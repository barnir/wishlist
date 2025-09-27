import * as admin from "firebase-admin";
import { logger } from "firebase-functions";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { v2 as cloudinary } from "cloudinary";
import * as functions from "firebase-functions";
import { onDocumentCreated, onDocumentUpdated, onDocumentDeleted } from "firebase-functions/v2/firestore";

// Initialize admin SDK once
if (admin.apps.length === 0) {
  admin.initializeApp();
}

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

// Enrichment response structure (more explicit types)
interface EnrichmentResult {
  title: string;
  price?: number; // numeric (parsed)
  currency?: string;
  image?: string;
  ratingValue?: number;
  ratingCount?: number;
  categorySuggestion?: string;
  rawPriceString?: string;
  sourceDomain: string;
  canonicalUrl: string;
  updatedAt: string; // ISO
  cacheId?: string; // doc id in link_metadata cache
}

// ================= Rate Limiting (per-user enrichLink) =================
// Simple Firestore-backed sliding window (minute + hour) to prevent abuse.
// For low scale acceptable; if scale grows, migrate to Redis/Memorystore.
const ENRICH_PER_MINUTE_LIMIT = 5; // burst
const ENRICH_PER_HOUR_LIMIT = 40;  // sustained

async function assertEnrichRateLimit(uid: string, db: FirebaseFirestore.Firestore) {
  const now = Date.now();
  const docRef = db.collection('rl_enrich').doc(uid);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(docRef);
    let minuteStart = now;
    let hourStart = now;
    let minuteCount = 0;
    let hourCount = 0;
    if (snap.exists) {
      const d = snap.data() || {};
      minuteStart = (d.minute_start_ms as number) || now;
      hourStart = (d.hour_start_ms as number) || now;
      minuteCount = (d.minute_count as number) || 0;
      hourCount = (d.hour_count as number) || 0;
      if (now - minuteStart >= 60_000) { minuteStart = now; minuteCount = 0; }
      if (now - hourStart >= 3_600_000) { hourStart = now; hourCount = 0; }
    }
    if (minuteCount + 1 > ENRICH_PER_MINUTE_LIMIT || hourCount + 1 > ENRICH_PER_HOUR_LIMIT) {
      logger.warn('enrichLink rate_limited', { uid, minuteCount, hourCount });
      throw new HttpsError('resource-exhausted', 'Limite de enriquecimentos atingido. Tente novamente mais tarde.');
    }
    minuteCount += 1; hourCount += 1;
    tx.set(docRef, {
      minute_start_ms: minuteStart,
      hour_start_ms: hourStart,
      minute_count: minuteCount,
      hour_count: hourCount,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  });
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

// =============================
// Aggregates: wishlist total_value & item_count (incremental)
// =============================

async function adjustWishlistAggregates(wishlistId: string, deltaCount: number, deltaValue: number) {
  const db = admin.firestore();
  const ref = db.collection("wishlists").doc(wishlistId);
  try {
    await ref.update({
      item_count: admin.firestore.FieldValue.increment(deltaCount),
      total_value: admin.firestore.FieldValue.increment(deltaValue),
      total_updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (e: any) {
    // Fallback: if doc missing fields, recompute fully
    logger.warn("adjustWishlistAggregates fallback recompute", { wishlistId, error: String(e) });
    await recomputeWishlistAggregates(wishlistId);
  }
}

async function recomputeWishlistAggregates(wishlistId: string) {
  const db = admin.firestore();
  const snap = await db.collection("wish_items").where("wishlist_id", "==", wishlistId).get();
  let total = 0; let count = 0;
  for (const d of snap.docs) {
    const data = d.data();
    const price = Number(data.price) || 0;
    total += price;
    count++;
  }
  await db.collection("wishlists").doc(wishlistId).set({
    item_count: count,
    total_value: total,
    total_updated_at: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

export const wishItemCreated = onDocumentCreated("wish_items/{itemId}", async (event) => {
  try {
    const data = event.data?.data();
    if (!data) return;
    const wishlistId = data.wishlist_id as string | undefined;
    if (!wishlistId) return;
    const price = Number(data.price) || 0;
    await adjustWishlistAggregates(wishlistId, 1, price);
  } catch (e) {
    logger.error("wishItemCreated aggregate error", e);
  }
});

export const wishItemUpdated = onDocumentUpdated("wish_items/{itemId}", async (event) => {
  try {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!after) return;
    const beforeWishlist = before?.wishlist_id as string | undefined;
    const afterWishlist = after.wishlist_id as string | undefined;
    const beforePrice = Number(before?.price) || 0;
    const afterPrice = Number(after.price) || 0;
    if (beforeWishlist && afterWishlist && beforeWishlist !== afterWishlist) {
      // Moved wishlist: decrement old, increment new
      await adjustWishlistAggregates(beforeWishlist, -1, -beforePrice);
      await adjustWishlistAggregates(afterWishlist, 1, afterPrice);
    } else if (afterWishlist) {
      const deltaValue = afterPrice - beforePrice;
      if (deltaValue !== 0) {
        await adjustWishlistAggregates(afterWishlist, 0, deltaValue);
      }
    }
  } catch (e) {
    logger.error("wishItemUpdated aggregate error", e);
  }
});

export const wishItemDeleted = onDocumentDeleted("wish_items/{itemId}", async (event) => {
  try {
    const before = event.data?.data();
    if (!before) return;
    const wishlistId = before.wishlist_id as string | undefined;
    if (!wishlistId) return;
    const price = Number(before.price) || 0;
    await adjustWishlistAggregates(wishlistId, -1, -price);
  } catch (e) {
    logger.error("wishItemDeleted aggregate error", e);
  }
});

export const secureScraper = onCall(async (request) => {
  try {
    const { url } = request.data;

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

// ==========================================================
// enrichLink callable (lightweight metadata enrichment + cache)
// Params: { url: string }
// Returns: EnrichmentResult
// ==========================================================
export const enrichLink = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Utilizador não autenticado');
  }
  const url = (request.data as any)?.url?.trim?.() || '';
  if (!url) {
    throw new HttpsError('invalid-argument', 'url obrigatória');
  }
  const normalized = validateAndNormalizeUrl(url);
  const canonical = stripTrackingParams(normalized);
  if (canonical.length > 2048) {
    throw new HttpsError('invalid-argument', 'URL demasiado longa');
  }
  const domain = new URL(canonical).hostname.toLowerCase();
  const db = admin.firestore();
  // Rate limit per user
  await assertEnrichRateLimit(uid, db);
  const cacheId = canonicalCacheId(canonical);
  const cacheRef = db.collection('link_metadata').doc(cacheId);

  // Cache reuse (TTL 12h)
  const now = Date.now();
  const ttlMs = 12 * 60 * 60 * 1000;
  const cacheSnap = await cacheRef.get();
  if (cacheSnap.exists) {
    const data = cacheSnap.data() || {};
    const updatedAtMs = (data.updated_at_ms as number) || 0;
    if (now - updatedAtMs < ttlMs) {
      logger.info('enrichLink cache_hit', { uid, cacheId, domain });
      return {
        title: data.title || 'Sem título',
        price: typeof data.price_cents === 'number' ? data.price_cents / 100 : undefined,
        currency: data.currency,
        image: data.image,
        ratingValue: data.rating_value,
        ratingCount: data.rating_count,
        categorySuggestion: data.category_suggestion,
        rawPriceString: data.raw_price_string,
        sourceDomain: data.domain || domain,
        canonicalUrl: data.canonical_url || canonical,
        updatedAt: new Date(updatedAtMs).toISOString(),
        cacheId,
      };
    }
  }

  // Fetch + parse
  let html: string;
  try {
    html = await fetchHtmlWithLimits(canonical);
  } catch (e: any) {
    logger.warn('enrichLink fetch fail', { canonical, error: String(e) });
    throw new HttpsError('unavailable', 'Falha ao obter conteúdo');
  }
  const parsed = extractDataFromHtml(html, canonical);
  const numericPrice = parseFloat(parsed.price || '0');
  const categorySuggestion = inferCategory(parsed.title || '');

  // Basic rating parse (simple regex for patterns like "4.6 de 5" or "4,6 de 5")
  let ratingValue: number | undefined; let ratingCount: number | undefined;
  try {
    const ratingMatch = html.match(/(\d+[.,]\d+)\s+de\s+5/);
    if (ratingMatch) {
      ratingValue = parseFloat(ratingMatch[1].replace(',', '.'));
    }
    const countMatch = html.match(/(\d{1,3}(?:[.,]\d{3})*)\s+(?:avaliações|opiniões|classificaç|vendido|vendidos)/i);
    if (countMatch) {
      ratingCount = parseInt(countMatch[1].replace(/[.,]/g, ''));
    }
  } catch { /* ignore */ }

  // Persist cache
  const toSave = {
    canonical_url: canonical,
    domain,
    title: parsed.title || 'Sem título',
    raw_price_string: parsed.price || '',
    price_cents: isFinite(numericPrice) ? Math.round(numericPrice * 100) : null,
    currency: (parsed as any).currency || 'EUR',
    image: parsed.image || '',
    rating_value: ratingValue,
    rating_count: ratingCount,
    category_suggestion: categorySuggestion,
    updated_at_ms: now,
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };
  await cacheRef.set(toSave, { merge: true });
  logger.info('enrichLink cache_miss_stored', { uid, cacheId, domain });

  const result: EnrichmentResult = {
    title: toSave.title,
    price: toSave.price_cents ? toSave.price_cents / 100 : undefined,
    currency: toSave.currency,
    image: toSave.image,
    ratingValue: ratingValue,
    ratingCount: ratingCount,
    categorySuggestion,
    rawPriceString: parsed.price || '',
    sourceDomain: domain,
    canonicalUrl: canonical,
    updatedAt: new Date(now).toISOString(),
    // extra field (not in original interface) but safe for clients
    cacheId,
  };
  return result;
});

function stripTrackingParams(u: string): string {
  try {
    const urlObj = new URL(u);
    const trackingKeys = ['tag', 'ascsubtag', 'aff_platform', 'aff_trace_key', 'spm', 'fbclid', 'gclid', 'utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content', 'ref', 'ref_'];
    trackingKeys.forEach(k => urlObj.searchParams.delete(k));
    return urlObj.origin + urlObj.pathname + (urlObj.searchParams.toString() ? '?' + urlObj.searchParams.toString() : '');
  } catch { return u; }
}

function canonicalCacheId(canonicalUrl: string): string {
  // Simple hash (FNV-1a like) to keep doc ids small
  let hash = 2166136261; for (let i = 0; i < canonicalUrl.length; i++) { hash ^= canonicalUrl.charCodeAt(i); hash = Math.imul(hash, 16777619); }
  return 'u_' + (hash >>> 0).toString(16);
}

async function fetchHtmlWithLimits(url: string): Promise<string> {
  const fetch = (await import('node-fetch')).default;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);
  const res = await fetch(url, {
    method: 'GET',
    headers: { 'User-Agent': 'Mozilla/5.0 (WishlistApp Metadata Bot)' },
    signal: controller.signal,
  });
  clearTimeout(timeout);
  if (!res.ok) throw new Error('HTTP ' + res.status);
  const limit = 300 * 1024; // 300KB
  // node-fetch v3 body is a web stream; convert via reader or fallback to arrayBuffer
  let buf: Buffer;
  try {
    const arrBuf = await res.arrayBuffer();
    buf = Buffer.from(arrBuf).subarray(0, limit);
  } catch (e) {
    const text = await res.text();
    return text.slice(0, limit);
  }
  return buf.toString('utf8');
}

function inferCategory(title: string): string | undefined {
  const t = title.toLowerCase();
  if (/(bateria|battery)/.test(t)) return 'electronics_computer_accessory';
  if (/bicicleta|bike/.test(t) && /luz|light/.test(t)) return 'sports_cycling';
  if (/camisa|t[- ]?shirt|blusa|shirt/.test(t)) return 'fashion_apparel';
  return undefined;
}

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

// =============================
// deleteUser: Apaga dados do utilizador autenticado (scoped, não destrutivo global)
// - Requer auth
// - Remove: users/{uid}, wishlists do utilizador + seus wish_items
// - Limpa imagens Cloudinary referenciadas (se variáveis CLOUDINARY_* disponíveis)
// =============================

interface DeletionSummary {
  wishlistsDeleted: number;
  wishItemsDeleted: number;
  userDocDeleted: boolean;
  cloudinaryImagesDeleted?: number;
}

export const deleteUser = onCall<DeletionSummary>(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Utilizador não autenticado');
  }
  const db = admin.firestore();
  const summary: DeletionSummary = { wishlistsDeleted: 0, wishItemsDeleted: 0, userDocDeleted: false };

  try {
    // Collect wishlist IDs for user
    const wishlistsSnap = await db.collection('wishlists').where('user_id', '==', uid).get();
    const wishlistIds = wishlistsSnap.docs.map(d => d.id);
    summary.wishlistsDeleted = wishlistIds.length;

    // Pre-collect wish_item IDs for Cloudinary cleanup (product_<id>) then delete in batches
    const allWishItemIds: string[] = [];
    for (const wid of wishlistIds) {
      let lastBatchSize = 0;
      do {
        const itemsSnap = await db.collection('wish_items').where('wishlist_id', '==', wid).limit(450).get();
        lastBatchSize = itemsSnap.size;
        if (lastBatchSize === 0) break;
        const batch = db.batch();
        itemsSnap.docs.forEach(doc => {
          allWishItemIds.push(doc.id);
          batch.delete(doc.ref);
          summary.wishItemsDeleted++;
        });
        await batch.commit();
      } while (lastBatchSize === 450);
    }

    // Delete wishlists in batches
    if (wishlistIds.length) {
      let idx = 0;
      while (idx < wishlistIds.length) {
        const slice = wishlistIds.slice(idx, idx + 450);
        const batch = db.batch();
        slice.forEach(id => batch.delete(db.collection('wishlists').doc(id)));
        await batch.commit();
        idx += slice.length;
      }
    }

    // Delete user profile doc if exists
    const userDocRef = db.collection('users').doc(uid);
    const userDoc = await userDocRef.get();
    if (userDoc.exists) {
      await userDocRef.delete();
      summary.userDocDeleted = true;
    }

    // Optional Cloudinary cleanup (server-side) if credentials provided
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    const apiKey = process.env.CLOUDINARY_API_KEY;
    const apiSecret = process.env.CLOUDINARY_API_SECRET;
    if (cloudName && apiKey && apiSecret) {
      try {
        // Lazy import to avoid cost if not configured
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        const cloudinary = require('cloudinary').v2;
        cloudinary.config({ cloud_name: cloudName, api_key: apiKey, api_secret: apiSecret });
        // Public IDs follow patterns: profile_<uid>, wishlist_<wishlistId>, product_<wishItemId>
        const toDelete: string[] = [`profile_${uid}`];
        // wishlist images
        toDelete.push(...wishlistIds.map(id => `wishlist_${id}`));
        // product images (wish items)
        toDelete.push(...allWishItemIds.map(id => `product_${id}`));
        if (toDelete.length) {
          const chunkSize = 90; // below 100 admin API limit
          for (let i = 0; i < toDelete.length; i += chunkSize) {
            const slice = toDelete.slice(i, i + chunkSize);
            try {
              const res = await cloudinary.api.delete_resources(slice, { invalidate: true });
              const deletedIds = Object.keys(res.deleted || {}).filter(k => res.deleted[k] === 'deleted');
              summary.cloudinaryImagesDeleted = (summary.cloudinaryImagesDeleted || 0) + deletedIds.length;
            } catch (e: any) {
              logger.warn('Cloudinary deletion partial failure', { error: String(e) });
            }
          }
        }
      } catch (e: any) {
        logger.warn('Cloudinary cleanup skipped/failed', { error: String(e) });
      }
    }

    logger.info('User data deletion summary', { uid, summary });
    return summary;
  } catch (e: any) {
    logger.error('deleteUser error', { uid, error: String(e) });
    throw new HttpsError('internal', 'Falha ao apagar dados do utilizador');
  }
});

// mirrorToCloudinary: Downloads a remote image URL on the server side (via Cloudinary) and
// stores it in your Cloudinary account, returning the secure_url and public_id.
// This is a skeleton implementation: make sure to set Cloudinary credentials
// using Firebase Functions config (never commit secrets):
//   firebase functions:config:set cloudinary.cloud_name="..." cloudinary.api_key="..." cloudinary.api_secret="..."
// Optionally add domain allowlist and rate limiting as needed.
export const mirrorToCloudinary = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError('unauthenticated', 'User must be authenticated.');
  }

  const { url, folder, publicIdHint } = (request.data ?? {}) as {
    url?: string;
    folder?: string;
    publicIdHint?: string;
  };

  if (!url || typeof url !== 'string' || !/^https?:\/\//i.test(url)) {
    throw new HttpsError('invalid-argument', 'A valid http(s) url is required.');
  }

  // Basic SSRF guard: block localhost/private ranges. Consider adding an allowlist per your needs.
  try {
    const u = new URL(url);
    const host = u.hostname.toLowerCase();
    const blocked = [
      'localhost', '127.0.0.1', '::1',
    ];
    if (blocked.includes(host) || /^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[0-1])\.)/.test(host)) {
      throw new HttpsError('permission-denied', 'Target host is not allowed.');
    }
  } catch (_) {
    throw new HttpsError('invalid-argument', 'Malformed URL.');
  }

  const allowedFolders = new Set([
    'wishlist/products', 'wishlist/wishlists', 'wishlist/profiles',
  ]);
  const targetFolder = allowedFolders.has(folder ?? '') ? folder! : 'wishlist/products';

  // Load Cloudinary credentials from Functions config (set via CLI). Do NOT commit secrets.
  const cfg = (functions.config().cloudinary || {}) as any;
  const cloudName: string | undefined = cfg.cloud_name || process.env.CLOUDINARY_CLOUD_NAME;
  const apiKey: string | undefined = cfg.api_key || process.env.CLOUDINARY_API_KEY;
  const apiSecret: string | undefined = cfg.api_secret || process.env.CLOUDINARY_API_SECRET;

  if (!cloudName || !apiKey || !apiSecret) {
    logger.error('Cloudinary not configured');
    throw new HttpsError('failed-precondition', 'Cloudinary is not configured.');
  }

  cloudinary.config({
    cloud_name: cloudName,
    api_key: apiKey,
    api_secret: apiSecret,
    secure: true,
  });

  // Build a stable public_id hint
  const ts = Date.now();
  const safeHint = (publicIdHint && /^[a-zA-Z0-9_\-/]+$/.test(publicIdHint)) ? publicIdHint : undefined;
  const publicId = safeHint ?? `mirrored_${uid}_${ts}`;

  try {
    // Cloudinary can fetch remote URLs directly server-side
    const result = await cloudinary.uploader.upload(url, {
      folder: targetFolder,
      public_id: publicId,
      resource_type: 'image',
      overwrite: false,
      unique_filename: true,
      use_filename: false,
    });

    logger.info('mirrorToCloudinary success', { uid, folder: targetFolder, publicId: result.public_id });
    return {
      secure_url: result.secure_url,
      public_id: result.public_id,
      width: result.width,
      height: result.height,
      bytes: result.bytes,
      format: result.format,
      folder: result.folder,
    };
  } catch (e: any) {
    logger.error('mirrorToCloudinary error', { uid, error: String(e) });
    // Map common errors to HttpsError
    throw new HttpsError('internal', e?.message ?? 'Upload failed');
  }
});


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
  const jsdom = require("jsdom");
  const { JSDOM } = jsdom;
  const dom = new JSDOM(html);
  const document = dom.window.document;

  // ---------- TITLE ----------
  let title = (document.querySelector('meta[property="og:title"]')?.getAttribute('content')
    || document.querySelector('meta[name="twitter:title"]')?.getAttribute('content')
    || document.querySelector('title')?.textContent || '').trim();

  // ---------- STRUCTURED DATA (JSON-LD) ----------
  let structuredPrice: string | undefined;
  let structuredCurrency: string | undefined;
  let structuredImage: string | undefined;
  try {
    const jsonLdNodes = Array.from(document.querySelectorAll('script[type="application/ld+json"]')) as Element[];
    for (const node of jsonLdNodes) {
      const txt = (node as HTMLElement).textContent?.trim();
      if (!txt) continue;
      // Some pages concatenate multiple JSON objects; attempt safe parse.
      const candidates: any[] = [];
      try {
        candidates.push(JSON.parse(txt));
      } catch {
        // Try to split if multiple objects (very naive fallback)
        const rawParts = txt.split(/}\s*{/);
        const parts: string[] = rawParts.map((p: string, i: number, arr: string[]) => i === 0 ? p + '}' : (i === arr.length - 1 ? '{' + p : '{' + p + '}'));
        for (const part of parts) { try { candidates.push(JSON.parse(part)); } catch { /* ignore parse error */ } }
      }
      for (const data of candidates) {
        if (!data || typeof data !== 'object') continue;
        // Product schema or Offer inside graph
        const possibleNodes: any[] = [];
        if (Array.isArray((data as any)['@graph'])) possibleNodes.push(...(data as any)['@graph']); else possibleNodes.push(data);
        for (const nodeObj of possibleNodes) {
          if (!nodeObj || typeof nodeObj !== 'object') continue;
          // Price
          const offers = nodeObj.offers || nodeObj.offer;
          if (offers) {
            const offerArray = Array.isArray(offers) ? offers : [offers];
            for (const o of offerArray) {
              if (!structuredPrice && (o.price || o.priceSpecification?.price)) {
                structuredPrice = String(o.price || o.priceSpecification?.price);
              }
              if (!structuredCurrency && (o.priceCurrency || o.priceSpecification?.priceCurrency)) {
                structuredCurrency = String(o.priceCurrency || o.priceSpecification?.priceCurrency);
              }
            }
          }
          if (!structuredImage) {
            if (typeof nodeObj.image === 'string') structuredImage = nodeObj.image;
            else if (Array.isArray(nodeObj.image) && nodeObj.image.length) structuredImage = nodeObj.image[0];
          }
        }
      }
      if (structuredPrice && structuredImage) break; // good enough
    }
  } catch { /* silent */ }

  // ---------- META TAG PRICE ----------
  const metaPrice = document.querySelector('meta[property="product:price:amount"]')?.getAttribute('content')
    || document.querySelector('meta[property="og:price:amount"]')?.getAttribute('content')
    || document.querySelector('meta[itemprop="price"]')?.getAttribute('content')
    || undefined;
  const metaCurrency = document.querySelector('meta[property="product:price:currency"]')?.getAttribute('content')
    || document.querySelector('meta[property="og:price:currency"]')?.getAttribute('content')
    || document.querySelector('meta[itemprop="priceCurrency"]')?.getAttribute('content')
    || undefined;

  // ---------- DOM ELEMENTS (Amazon etc.) ----------
  const amazonPriceEl = document.querySelector('#priceblock_ourprice, #priceblock_dealprice, #priceblock_saleprice, span.a-price span.a-offscreen');
  const amazonPriceText = amazonPriceEl?.textContent?.trim();

  // ---------- REGEX FALLBACK (multi-currency) ----------
  // Capture currencies: €, $, £, R$, US$ etc.
  const currencySymbols = ['€', '$', '£'];
  let regexPrice: { amount?: string; symbol?: string } = {};
  const symbolPattern = /(€|£|US\$|R\$|\$)\s*([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{2})?)/i;
  const symbolMatch = html.match(symbolPattern);
  if (symbolMatch) {
    regexPrice = { symbol: symbolMatch[1], amount: symbolMatch[2] };
  }

  // ---------- DECISION LOGIC FOR PRICE ----------
  let rawPrice = structuredPrice || metaPrice || amazonPriceText || regexPrice.amount;
  let currency = (structuredCurrency || metaCurrency || (regexPrice.symbol === '€' ? 'EUR' : regexPrice.symbol === '£' ? 'GBP' : regexPrice.symbol ? 'USD' : undefined) || 'EUR').toUpperCase();
  if (rawPrice) {
    // Clean separators: if both comma and dot present, assume thousand separators
    rawPrice = rawPrice.replace(/\s/g, '');
    const commaCount = (rawPrice.match(/,/g) || []).length;
    const dotCount = (rawPrice.match(/\./g) || []).length;
    if (commaCount > 0 && dotCount > 0) {
      // Remove thousand separators heuristically
      if (rawPrice.indexOf(',') < rawPrice.lastIndexOf('.')) {
        // e.g. 1,234.56 -> remove commas
        rawPrice = rawPrice.replace(/,/g, '');
      } else {
        // e.g. 1.234,56 -> remove dots, replace comma with dot
        rawPrice = rawPrice.replace(/\./g, '').replace(/,/g, '.');
      }
    } else if (commaCount === 1 && dotCount === 0) {
      // European decimal
      rawPrice = rawPrice.replace(/,/g, '.');
    } else if (commaCount > 1 && dotCount === 0) {
      // 1,234,567 -> remove commas
      rawPrice = rawPrice.replace(/,/g, '');
    }
  }
  let price = '0.00';
  if (rawPrice && /^\d+(?:\.\d+)?$/.test(rawPrice)) {
    price = rawPrice;
  }

  // ---------- IMAGE EXTRACTION ----------
  let image = structuredImage
    || document.querySelector('meta[property="og:image"]')?.getAttribute('content')
    || document.querySelector('meta[name="twitter:image"]')?.getAttribute('content')
    || document.querySelector('link[rel="image_src"]')?.getAttribute('href')
    || '';

  if (!image) {
    // Try Amazon image container
    const imgCandidate = document.querySelector('#landingImage, img#imgBlkFront, img.a-dynamic-image');
    if (imgCandidate) image = imgCandidate.getAttribute('src') || '';
  }

  if (image) {
    if (image.startsWith('//')) image = 'https:' + image;
    else if (image.startsWith('/')) {
      const base = new URL(baseUrl); image = base.origin + image;
    }
  }

  return {
    title: title || 'Título não encontrado',
    price,
    currency,
    image,
    description: '',
    category: 'Outros',
    availability: 'Desconhecido'
  };
}

