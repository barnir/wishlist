import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { corsHeaders } from "../_shared/cors.ts"

// Lista massiva de domínios confiáveis para scraping
const TRUSTED_DOMAINS = [
  // === MARKETPLACES GLOBAIS ===
  // Amazon (todas as regiões)
  'amazon.com', 'amazon.pt', 'amazon.es', 'amazon.fr', 'amazon.co.uk', 
  'amazon.de', 'amazon.it', 'amazon.ca', 'amazon.com.br', 'amazon.in',
  'amazon.com.mx', 'amazon.co.jp', 'amazon.com.au', 'amazon.sg',
  // eBay (todas as regiões)
  'ebay.com', 'ebay.pt', 'ebay.es', 'ebay.fr', 'ebay.co.uk', 
  'ebay.de', 'ebay.it', 'ebay.ca', 'ebay.com.au', 'ebay.in',
  // AliExpress
  'aliexpress.com', 'aliexpress.us', 'pt.aliexpress.com', 'es.aliexpress.com',
  'fr.aliexpress.com', 'de.aliexpress.com', 'it.aliexpress.com',
  // Outros marketplaces asiáticos
  'shein.com', 'pt.shein.com', 'es.shein.com', 'fr.shein.com', 'de.shein.com',
  'wish.com', 'pt.wish.com', 'es.wish.com',
  'temu.com', 'pt.temu.com', 'es.temu.com',
  'banggood.com', 'pt.banggood.com', 'es.banggood.com',
  'gearbest.com', 'dhgate.com', 'lightinthebox.com',
  
  // === LOJAS PORTUGUESAS ===
  'fnac.pt', 'worten.pt', 'pcdiga.pt', 'globaldata.pt', 'novoatalho.pt',
  'continente.pt', 'radiopopular.pt', 'kuantokusta.pt', 'chupamobile.pt',
  'bertrand.pt', 'staples.pt', 'ikea.com', 'leroy.pt',
  'celeiro.pt', 'prozis.com', 'mango.com', 'parfois.com',
  
  // === LOJAS ESPANHOLAS ===
  'elcorteingles.es', 'mediamarkt.es', 'worten.es', 'fnac.es',
  'carrefour.es', 'alcampo.es', 'leroymerlin.es', 'pccomponentes.com',
  
  // === MODA INTERNACIONAL ===
  'zara.com', 'hm.com', 'uniqlo.com', 'gap.com', 'forever21.com',
  'asos.com', 'boohoo.com', 'prettylittlething.com', 'missguided.com',
  'zalando.pt', 'zalando.es', 'zalando.fr', 'zalando.de', 'zalando.it',
  'aboutyou.pt', 'aboutyou.es', 'aboutyou.fr', 'aboutyou.de',
  
  // === DESPORTO ===
  'nike.com', 'adidas.com', 'adidas.pt', 'puma.com', 'reebok.com',
  'underarmour.com', 'newbalance.com', 'asics.com', 'vans.com',
  'converse.com', 'timberland.com', 'sportzone.pt', 'intersport.pt',
  
  // === ELETRÔNICOS ===
  'apple.com', 'samsung.com', 'sony.com', 'lg.com', 'philips.com',
  'asus.com', 'hp.com', 'dell.com', 'lenovo.com', 'acer.com',
  'bestbuy.com', 'newegg.com', 'bhphotovideo.com',
  
  // === CASA E JARDIM ===
  'ikea.com', 'homedepot.com', 'lowes.com', 'wayfair.com',
  'overstock.com', 'bedbathandbeyond.com', 'williams-sonoma.com',
  
  // === LIVROS ===
  'bookdepository.com', 'waterstones.com', 'barnesandnoble.com',
  'thriftbooks.com', 'abebooks.com', 'bertrand.pt',
  
  // === BELEZA ===
  'sephora.com', 'ulta.com', 'beautylish.com', 'lookfantastic.com',
  'feelunique.com', 'strawberrynet.com', 'douglas.pt', 'douglas.es',
  
  // === VIAGENS ===
  'booking.com', 'expedia.com', 'hotels.com', 'trivago.com',
  'airbnb.com', 'vrbo.com', 'momondo.com', 'kayak.com',
  
  // === MERCADO LIVRE ===
  'mercadolivre.pt', 'mercadolivre.com.br', 'mercadolibre.com.ar',
  'mercadolibre.com.mx', 'mercadolibre.cl', 'mercadolibre.com.co',
  
  // === OUTROS EUROPEUS ===
  'bol.com', 'coolblue.nl', 'otto.de', 'alternate.de',
  'conforama.fr', 'darty.fr', 'cdiscount.fr', 'rue-du-commerce.com',
  'pixmania.com', 'grosbill.com', 'ldlc.com'
];

