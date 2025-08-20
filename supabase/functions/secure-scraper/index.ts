import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { corsHeaders } from "../_shared/cors.ts"

// Lista de domínios permitidos para scraping
const ALLOWED_DOMAINS = [
  // Amazon (todas as regiões)
  'amazon.com', 'amazon.pt', 'amazon.es', 'amazon.fr', 'amazon.co.uk', 'amazon.de', 'amazon.it',
  // eBay (todas as regiões)
  'ebay.com', 'ebay.pt', 'ebay.es', 'ebay.fr', 'ebay.co.uk', 'ebay.de', 'ebay.it',
  // Plataformas internacionais populares
  'aliexpress.com', 'aliexpress.us', 'pt.aliexpress.com',
  'shein.com', 'pt.shein.com', 'es.shein.com', 'fr.shein.com',
  'wish.com', 'pt.wish.com',
  'temu.com', 'pt.temu.com',
  'banggood.com', 'pt.banggood.com',
  'gearbest.com',
  'dhgate.com',
  // Lojas portuguesas/espanholas
  'mercadolivre.pt', 'mercadolivre.com.br',
  'fnac.pt', 'fnac.com', 'fnac.es', 'fnac.fr',
  'worten.pt', 'worten.es',
  'pcdiga.pt',
  'globaldata.pt',
  'novoatalho.pt',
  'continente.pt',
  'elcorteingles.pt', 'elcorteingles.es',
  'mediamarkt.pt', 'mediamarkt.es',
  'radiopopular.pt',
  'kuantokusta.pt',
  // Outras lojas populares
  'zalando.pt', 'zalando.es', 'zalando.fr',
  'hm.com', 'zara.com',
  'nike.com', 'adidas.com', 'adidas.pt',
  'booking.com', 'hotels.com',
  'leroy.pt', 'leroymerlin.es'
];

// User-Agent para parecer um browser real
const USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

interface ScrapedData {
  title: string;
  price: string;
  image: string;
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
    
    // Verificar se o domínio está na lista de permitidos
    const hostname = urlObj.hostname.toLowerCase();
    const isAllowed = ALLOWED_DOMAINS.some(domain => 
      hostname === domain || hostname.endsWith('.' + domain)
    );
    
    if (!isAllowed) {
      throw new Error(`Domínio não permitido: ${hostname}. Domínios permitidos: ${ALLOWED_DOMAINS.join(', ')}`);
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
  
  return {
    title: title || 'Título não encontrado',
    price: priceData.price || '0.00',
    currency: priceData.currency || 'EUR',
    image: image || '',
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
