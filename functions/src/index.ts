import * as admin from "firebase-admin";
import {onCall, CallableRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {logger} from "firebase-functions";
import {v2 as cloudinary} from "cloudinary";
// NOTE: For runtime config values set via `firebase functions:config:set`,
// we prefer accessing them through functions.config() (v1 style) which is still
// supported in v2 for hydrated environment, then fall back to process.env.* if provided.

// Initialize Firebase Admin
admin.initializeApp();

// Cloudinary admin configuration retrieval
function configureCloudinary() {
  try {
    // Attempt functions.config() style (works when deployed or using emulator with config)
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const functions = require("firebase-functions");
    const fnConfig = functions.config ? functions.config() : {};
    const cSection = fnConfig.cloudinary || {};

    const cloudNameCfg = cSection.cloud_name || process.env.CLOUDINARY_CLOUD_NAME;
    const apiKeyCfg = cSection.api_key || process.env.CLOUDINARY_API_KEY;
    const apiSecretCfg = cSection.api_secret || process.env.CLOUDINARY_API_SECRET;

    cloudinary.config({
      cloud_name: cloudNameCfg,
      api_key: apiKeyCfg,
      api_secret: apiSecretCfg,
      secure: true,
    });

    const conf = cloudinary.config() as any;
    const available = !!(conf.cloud_name && conf.api_key && conf.api_secret);
    if (available) {
      logger.info("[Cloudinary] Admin API configured for cleanup (cloud_name=" + conf.cloud_name + ")");
    } else {
      logger.warn("[Cloudinary] Incomplete configuration - image cleanup will be skipped. Provide cloudinary.cloud_name/api_key/api_secret.");
    }
    return available;
  } catch (e) {
    logger.error("[Cloudinary] Failed to configure admin API", e);
    return false;
  }
}

const cloudinaryAvailable = configureCloudinary();

// =============================
// Image Cleanup Scheduler
// Processes queued cleanup requests generated on the client.
// =============================

interface CleanupDoc {
  id: string;
  public_id: string;
  image_type: string;
  status: string;
  attempts?: number;
}

interface BulkCleanupDoc {
  id: string;
  user_id: string;
  cleanup_type: string;
  status: string;
  pattern?: string;
  folders_to_clean?: string[];
  attempts?: number;
}

const MAX_ATTEMPTS = 5;

async function processSingleCleanup(db: FirebaseFirestore.Firestore, doc: CleanupDoc) {
  if (!cloudinaryAvailable) return;
  const attempts = (doc.attempts || 0) + 1;
  try {
    await cloudinary.api.delete_resources([doc.public_id], {resource_type: "image"});
    await db.collection("image_cleanup_queue").doc(doc.id).update({status: "processed", processed_at: admin.firestore.FieldValue.serverTimestamp(), attempts});
    logger.info(`[cleanup] deleted ${doc.public_id}`);
  } catch (e:any) {
    const permanent = e?.http_code === 404; // treat not found as success-equivalent
    if (permanent) {
      await db.collection("image_cleanup_queue").doc(doc.id).update({status: "processed", note: "not_found", attempts});
      logger.warn(`[cleanup] not found ${doc.public_id}`);
    } else if (attempts >= MAX_ATTEMPTS) {
      await db.collection("image_cleanup_queue").doc(doc.id).update({status: "failed", attempts, last_error: String(e)});
      logger.error(`[cleanup] failed ${doc.public_id} attempts=${attempts}`, e);
    } else {
      await db.collection("image_cleanup_queue").doc(doc.id).update({status: "pending", attempts, last_error: String(e)});
      logger.warn(`[cleanup] retry scheduled ${doc.public_id} attempts=${attempts}`);
    }
  }
}

async function processBulkCleanup(db: FirebaseFirestore.Firestore, doc: BulkCleanupDoc) {
  if (!cloudinaryAvailable) return;
  const attempts = (doc.attempts || 0) + 1;
  try {
    // If explicit pattern present, attempt delete by prefix (requires listing)
    const folders = doc.folders_to_clean || [];
    let totalDeleted = 0;
    for (const folder of folders) {
      // List with prefix using Admin API (paginated)
      let nextCursor: string | undefined = undefined;
      let guard = 0;
      const prefix = doc.pattern ? `${folder}/${doc.pattern.replace(/\*/g, "")}` : folder;
      do {
        const res:any = await cloudinary.api.resources({
          type: "upload",
          resource_type: "image",
          prefix,
          max_results: 100,
          next_cursor: nextCursor,
        });
        const ids: string[] = (res.resources || []).map((r:any) => r.public_id);
        if (ids.length) {
          const delRes:any = await cloudinary.api.delete_resources(ids, {resource_type: "image"});
          const deletedCount = Object.values(delRes.deleted || {}).filter((v:any) => v === "deleted").length;
          totalDeleted += deletedCount;
        }
        nextCursor = res.next_cursor;
        guard++;
      } while (nextCursor && guard < 20);
    }
    await db.collection("bulk_cleanup_queue").doc(doc.id).update({status: "processed", processed_at: admin.firestore.FieldValue.serverTimestamp(), attempts, total_deleted: totalDeleted});
    logger.info(`[bulk_cleanup] processed id=${doc.id} deleted=${totalDeleted}`);
  } catch (e:any) {
    if (attempts >= MAX_ATTEMPTS) {
      await db.collection("bulk_cleanup_queue").doc(doc.id).update({status: "failed", attempts, last_error: String(e)});
      logger.error(`[bulk_cleanup] failed id=${doc.id} attempts=${attempts}`, e);
    } else {
      await db.collection("bulk_cleanup_queue").doc(doc.id).update({status: "pending", attempts, last_error: String(e)});
      logger.warn(`[bulk_cleanup] retry id=${doc.id} attempts=${attempts}`);
    }
  }
}

export const scheduledImageCleanup = onSchedule({schedule: "every 5 minutes"}, async () => {
  if (!cloudinaryAvailable) {
    logger.warn("[scheduler] Cloudinary not configured; skipping cleanup run");
    return;
  }
  const db = admin.firestore();
  const start = Date.now();
  const perRunLimit = 40; // total docs processed per run (split between queues)
  try {
    // Process individual cleanup queue
    const singleSnap = await db.collection("image_cleanup_queue")
      .where("status", "in", ["pending", "error"]) // legacy status 'error'
      .orderBy("created_at", "asc")
      .limit(perRunLimit)
      .get();
    let processedSingles = 0;
    for (const doc of singleSnap.docs) {
      if (processedSingles >= perRunLimit) break;
      await processSingleCleanup(db, {id: doc.id, ...(doc.data() as any)});
      processedSingles++;
    }

    // Process bulk cleanup queue (remaining budget)
    const remaining = perRunLimit - processedSingles;
    if (remaining > 0) {
      const bulkSnap = await db.collection("bulk_cleanup_queue")
        .where("status", "in", ["pending", "error"]) // legacy status 'error'
        .orderBy("created_at", "asc")
        .limit(remaining)
        .get();
      for (const doc of bulkSnap.docs) {
        await processBulkCleanup(db, {id: doc.id, ...(doc.data() as any)});
      }
    }
    const dur = Date.now() - start;
    logger.info(`[scheduler] image cleanup run completed in ${dur}ms singles=${processedSingles}`);
  } catch (e) {
    logger.error("[scheduler] cleanup run failed", e);
  }
});

// Simple rate limiting without persistent storage
const rateLimiter = new Map<string, number>();

const checkRateLimit = (functionName: string): boolean => {
  const now = Date.now();
  const key = functionName;
  const lastCall = rateLimiter.get(key) || 0;
  
  // Simple rate limiting: max 1 call per second per function
  if (now - lastCall < 1000) {
    logger.warn(`Function ${functionName} rate limited`);
    return false;
  }
  
  rateLimiter.set(key, now);
  return true;
};

// CORS headers for web requests (if needed for HTTP functions)
// const corsHeaders = {
//   "Access-Control-Allow-Origin": "*",
//   "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
//   "Access-Control-Allow-Methods": "POST, GET, OPTIONS, PUT, DELETE",
// };

export const deleteUser = onCall(async (request: CallableRequest) => {
  if (!checkRateLimit("deleteUser")) {
    throw new Error("Rate limit exceeded. Please wait a moment.");
  }

  try {
    const {auth} = request;
    
    if (!auth) {
      throw new Error("Authentication required");
    }

    const userId = auth.uid;
    logger.info(`Starting deletion process for user: ${userId}`);

  const db = admin.firestore();
  const batch = db.batch();

    // Delete user data in cascading order to avoid foreign key constraint violations
    
    // 1. Delete user interactions and analytics
    const userInteractionsRef = db.collection("user_interactions").where("user_id", "==", userId);
    const analyticsRef = db.collection("analytics_events").where("user_id", "==", userId);
    const performanceRef = db.collection("performance_metrics").where("user_id", "==", userId);
    const requestLogsRef = db.collection("request_logs").where("user_id", "==", userId);
    const errorLogsRef = db.collection("error_logs").where("user_id", "==", userId);

    const collections = [userInteractionsRef, analyticsRef, performanceRef, requestLogsRef, errorLogsRef];
    
    for (const collectionRef of collections) {
      const snapshot = await collectionRef.get();
      snapshot.forEach((doc) => {
        batch.delete(doc.ref);
      });
    }

    // 2. Delete wish item statuses where user is involved
    const wishItemStatusesRef = db.collection("wish_item_statuses").where("user_id", "==", userId);
    const statusSnapshot = await wishItemStatusesRef.get();
    statusSnapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // 3. Delete friendships and friends where user is involved
    const friendshipsRef1 = db.collection("friendships").where("user_id", "==", userId);
    const friendshipsRef2 = db.collection("friendships").where("friend_id", "==", userId);
    const friendsRef1 = db.collection("friends").where("user_id", "==", userId);
    const friendsRef2 = db.collection("friends").where("friend_id", "==", userId);

    const friendCollections = [friendshipsRef1, friendshipsRef2, friendsRef1, friendsRef2];
    
    for (const collectionRef of friendCollections) {
      const snapshot = await collectionRef.get();
      snapshot.forEach((doc) => {
        batch.delete(doc.ref);
      });
    }

    // 4. Delete wish items from user's wishlists
    const userWishlistsRef = db.collection("wishlists").where("owner_id", "==", userId);
    const wishlistsSnapshot = await userWishlistsRef.get();
    
    const wishlistIds: string[] = [];
    wishlistsSnapshot.forEach((doc) => {
      wishlistIds.push(doc.id);
      batch.delete(doc.ref);
    });

    // Collect product & wishlist image public IDs for Cloudinary cleanup
    const productImagePublicIds: string[] = [];
    const wishlistImagePublicIds: string[] = [];
    if (wishlistIds.length > 0) {
      for (const wishlistId of wishlistIds) {
        // For each wishlist gather wish_items first (need their IDs before deletion)
        const wishItemsRef = db.collection("wish_items").where("wishlist_id", "==", wishlistId);
        const itemsSnapshot = await wishItemsRef.get();
        itemsSnapshot.forEach((doc) => {
          const itemId = doc.id;
            // Pattern used on client: product_<itemId>
          productImagePublicIds.push(`product_${itemId}`);
          batch.delete(doc.ref);
        });
        // Wishlist cover pattern: wishlist_<wishlistId>
        wishlistImagePublicIds.push(`wishlist_${wishlistId}`);
      }
    }

    // 6. Delete from users collection
    const userDocRef = db.collection("users").doc(userId);
    batch.delete(userDocRef);

  // Execute all Firestore deletions first
  await batch.commit();

    // 7. Cloudinary cleanup (best effort, non-blocking failures)
    const profileImageId = `profile_${userId}`;
    const allPublicIds = [profileImageId, ...productImagePublicIds, ...wishlistImagePublicIds];
    let cloudinaryDeleted: string[] = [];
  if (cloudinaryAvailable && allPublicIds.length > 0) {
      try {
        // Bulk delete by public IDs
        logger.info(`Attempting Cloudinary deletion for ${allPublicIds.length} images`);
        const deleteResponse = await cloudinary.api.delete_resources(allPublicIds, {resource_type: 'image'});
        // deleteResponse.deleted is an object mapping id-> 'deleted' | 'not_found'
        cloudinaryDeleted = Object.entries(deleteResponse.deleted || {})
          .filter(([, status]) => status === 'deleted')
          .map(([id]) => id);
        const notFound = Object.entries(deleteResponse.deleted || {})
          .filter(([, status]) => status === 'not_found')
          .map(([id]) => id);
        logger.info(`Cloudinary deletion summary: deleted=${cloudinaryDeleted.length} not_found=${notFound.length}`);
        if (notFound.length) {
          logger.warn(`Cloudinary images not found (may already be removed): ${notFound.join(', ')}`);
        }
      } catch (cloudErr) {
        logger.error("Cloudinary cleanup failed", cloudErr as any);
      }
    }

    // 8. Finally, delete from Firebase Auth
    await admin.auth().deleteUser(userId);

  logger.info(`Successfully deleted user: ${userId}`);

  return {message: "User deleted successfully", cloudinaryDeleted};
  } catch (error) {
    logger.error("Error deleting user:", error);
    throw error;
  }
});

// Secure scraper function
interface ScrapedData {
  title: string;
  price: string;
  image: string;
  description?: string;
  category?: string;
  rating?: string;
  currency?: string;
  availability?: string;
}

// Lista de domínios confiáveis (resumida para exemplo)
const TRUSTED_DOMAINS = [
  // Marketplaces globais
  "amazon.com", "amazon.pt", "amazon.es", "amazon.fr", "amazon.co.uk", "amazon.de",
  "ebay.com", "ebay.pt", "ebay.es", "aliexpress.com",
  
  // Lojas portuguesas
  "fnac.pt", "worten.pt", "pcdiga.pt", "continente.pt", "kuantokusta.pt",
  
  // Lojas espanholas
  "elcorteingles.es", "mediamarkt.es", "carrefour.es",
  
  // Moda internacional
  "zara.com", "hm.com", "uniqlo.com", "asos.com", "zalando.pt",
  
  // Eletrônicos
  "apple.com", "samsung.com", "sony.com", "bestbuy.com",
  
  // E muitos outros...
  "ikea.com", "booking.com", "sephora.com"
];

const SUSPICIOUS_PATTERNS = [
  "localhost", "127.0.0.1", "192.168.", "file://", "javascript:"
];

export const secureScraper = onCall(async (request: CallableRequest) => {
  if (!checkRateLimit("secureScraper")) {
    throw new Error("Rate limit exceeded. Please wait a moment.");
  }

  try {
    const {url} = request.data;
    
    if (!url || typeof url !== "string") {
      throw new Error("URL é obrigatória");
    }

    // Validate and normalize URL
    const validatedUrl = validateAndNormalizeUrl(url);
    
    // Scrape with safety measures
    const scrapedData = await scrapeWithSanitization(validatedUrl);
    
    return scrapedData;
  } catch (error) {
    logger.error("Scraping error:", error);
    
    return {
      error: error instanceof Error ? error.message : "Erro ao fazer scraping da URL",
      title: "Could not fetch title",
      price: "0.00",
      image: ""
    };
  }
});

function validateAndNormalizeUrl(url: string): string {
  try {
    let normalizedUrl = url.trim();
    
    if (!normalizedUrl.startsWith("http://") && !normalizedUrl.startsWith("https://")) {
      normalizedUrl = "https://" + normalizedUrl;
    }
    
    const urlObj = new URL(normalizedUrl);
    const hostname = urlObj.hostname.toLowerCase();
    
    // Check suspicious patterns
    const isSuspicious = SUSPICIOUS_PATTERNS.some(pattern => 
      hostname.includes(pattern)
    );
    
    if (isSuspicious) {
      throw new Error(`Domínio suspeito bloqueado: ${hostname}`);
    }
    
    // Check if it's a trusted domain
    const isTrusted = TRUSTED_DOMAINS.some(domain => 
      hostname === domain || hostname.endsWith("." + domain)
    );
    
    if (!isTrusted && !isValidEcommerceDomain(hostname)) {
      throw new Error(`Domínio não suportado: ${hostname}. Para segurança, apenas lojas verificadas são permitidas.`);
    }
    
    return normalizedUrl;
  } catch (error) {
    if (error instanceof TypeError) {
      throw new Error("URL inválida");
    }
    throw error;
  }
}

function isValidEcommerceDomain(hostname: string): boolean {
  const ecommerceIndicators = ["shop", "store", "loja", "buy", "market"];
  const trustedTlds = [".com", ".pt", ".es", ".fr", ".de", ".co.uk"];
  
  const hasEcommerceIndicator = ecommerceIndicators.some(indicator => 
    hostname.includes(indicator)
  );
  
  const hasTrustedTld = trustedTlds.some(tld => hostname.endsWith(tld));
  
  return hasEcommerceIndicator && hasTrustedTld;
}

async function scrapeWithSanitization(url: string): Promise<ScrapedData> {
  try {
    // Import fetch dynamically to avoid module issues
    const fetch = (await import("node-fetch")).default;
    
    // Create AbortController for timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000);
    
    const response = await fetch(url, {
      method: "GET",
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
      },
      signal: controller.signal,
    });
    
    clearTimeout(timeoutId);
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    const html = await response.text();
    
    // Extract data from HTML
    const scrapedData = extractDataFromHtml(html, url);
    
    return scrapedData;
  } catch (error) {
    logger.error("Scraping error:", error);
    throw error;
  }
}

function extractDataFromHtml(html: string, baseUrl: string): ScrapedData {
  // Import JSDOM for HTML parsing
  const jsdom = require("jsdom");
  const {JSDOM} = jsdom;
  
  const dom = new JSDOM(html);
  const document = dom.window.document;
  
  // Extract title
  let title = "";
  const titleElement = document.querySelector("title");
  if (titleElement) {
    title = titleElement.textContent || "";
  }
  
  // Extract price (simplified)
  let price = "0.00";
  let currency = "EUR";
  const priceText = html.match(/€\s*(\d+[.,]\d{2})/);
  if (priceText) {
    price = priceText[1].replace(",", ".");
  }
  
  // Extract image
  let image = "";
  const ogImage = document.querySelector('meta[property="og:image"]');
  if (ogImage) {
    image = ogImage.getAttribute("content") || "";
    if (image.startsWith("//")) {
      image = "https:" + image;
    } else if (image.startsWith("/")) {
      const base = new URL(baseUrl);
      image = base.origin + image;
    }
  }
  
  return {
    title: title || "Título não encontrado",
    price: price,
    currency: currency,
    image: image,
    description: "",
    category: "Outros",
    availability: "Desconhecido"
  };
}