// Padrões suspeitos que devemos sempre bloquear
const SUSPICIOUS_PATTERNS = [
  'localhost', '127.0.0.1', '0.0.0.0', '192.168.',
  'file://', 'data:', 'javascript:', 'vbscript:',
  '.onion', 'bit.ly', 'tinyurl', 'ow.ly', 't.co'
];

// Indicadores de sites de e-commerce legítimos
const ECOMMERCE_INDICATORS = [
  'shop', 'store', 'loja', 'tienda', 'boutique', 'market',
  'buy', 'sell', 'commerce', 'retail', 'outlet',
  'fashion', 'clothing', 'electronics', 'books', 'games'
];

// TLD confiáveis para e-commerce
const TRUSTED_TLDS = [
  '.com', '.pt', '.es', '.fr', '.de', '.it', '.co.uk',
  '.net', '.org', '.eu', '.shop', '.store'
];

// User-Agent para parecer um browser real
const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

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

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { url } = await req.json()
    
    if (!url || typeof url !== 'string') {
      return new Response(
        JSON.stringify({ error: 'URL é obrigatória' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Validar e normalizar URL
    const validatedUrl = validateAndNormalizeUrl(url);
    
    // Fazer scraping seguro
    const scrapedData = await scrapeWithSanitization(validatedUrl);
    
    return new Response(
      JSON.stringify(scrapedData),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
    
  } catch (error) {
    console.error('Scraping error:', error);
    
    return new Response(
      JSON.stringify({ 
        error: error.message || 'Erro ao fazer scraping da URL',
        title: 'Could not fetch title',
        price: '0.00',
        image: ''
      }),
      { 
        status: 400, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})

function validateAndNormalizeUrl(url: string): string {
  try {
    // Normalizar URL
    let normalizedUrl = url.trim();
    
    // Adicionar protocolo se não tiver
    if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://' + normalizedUrl;
    }
    
    const urlObj = new URL(normalizedUrl);
    const hostname = urlObj.hostname.toLowerCase();
    
    // Verificar padrões suspeitos primeiro
    const isSuspicious = SUSPICIOUS_PATTERNS.some(pattern => 
      hostname.includes(pattern)
    );
    
    if (isSuspicious) {
      throw new Error(`Domínio suspeito bloqueado: ${hostname}`);
    }
    
    // Verificar se é domínio confiável
    const isTrusted = TRUSTED_DOMAINS.some(domain => 
      hostname === domain || hostname.endsWith('.' + domain)
    );
    
    // Se não for confiável, usar validação inteligente
    if (!isTrusted && !isValidEcommerceDomain(hostname)) {
      throw new Error(`Domínio não suportado: ${hostname}. Para segurança, apenas lojas verificadas ou com indicadores de e-commerce são permitidas.`);
    }
    
    // Verificar protocolo HTTPS (mais seguro)
    if (urlObj.protocol !== 'https:' && urlObj.protocol !== 'http:') {
      throw new Error('Apenas URLs HTTP/HTTPS são permitidas');
    }
    
    return normalizedUrl;
    
  } catch (error) {
    if (error instanceof TypeError) {
      throw new Error('URL inválida');
    }
    throw error;
  }
}

function isValidEcommerceDomain(hostname: string): boolean {
  // Verificar se contém indicadores de e-commerce
  const hasEcommerceIndicator = ECOMMERCE_INDICATORS.some(indicator => 
    hostname.includes(indicator)
  );
  
  // Verificar se tem TLD confiável
  const hasTrustedTld = TRUSTED_TLDS.some(tld => hostname.endsWith(tld));
  
  // Permitir se tem indicador de e-commerce E TLD confiável
  return hasEcommerceIndicator && hasTrustedTld;
}

async function scrapeWithSanitization(url: string): Promise<ScrapedData> {
  try {
    // Fazer request com timeout e headers seguros
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000); // 10s timeout
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'User-Agent': USER_AGENT,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'pt-PT,pt;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
      },
      signal: controller.signal
    });
    
    clearTimeout(timeoutId);
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    // Verificar content-type
    const contentType = response.headers.get('content-type') || '';
    if (!contentType.includes('text/html')) {
      throw new Error('URL não retorna HTML válido');
    }
    
    const html = await response.text();
    
    // Sanitizar e extrair dados
    const scrapedData = extractDataFromHtml(html, url);
    
    return scrapedData;
    
  } catch (error) {
    if (error.name === 'AbortError') {
      throw new Error('Timeout: URL demorou muito para responder');
    }
    throw error;
  }
}

