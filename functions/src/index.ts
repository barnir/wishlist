import * as admin from "firebase-admin";
import {onCall, CallableRequest} from "firebase-functions/v2/https";
import {logger} from "firebase-functions";

// Initialize Firebase Admin
admin.initializeApp();

// Usage monitoring
interface UsageStats {
  reads: number;
  writes: number;
  functions: number;
  date: string;
}

// Monitor usage to stay within free tier
const monitorUsage = async (functionName: string): Promise<boolean> => {
  try {
    const today = new Date().toISOString().split("T")[0];
    const statsRef = admin.firestore().collection("_usage").doc(today);
    
    const doc = await statsRef.get();
    const stats: UsageStats = doc.exists ? 
      doc.data() as UsageStats : 
      {reads: 0, writes: 0, functions: 0, date: today};
    
    // Check if we're approaching limits (80% threshold)
    if (stats.functions >= 53333) { // 80% of 66,666 daily limit
      logger.warn(`Function ${functionName} blocked - approaching daily limit`);
      return false;
    }
    
    // Increment function counter
    stats.functions += 1;
    await statsRef.set(stats, {merge: true});
    
    return true;
  } catch (error) {
    logger.error("Error monitoring usage:", error);
    return true; // Allow execution on monitoring error
  }
};

// CORS headers for web requests (if needed for HTTP functions)
// const corsHeaders = {
//   "Access-Control-Allow-Origin": "*",
//   "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
//   "Access-Control-Allow-Methods": "POST, GET, OPTIONS, PUT, DELETE",
// };

export const deleteUser = onCall(async (request: CallableRequest) => {
  const canExecute = await monitorUsage("deleteUser");
  if (!canExecute) {
    throw new Error("Daily function limit reached. Try again tomorrow.");
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

    if (wishlistIds.length > 0) {
      // Delete wish items from user's wishlists
      for (const wishlistId of wishlistIds) {
        const wishItemsRef = db.collection("wish_items").where("wishlist_id", "==", wishlistId);
        const itemsSnapshot = await wishItemsRef.get();
        itemsSnapshot.forEach((doc) => {
          batch.delete(doc.ref);
        });
      }
    }

    // 6. Delete from users collection
    const userDocRef = db.collection("users").doc(userId);
    batch.delete(userDocRef);

    // Execute all deletions
    await batch.commit();

    // 7. Finally, delete from Firebase Auth
    await admin.auth().deleteUser(userId);

    logger.info(`Successfully deleted user: ${userId}`);

    return {message: "User deleted successfully"};
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
  const canExecute = await monitorUsage("secureScraper");
  if (!canExecute) {
    throw new Error("Daily function limit reached. Try again tomorrow.");
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

// Health check function for monitoring
export const healthCheck = onCall(async (request: CallableRequest) => {
  const today = new Date().toISOString().split("T")[0];
  
  try {
    const statsRef = admin.firestore().collection("_usage").doc(today);
    const doc = await statsRef.get();
    const stats = doc.exists ? doc.data() : {reads: 0, writes: 0, functions: 0};
    
    return {
      status: "healthy",
      usage: stats,
      limits: {
        reads: 50000,
        writes: 20000,
        functions: 66666
      },
      date: today
    };
  } catch (error) {
    logger.error("Health check error:", error);
    return {
      status: "error",
      error: error instanceof Error ? error.message : "Unknown error"
    };
  }
});