// ================= Purchase Reminder Functions =================

/**
 * Cloud Function agendada para processar lembretes de compra pendentes
 * Executa a cada hora para verificar se há lembretes para enviar
 */
export const processPurchaseReminders = onSchedule({
  schedule: "0 */1 * * *", // A cada hora
  timeZone: "Europe/Lisbon",
  timeoutSeconds: 540,
  memory: "512MiB"
}, async (event) => {
  logger.info("🔔 Processing purchase reminders...");

  try {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // Processar lembretes do 6º dia
    const reminder6Query = await db
      .collection('purchase_reminders')
      .where('status', '==', 'active')
      .where('reminder_6_sent', '==', false)
      .where('reminder_6_days', '<=', now)
      .get();

    logger.info(`Found ${reminder6Query.docs.length} reminders for day 6`);

    for (const doc of reminder6Query.docs) {
      await sendReminderNotification(doc, 6);
      await doc.ref.update({ reminder_6_sent: true });
    }

    // Processar lembretes do 7º dia
    const reminder7Query = await db
      .collection('purchase_reminders')
      .where('status', '==', 'active')
      .where('reminder_7_sent', '==', false)
      .where('reminder_7_days', '<=', now)
      .get();

    logger.info(`Found ${reminder7Query.docs.length} reminders for day 7`);

    for (const doc of reminder7Query.docs) {
      await sendReminderNotification(doc, 7);
      await doc.ref.update({ reminder_7_sent: true });
    }

    logger.info("✅ Purchase reminders processed successfully");

  } catch (error) {
    logger.error("❌ Error processing purchase reminders:", error);
    throw error;
  }
});

