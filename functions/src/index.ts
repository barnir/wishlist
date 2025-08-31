import * as admin from "firebase-admin";
import { logger } from "firebase-functions";
import { onCall, HttpsError } from "firebase-functions/v2/https";
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
  } catch (e:any) {
    // Fallback: if doc missing fields, recompute fully
    logger.warn("adjustWishlistAggregates fallback recompute", {wishlistId, error: String(e)});
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
  }, {merge: true});
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
  const summary: DeletionSummary = {wishlistsDeleted: 0, wishItemsDeleted: 0, userDocDeleted: false};

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
        cloudinary.config({cloud_name: cloudName, api_key: apiKey, api_secret: apiSecret});
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
                const res = await cloudinary.api.delete_resources(slice, {invalidate: true});
                const deletedIds = Object.keys(res.deleted || {}).filter(k => res.deleted[k] === 'deleted');
                summary.cloudinaryImagesDeleted = (summary.cloudinaryImagesDeleted || 0) + deletedIds.length;
              } catch (e:any) {
                logger.warn('Cloudinary deletion partial failure', {error: String(e)});
              }
            }
        }
      } catch (e:any) {
        logger.warn('Cloudinary cleanup skipped/failed', {error: String(e)});
      }
    }

    logger.info('User data deletion summary', {uid, summary});
    return summary;
  } catch (e:any) {
    logger.error('deleteUser error', {uid, error: String(e)});
    throw new HttpsError('internal', 'Falha ao apagar dados do utilizador');
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
  const {JSDOM} = jsdom;
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
        const parts: string[] = rawParts.map((p: string, i: number, arr: string[]) => i===0 ? p + '}' : (i===arr.length-1? '{'+p : '{'+p+'}'));
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
    regexPrice = {symbol: symbolMatch[1], amount: symbolMatch[2]};
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

