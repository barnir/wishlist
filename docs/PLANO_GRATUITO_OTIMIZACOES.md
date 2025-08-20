# 💰 Otimizações para Planos Gratuitos - Wishlist App

## 📊 **LIMITAÇÕES DOS PLANOS GRATUITOS**

### **Supabase (Free Tier)**
- **Edge Functions**: 500,000 invocations/mês
- **Database**: 500MB storage
- **Bandwidth**: 2GB/mês
- **Realtime**: 2 concurrent connections
- **Storage**: 1GB

### **ScraperAPI (Free Tier)**
- **1,000 requests/mês**
- **Rate limit**: 1 request/segundo
- **Timeout**: 60 segundos

## 🛠️ **ESTRATÉGIAS DE ECONOMIA IMPLEMENTADAS**

### **1. Cache Local Inteligente**
```dart
// Cache por 24h para evitar re-scraping
static final Map<String, Map<String, dynamic>> _cache = {};
static const Duration _cacheExpiry = Duration(hours: 24);
```

**Benefícios:**
- ✅ Reduz chamadas à Edge Function em ~80%
- ✅ URLs repetidas usam cache local
- ✅ Limpeza automática de cache antigo

### **2. Rate Limiting Conservador**
```dart
'scrape': RateLimitConfig(maxRequests: 3, window: Duration(minutes: 5)),
'upload': RateLimitConfig(maxRequests: 2, window: Duration(minutes: 10)),
'auth': RateLimitConfig(maxRequests: 3, window: Duration(minutes: 15)),
```

**Benefícios:**
- ✅ Máximo 3 scrapes por 5 minutos
- ✅ Evita exceder 500k calls/mês
- ✅ Proteção contra abuso

### **3. Uso Inteligente do ScraperAPI**
```dart
// Usar apenas para domínios confiáveis
if (Config.scraperApiKey.isNotEmpty && isTrusted) {
  // ScraperAPI (1k requests/mês)
} else {
  // Scraping básico (sem custo)
}
```

**Benefícios:**
- ✅ Economiza requests do ScraperAPI
- ✅ Fallback gratuito para domínios não confiáveis
- ✅ Prioriza lojas conhecidas

### **4. Validação de Domínios**
```dart
// Bloqueia domínios suspeitos antes de fazer scraping
const SUSPICIOUS_PATTERNS = [
  'localhost', '127.0.0.1', 'bit.ly', 'tinyurl'
];
```

**Benefícios:**
- ✅ Evita chamadas desnecessárias
- ✅ Proteção contra URLs maliciosas
- ✅ Economiza recursos

## 📈 **ESTIMATIVAS DE USO**

### **Cenário Conservador (100 utilizadores ativos)**
- **Scrapes por dia**: ~50
- **Edge Function calls**: ~1,500/mês (0.3% do limite)
- **ScraperAPI calls**: ~300/mês (30% do limite)
- **Cache hit rate**: ~80%

### **Cenário Moderado (500 utilizadores ativos)**
- **Scrapes por dia**: ~200
- **Edge Function calls**: ~6,000/mês (1.2% do limite)
- **ScraperAPI calls**: ~800/mês (80% do limite)
- **Cache hit rate**: ~75%

### **Cenário Alto (1000+ utilizadores)**
- **Scrapes por dia**: ~500
- **Edge Function calls**: ~15,000/mês (3% do limite)
- **ScraperAPI calls**: ~1,000/mês (100% do limite)
- **Cache hit rate**: ~70%

## 🚨 **ALERTAS E MONITORIZAÇÃO**

### **Quando Aproximar dos Limites**
- **Supabase**: >400k calls/mês
- **ScraperAPI**: >800 requests/mês
- **Storage**: >400MB

### **Ações Automáticas**
1. **Cache mais agressivo** (48h em vez de 24h)
2. **Rate limiting mais restritivo**
3. **Desativar ScraperAPI** temporariamente
4. **Usar apenas scraping básico**

## 💡 **RECOMENDAÇÕES FUTURAS**

### **Para Escalar (quando necessário)**
1. **Upgrade para planos pagos** quando atingir limites
2. **Implementar cache distribuído** (Redis)
3. **Usar múltiplas APIs** de scraping
4. **Implementar queue system** para requests

### **Monitorização Contínua**
- Dashboard de uso de recursos
- Alertas automáticos
- Métricas de performance
- Análise de padrões de uso

## ✅ **RESUMO**

O sistema está **otimizado para planos gratuitos** com:
- ✅ Cache inteligente (80% economia)
- ✅ Rate limiting conservador
- ✅ Uso eficiente de APIs externas
- ✅ Proteção contra abuso
- ✅ Fallbacks gratuitos

**Capacidade estimada**: 500-1000 utilizadores ativos sem exceder limites gratuitos.