/**
 * Cloud Function agendada para limpar lembretes expirados
 * Executa diariamente à meia-noite para remover status "vou comprar" expirados
 */
export const cleanupExpiredReminders = onSchedule({
  schedule: "0 1 * * *", // Diariamente à 1h da manhã
  timeZone: "Europe/Lisbon",
  timeoutSeconds: 540,
  memory: "512MiB"
}, async (event) => {
  logger.info("🧹 Cleaning up expired reminders...");

  try {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // Buscar lembretes expirados
    const expiredQuery = await db
      .collection('purchase_reminders')
      .where('status', '==', 'active')
      .where('expiration_date', '<=', now)
      .get();

    logger.info(`Found ${expiredQuery.docs.length} expired reminders`);

    for (const doc of expiredQuery.docs) {
      const data = doc.data();
      const wishItemId = data.wish_item_id;
      const userId = data.user_id;

      // Remover o status "vou comprar" do item
      const statusQuery = await db
        .collection('wish_item_statuses')
        .where('wish_item_id', '==', wishItemId)
        .where('user_id', '==', userId)
        .where('status', '==', 'will_buy')
        .get();

      for (const statusDoc of statusQuery.docs) {
        await statusDoc.ref.delete();
        logger.info(`Removed expired status for item ${wishItemId} user ${userId}`);
      }

      // Marcar lembrete como expirado
      await doc.ref.update({
        status: 'expired',
        expired_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Enviar notificação de expiração
      await sendExpirationNotification(data);
    }

    logger.info("✅ Expired reminders cleaned up successfully");

  } catch (error) {
    logger.error("❌ Error cleaning up expired reminders:", error);
    throw error;
  }
});

/**
 * Cloud Function para processar fila de notificações
 * Executa a cada 5 minutos para enviar notificações pendentes
 */
export const processNotificationQueue = onSchedule({
  schedule: "*/5 * * * *", // A cada 5 minutos
  timeZone: "Europe/Lisbon",
  timeoutSeconds: 540,
  memory: "512MiB"
}, async (event) => {
  logger.info("📱 Processing notification queue...");

  try {
    const db = admin.firestore();

    // Buscar notificações pendentes
    const pendingQuery = await db
      .collection('notifications_queue')
      .where('status', '==', 'pending')
      .limit(50) // Processar em lotes de 50
      .get();

    logger.info(`Found ${pendingQuery.docs.length} pending notifications`);

    for (const doc of pendingQuery.docs) {
      const data = doc.data();

      try {
        // Enviar notificação via FCM
        await admin.messaging().send({
          token: data.fcm_token,
          notification: {
            title: data.title,
            body: data.body,
          },
          data: data.data || {},
          android: {
            priority: 'high',
            notification: {
              channelId: 'purchase_reminders',
              icon: 'ic_notification',
              color: '#FF6B35',
            },
          },
        });

        // Marcar como enviada
        await doc.ref.update({
          status: 'sent',
          sent_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        logger.info(`Notification sent successfully to user ${data.user_id}`);

      } catch (error) {
        logger.error(`Failed to send notification to user ${data.user_id}:`, error);

        // Marcar como falhada
        await doc.ref.update({
          status: 'failed',
          failed_at: admin.firestore.FieldValue.serverTimestamp(),
          error_message: error instanceof Error ? error.message : String(error),
        });
      }
    }

    logger.info("✅ Notification queue processed successfully");

  } catch (error) {
    logger.error("❌ Error processing notification queue:", error);
    throw error;
  }
});

/**
 * Função auxiliar para enviar notificação de lembrete
 */
async function sendReminderNotification(doc: FirebaseFirestore.QueryDocumentSnapshot, dayNumber: number) {
  try {
    const data = doc.data();
    const userId = data.user_id;
    const itemName = data.item_name;
    const wishlistId = data.wishlist_id;

    // Buscar token FCM do usuário
    const userDoc = await admin.firestore()
      .collection('user_profiles')
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      logger.info(`User profile not found for user ${userId}`);
      return;
    }

    const userData = userDoc.data()!;
    const fcmToken = userData.fcm_token;

    if (!fcmToken) {
      logger.info(`No FCM token found for user ${userId}`);
      return;
    }

    const isLastDay = dayNumber === 7;
    const title = isLastDay
      ? '⚡ Último dia para comprar!'
      : '🔔 Lembrete de compra';

    const body = isLastDay
      ? `Hoje é o último dia para marcar "${itemName}" como comprado. Depois de hoje, a reserva será cancelada.`
      : `Faltam ${8 - dayNumber} dias para completar a compra de "${itemName}".`;

    // Adicionar à fila de notificações
    await admin.firestore().collection('notifications_queue').add({
      user_id: userId,
      fcm_token: fcmToken,
      title: title,
      body: body,
      data: {
        type: 'purchase_reminder',
        wish_item_id: data.wish_item_id,
        wishlist_id: wishlistId,
        day_number: dayNumber.toString(),
      },
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
    });

    logger.info(`Reminder notification queued: ${itemName} (day ${dayNumber}) for user ${userId}`);

  } catch (error) {
    logger.error(`Error sending reminder notification:`, error);
  }
}

/**
 * Função auxiliar para enviar notificação de expiração
 */
async function sendExpirationNotification(reminderData: any) {
  try {
    const userId = reminderData.user_id;
    const itemName = reminderData.item_name;

    // Buscar token FCM do usuário
    const userDoc = await admin.firestore()
      .collection('user_profiles')
      .doc(userId)
      .get();

    if (!userDoc.exists) return;

    const userData = userDoc.data()!;
    const fcmToken = userData.fcm_token;

    if (!fcmToken) return;

    // Adicionar à fila de notificações
    await admin.firestore().collection('notifications_queue').add({
      user_id: userId,
      fcm_token: fcmToken,
      title: '❌ Reserva cancelada',
      body: `A reserva de "${itemName}" foi cancelada após 7 dias. Podes voltar a marcá-lo como "vou comprar" se necessário.`,
      data: {
        type: 'purchase_expired',
        wish_item_id: reminderData.wish_item_id,
        wishlist_id: reminderData.wishlist_id,
      },
      created_at: admin.firestore.FieldValue.serverTimestamp(),
      status: 'pending',
    });

    logger.info(`Expiration notification queued for user ${userId}`);

  } catch (error) {
    logger.error(`Error sending expiration notification:`, error);
  }
}