function extractDataFromHtml(html: string, baseUrl: string): ScrapedData {
  // Limpar HTML de scripts maliciosos
  const cleanHtml = sanitizeHtml(html);
  
  // Extrair título
  const title = extractTitle(cleanHtml);
  
  // Extrair preço
  const priceData = extractPrice(cleanHtml);
  
  // Extrair imagem
  const image = extractImage(cleanHtml, baseUrl);
  
  // Extrair descrição
  const description = extractDescription(cleanHtml);
  
  // Extrair rating
  const rating = extractRating(cleanHtml);
  
  // Detectar categoria
  const category = detectCategory(title, description);
  
  return {
    title: title || 'Título não encontrado',
    price: priceData.price || '0.00',
    currency: priceData.currency || 'EUR',
    image: image || '',
    description: description || '',
    category: category || 'Outros',
    rating: rating || undefined,
    availability: extractAvailability(cleanHtml)
  };
}

function sanitizeHtml(html: string): string {
  // Remover scripts, iframes e outros elementos perigosos
  return html
    .replace(/<script[^>]*>.*?<\/script>/gsi, '')
    .replace(/<iframe[^>]*>.*?<\/iframe>/gsi, '')
    .replace(/<object[^>]*>.*?<\/object>/gsi, '')
    .replace(/<embed[^>]*>.*?<\/embed>/gsi, '')
    .replace(/<form[^>]*>.*?<\/form>/gsi, '')
    .replace(/on\w+\s*=\s*["'][^"']*["']/gi, '') // remover event handlers
    .replace(/javascript:/gi, ''); // remover javascript: URLs
}

function extractTitle(html: string): string {
  // Tentar vários seletores comuns para título
  const titleSelectors = [
    /<title[^>]*>([^<]+)<\/title>/i,
    /<h1[^>]*>([^<]+)<\/h1>/i,
    /<meta[^>]*property=["']og:title["'][^>]*content=["']([^"']+)["']/i,
    /<meta[^>]*name=["']title["'][^>]*content=["']([^"']+)["']/i,
    /<span[^>]*class=["'][^"']*title[^"']*["'][^>]*>([^<]+)<\/span>/i,
    /<div[^>]*class=["'][^"']*title[^"']*["'][^>]*>([^<]+)<\/div>/i
  ];
  
  for (const selector of titleSelectors) {
    const match = html.match(selector);
    if (match && match[1]) {
      return cleanText(match[1]);
    }
  }
  
  return '';
}

function extractPrice(html: string): { price: string; currency: string } {
  // Padrões melhorados para preços internacionais
  const pricePatterns = [
    // Euro
    /€\s*(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})/g,
    /(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})\s*€/g,
    /EUR\s*(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})/g,
    /(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})\s*EUR/g,
    // Dólar americano
    /\$\s*(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})/g,
    /(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})\s*\$/g,
    /USD\s*(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})/g,
    /(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})\s*USD/g,
    // Libra britânica
    /£\s*(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})/g,
    /(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})\s*£/g,
    /GBP\s*(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})/g,
    // Seletores de preço com classes comuns
    /price[^>]*>.*?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})/gi,
    /valor[^>]*>.*?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})/gi,
    /cost[^>]*>.*?(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})/gi,
    // Padrões genéricos melhorados
    /(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})/g
  ];
  
  const currencyMap: { [key: string]: string } = {
    '€': 'EUR',
    '$': 'USD', 
    '£': 'GBP'
  };
  
  for (const pattern of pricePatterns) {
    const matches = Array.from(html.matchAll(pattern));
    if (matches.length > 0) {
      const match = matches[0];
      const priceStr = match[1] || match[0];
      const cleanPrice = priceStr.replace(/[^\d.,]/g, '').replace(',', '.');
      
      if (parseFloat(cleanPrice) > 0) {
        // Detectar moeda
        let currency = 'EUR';
        for (const [symbol, code] of Object.entries(currencyMap)) {
          if (match[0].includes(symbol)) {
            currency = code;
            break;
          }
        }
        
        return { 
          price: parseFloat(cleanPrice).toFixed(2), 
          currency 
        };
      }
    }
  }
  
  return { price: '0.00', currency: 'EUR' };
}

function extractImage(html: string, baseUrl: string): string {
  // Tentar vários seletores para imagens
  const imageSelectors = [
    /<meta[^>]*property=["']og:image["'][^>]*content=["']([^"']+)["']/i,
    /<meta[^>]*name=["']twitter:image["'][^>]*content=["']([^"']+)["']/i,
    /<img[^>]*class=["'][^"']*product[^"']*["'][^>]*src=["']([^"']+)["']/i,
    /<img[^>]*src=["']([^"']+)["'][^>]*class=["'][^"']*product[^"']*["']/i,
    /<img[^>]*src=["']([^"']+)["'][^>]*alt=["'][^"']*product[^"']*["']/i
  ];
  
  for (const selector of imageSelectors) {
    const match = html.match(selector);
    if (match && match[1]) {
      let imageUrl = match[1];
      
      // Converter URL relativa para absoluta
      if (imageUrl.startsWith('//')) {
        imageUrl = 'https:' + imageUrl;
      } else if (imageUrl.startsWith('/')) {
        const base = new URL(baseUrl);
        imageUrl = base.origin + imageUrl;
      }
      
      // Validar se é uma imagem válida
      if (isValidImageUrl(imageUrl)) {
        return imageUrl;
      }
    }
  }
  
  return '';
}

function extractAvailability(html: string): string {
  const availabilityPatterns = [
    /em\s+stock/gi,
    /disponível/gi,
    /available/gi,
    /in\s+stock/gi,
    /esgotado/gi,
    /out\s+of\s+stock/gi
  ];
  
  for (const pattern of availabilityPatterns) {
    const match = html.match(pattern);
    if (match) {
      return match[0].toLowerCase().includes('esgotado') || 
             match[0].toLowerCase().includes('out') ? 'Esgotado' : 'Disponível';
    }
  }
  
  return 'Desconhecido';
}

function isValidImageUrl(url: string): boolean {
  try {
    const urlObj = new URL(url);
    const path = urlObj.pathname.toLowerCase();
    return path.endsWith('.jpg') || 
           path.endsWith('.jpeg') || 
           path.endsWith('.png') || 
           path.endsWith('.webp') ||
           path.endsWith('.gif');
  } catch {
    return false;
  }
}

function extractDescription(html: string): string {
  // Tentar vários seletores para descrições
  const descriptionSelectors = [
    /<meta[^>]*property=["']og:description["'][^>]*content=["']([^"']+)["']/i,
    /<meta[^>]*name=["']description["'][^>]*content=["']([^"']+)["']/i,
    /<div[^>]*class=["'][^"']*product-description[^"']*["'][^>]*>([^<]+)<\/div>/i,
    /<div[^>]*class=["'][^"']*description[^"']*["'][^>]*>([^<]+)<\/div>/i,
    /<p[^>]*class=["'][^"']*description[^"']*["'][^>]*>([^<]+)<\/p>/i,
    /<span[^>]*class=["'][^"']*desc[^"']*["'][^>]*>([^<]+)<\/span>/i
  ];
  
  for (const selector of descriptionSelectors) {
    const match = html.match(selector);
    if (match && match[1] && match[1].trim().length > 20) {
      const desc = cleanText(match[1]);
      return desc.length > 500 ? desc.substring(0, 497) + '...' : desc;
    }
  }
  
  // Procurar por parágrafos que podem conter descrições
  const paragraphPattern = /<p[^>]*>([^<]{50,300})<\/p>/gi;
  const paragraphs = Array.from(html.matchAll(paragraphPattern));
  
  for (const match of paragraphs) {
    const text = cleanText(match[1]);
    if (looksLikeProductDescription(text)) {
      return text;
    }
  }
  
  return '';
}

function extractRating(html: string): string {
  // Padrões para extrair ratings
  const ratingPatterns = [
    /rating[^>]*>.*?(\d+[.,]\d+)/gi,
    /estrelas[^>]*>.*?(\d+[.,]\d+)/gi,
    /stars[^>]*>.*?(\d+[.,]\d+)/gi,
    /score[^>]*>.*?(\d+[.,]\d+)/gi,
    /(\d+[.,]\d+)\s*(?:de\s*5|\/5|\*|estrelas|stars)/gi,
    /(\d+[.,]\d+)\s*rating/gi
  ];
  
  for (const pattern of ratingPatterns) {
    const matches = Array.from(html.matchAll(pattern));
    if (matches.length > 0) {
      const match = matches[0];
      const ratingStr = match[1].replace(',', '.');
      const rating = parseFloat(ratingStr);
      
      if (rating >= 0 && rating <= 5) {
        return rating.toFixed(1);
      }
    }
  }
  
  return '';
}

function detectCategory(title: string, description: string): string {
  const content = `${title.toLowerCase()} ${description.toLowerCase()}`;
  
  // Mapeamento de palavras-chave para categorias
  const categoryMappings: { [key: string]: string[] } = {
    'Livro': [
      'book', 'livro', 'novel', 'romance', 'biografia', 'ensaio', 'autor',
      'literatura', 'ficção', 'história', 'poetry', 'poesia', 'manual',
      'guia', 'encyclopedia', 'enciclopédia', 'dicionário', 'dictionary'
    ],
    'Eletrónico': [
      'smartphone', 'phone', 'telemóvel', 'tablet', 'laptop', 'computador',
      'headphones', 'auscultadores', 'camera', 'câmara', 'tv', 'televisão',
      'gaming', 'console', 'playstation', 'xbox', 'nintendo', 'electronic',
      'eletrónico', 'digital', 'tech', 'technology', 'gadget', 'device',
      'smart', 'wireless', 'bluetooth', 'usb', 'charger', 'carregador'
    ],
    'Viagem': [
      'mala', 'suitcase', 'bagagem', 'travel', 'viagem', 'flight', 'hotel',
      'vacation', 'férias', 'backpack', 'mochila', 'passport', 'passaporte',
      'luggage', 'trip', 'journey', 'tourism', 'turismo', 'destination'
    ],
    'Moda': [
      'fashion', 'moda', 'clothing', 'roupa', 'shirt', 'camisa', 'dress',
      'vestido', 'shoes', 'sapatos', 'jeans', 'jacket', 'casaco', 'pants',
      'calças', 'skirt', 'saia', 'blouse', 'blusa', 'style', 'estilo',
      'designer', 'brand', 'marca', 'accessories', 'acessórios', 'watch',
      'relógio', 'jewelry', 'jóias', 'bag', 'bolsa', 'hat', 'chapéu'
    ],
    'Casa': [
      'home', 'casa', 'furniture', 'móveis', 'kitchen', 'cozinha',
      'bathroom', 'casa de banho', 'bedroom', 'quarto', 'living room',
      'sala', 'decoration', 'decoração', 'appliance', 'eletrodoméstico',
      'cleaning', 'limpeza', 'garden', 'jardim', 'tool', 'ferramenta',
      'lamp', 'lâmpada', 'table', 'mesa', 'chair', 'cadeira', 'sofa'
    ]
  };
  
  // Contar matches para cada categoria
  const categoryScores: { [key: string]: number } = {};
  
  for (const [category, keywords] of Object.entries(categoryMappings)) {
    let score = 0;
    for (const keyword of keywords) {
      if (content.includes(keyword)) {
        score++;
      }
    }
    
    if (score > 0) {
      categoryScores[category] = score;
    }
  }
  
  // Retornar categoria com maior pontuação
  if (Object.keys(categoryScores).length > 0) {
    const sortedCategories = Object.entries(categoryScores)
      .sort(([,a], [,b]) => b - a);
    return sortedCategories[0][0];
  }
  
  // Default fallback
  return 'Outros';
}

function looksLikeProductDescription(text: string): boolean {
  // Características de descrições de produto
  const productIndicators = [
    'característica', 'feature', 'especificação', 'specification',
    'material', 'cor', 'color', 'tamanho', 'size', 'dimensão',
    'qualidade', 'quality', 'design', 'style', 'marca', 'brand',
    'produto', 'product', 'artigo', 'item'
  ];
  
  const lowerText = text.toLowerCase();
  return productIndicators.some(indicator => lowerText.includes(indicator));
}

function cleanText(text: string): string {
  return text
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, ' ')
    .trim();
}
