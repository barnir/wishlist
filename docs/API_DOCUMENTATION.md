# 📚 Documentação da API - Wishlist App

## 🔧 Visão Geral

Esta documentação descreve a arquitetura técnica, APIs e serviços da aplicação Wishlist App.

## 🏗️ Arquitetura

### Stack Tecnológico
- **Frontend**: Flutter 3.8.1
- **Backend**: Supabase (PostgreSQL + Edge Functions)
- **Autenticação**: Supabase Auth + Google Sign-In
- **Storage**: Supabase Storage
- **Realtime**: Supabase Realtime
- **Deploy**: Supabase Edge Functions

### Diagrama de Arquitetura
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Supabase      │    │   External      │
│                 │    │   Backend       │    │   Services      │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • Auth Service  │◄──►│ • PostgreSQL    │    │ • Google APIs   │
│ • Database      │    │ • Auth          │    │ • ScraperAPI    │
│ • Storage       │    │ • Storage       │    │ • SMS Gateway   │
│ • Web Scraper   │    │ • Edge Functions│    │                 │
│ • Cache         │    │ • Realtime      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔐 Autenticação

### AuthService

#### Métodos Principais

##### `signInWithEmailAndPassword(String email, String password)`
```dart
Future<AuthResponse> signInWithEmailAndPassword(String email, String password)
```
**Descrição**: Autenticação tradicional com email e password.

**Parâmetros**:
- `email` (String): Email do utilizador
- `password` (String): Password do utilizador

**Retorno**: `AuthResponse` com dados da sessão

**Exemplo**:
```dart
final authService = AuthService();
try {
  final response = await authService.signInWithEmailAndPassword(
    'user@example.com',
    'password123'
  );
  // Navegar para dashboard
} catch (e) {
  // Tratar erro
}
```

##### `createUserWithEmailAndPassword(String email, String password, String displayName)`
```dart
Future<AuthResponse> createUserWithEmailAndPassword(
  String email, 
  String password, 
  String displayName
)
```
**Descrição**: Criar nova conta com email e password.

**Validações de Password**:
- Mínimo 6 caracteres
- Pelo menos uma letra minúscula
- Pelo menos uma letra maiúscula
- Pelo menos um número
- Pelo menos um símbolo

##### `sendPhoneOtp(String phoneNumber)`
```dart
Future<void> sendPhoneOtp(String phoneNumber)
```
**Descrição**: Enviar código OTP via SMS.

**Parâmetros**:
- `phoneNumber` (String): Número de telefone no formato internacional

##### `verifyPhoneOtp(String phoneNumber, String otp)`
```dart
Future<AuthResponse> verifyPhoneOtp(String phoneNumber, String otp)
```
**Descrição**: Verificar código OTP e autenticar utilizador.

##### `signInWithGoogle()`
```dart
Future<GoogleSignInResult> signInWithGoogle()
```
**Descrição**: Autenticação via Google Sign-In.

**Retorno**: `GoogleSignInResult` enum
- `success`: Login bem-sucedido
- `cancelled`: Utilizador cancelou
- `failed`: Erro no processo
- `missingPhoneNumber`: Falta número de telefone

### Estados de Autenticação

```dart
enum GoogleSignInResult {
  success,
  cancelled,
  failed,
  missingPhoneNumber,
}
```

## 📊 Base de Dados

### SupabaseDatabaseService

#### Tabelas Principais

##### Users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE,
  phone_number TEXT UNIQUE NOT NULL,
  display_name TEXT,
  bio TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

##### Wishlists
```sql
CREATE TABLE wishlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  is_public BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

##### Wish Items
```sql
CREATE TABLE wish_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wishlist_id UUID REFERENCES wishlists(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2),
  image_url TEXT,
  product_url TEXT,
  priority INTEGER DEFAULT 1,
  is_purchased BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### Métodos Principais

##### Wishlists

###### `getUserWishlists(String userId)`
```dart
Future<List<Wishlist>> getUserWishlists(String userId)
```
**Descrição**: Obter todas as wishlists de um utilizador.

###### `createWishlist(String userId, Map<String, dynamic> data)`
```dart
Future<Wishlist?> createWishlist(String userId, Map<String, dynamic> data)
```
**Descrição**: Criar nova wishlist.

**Parâmetros**:
- `userId`: ID do utilizador
- `data`: Dados da wishlist (name, description, is_public)

###### `updateWishlist(String wishlistId, Map<String, dynamic> data)`
```dart
Future<bool> updateWishlist(String wishlistId, Map<String, dynamic> data)
```
**Descrição**: Atualizar wishlist existente.

###### `deleteWishlist(String wishlistId)`
```dart
Future<bool> deleteWishlist(String wishlistId)
```
**Descrição**: Eliminar wishlist e todos os seus items.

##### Wish Items

###### `getWishlistItems(String wishlistId)`
```dart
Future<List<WishItem>> getWishlistItems(String wishlistId)
```
**Descrição**: Obter todos os items de uma wishlist.

###### `addWishItem(String wishlistId, Map<String, dynamic> data)`
```dart
Future<WishItem?> addWishItem(String wishlistId, Map<String, dynamic> data)
```
**Descrição**: Adicionar novo item à wishlist.

**Parâmetros**:
- `wishlistId`: ID da wishlist
- `data`: Dados do item (name, description, price, image_url, product_url, priority)

###### `updateWishItem(String itemId, Map<String, dynamic> data)`
```dart
Future<bool> updateWishItem(String itemId, Map<String, dynamic> data)
```
**Descrição**: Atualizar item existente.

###### `deleteWishItem(String itemId)`
```dart
Future<bool> deleteWishItem(String itemId)
```
**Descrição**: Eliminar item da wishlist.

###### `togglePurchased(String itemId)`
```dart
Future<bool> togglePurchased(String itemId)
```
**Descrição**: Alternar estado de comprado/não comprado.

## 📸 Storage

### SupabaseStorageServiceSecure

#### Configurações de Segurança
```dart
static const int maxFileSize = 5 * 1024 * 1024; // 5MB
static const List<String> allowedMimeTypes = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/gif'
];
```

#### Métodos Principais

##### `uploadImage(File imageFile, String path, {String? userId})`
```dart
Future<String?> uploadImage(File imageFile, String path, {String? userId})
```
**Descrição**: Upload seguro de imagem com validações.

**Validações**:
1. Tamanho do arquivo (máx. 5MB)
2. Tipo MIME permitido
3. Magic bytes para validação de tipo
4. Sanitização do nome do arquivo
5. Otimização automática da imagem

**Retorno**: URL pública da imagem ou null se erro

##### `uploadImageFromUrl(String imageUrl, String path)`
```dart
Future<String?> uploadImageFromUrl(String imageUrl, String path)
```
**Descrição**: Download e upload de imagem a partir de URL.

**Validações**:
- URL válida (HTTP/HTTPS)
- Tamanho da imagem
- Tipo MIME permitido
- Magic bytes

##### `deleteImage(String imageUrl)`
```dart
Future<bool> deleteImage(String imageUrl)
```
**Descrição**: Eliminar imagem do storage.

**Validações**:
- URL pertence ao nosso bucket
- Path traversal protection

##### `getStorageStats()`
```dart
Future<Map<String, dynamic>> getStorageStats()
```
**Descrição**: Obter estatísticas de uso do storage.

**Retorno**:
```dart
{
  'totalFiles': 42,
  'totalSize': 1048576,
  'typeCount': {
    'image/jpeg': 30,
    'image/png': 12
  },
  'bucketName': 'wishlist-images'
}
```

## 🛍️ Web Scraping

### WebScraperServiceSecure

#### Domínios Suportados
```dart
const allowedDomains = [
  'amazon.com', 'amazon.pt', 'amazon.es', 'amazon.fr', 'amazon.co.uk',
  'ebay.com', 'ebay.pt', 'ebay.es', 'ebay.fr', 'ebay.co.uk',
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
  'kuantokusta.pt'
];
```

#### Métodos Principais

##### `scrape(String url, {String? userId})`
```dart
Future<Map<String, dynamic>> scrape(String url, {String? userId})
```
**Descrição**: Fazer scraping de uma URL com rate limiting.

**Processo**:
1. Validar domínio permitido
2. Tentar Edge Function segura
3. Fallback para ScraperAPI
4. Fallback para scraping básico
5. Sanitizar dados extraídos

**Retorno**:
```dart
{
  'title': 'Nome do Produto',
  'price': '29.99',
  'image': 'https://example.com/image.jpg',
  'currency': 'EUR',
  'availability': 'Em Stock'
}
```

#### Rate Limiting
- **Scraping**: 5 requests/user, 10 requests/IP por 2 minutos
- **Upload**: 3 requests/user, 5 requests/IP por 5 minutos
- **Auth**: 5 requests/user, 10 requests/IP por 10 minutos

## 🔄 Cache

### CacheService

#### Métodos Principais

##### `setString(String key, String value, {Duration? expiry})`
```dart
Future<void> setString(String key, String value, {Duration? expiry})
```
**Descrição**: Armazenar string no cache.

##### `getString(String key)`
```dart
Future<String?> getString(String key)
```
**Descrição**: Obter string do cache.

##### `setObject<T>(String key, T object, {Duration? expiry})`
```dart
Future<void> setObject<T>(String key, T object, {Duration? expiry})
```
**Descrição**: Armazenar objeto serializado no cache.

##### `getObject<T>(String key, T Function(Map<String, dynamic>) fromJson)`
```dart
Future<T?> getObject<T>(String key, T Function(Map<String, dynamic>) fromJson)
```
**Descrição**: Obter objeto deserializado do cache.

##### `remove(String key)`
```dart
Future<void> remove(String key)
```
**Descrição**: Remover item do cache.

##### `clear()`
```dart
Future<void> clear()
```
**Descrição**: Limpar todo o cache.

## 🚨 Tratamento de Erros

### ErrorService

#### Categorias de Erro
```dart
enum ErrorCategory {
  auth,
  network,
  storage,
  database,
  validation,
  scraping,
  general
}
```

#### Métodos Principais

##### `logError(String category, dynamic error, StackTrace? stackTrace)`
```dart
static void logError(String category, dynamic error, StackTrace? stackTrace)
```
**Descrição**: Registrar erro centralizado.

**Parâmetros**:
- `category`: Categoria do erro
- `error`: Objeto de erro
- `stackTrace`: Stack trace opcional

##### `getErrorMessage(dynamic error)`
```dart
static String getErrorMessage(dynamic error)
```
**Descrição**: Obter mensagem de erro amigável.

##### `getErrorSuggestion(dynamic error)`
```dart
static String? getErrorSuggestion(dynamic error)
```
**Descrição**: Obter sugestão para resolver o erro.

## 📊 Monitorização

### PerformanceService

#### Métodos Principais

##### `recordOperation(String name, Future<void> Function() operation)`
```dart
static Future<void> recordOperation(String name, Future<void> Function() operation)
```
**Descrição**: Monitorizar performance de operação.

##### `recordMetric(String name, double value)`
```dart
static void recordMetric(String name, double value)
```
**Descrição**: Registrar métrica de performance.

##### `getMetrics()`
```dart
static Map<String, dynamic> getMetrics()
```
**Descrição**: Obter métricas registradas.

## 🔧 Edge Functions

### secure-scraper

#### Endpoint
```
POST /functions/v1/secure-scraper
```

#### Request Body
```json
{
  "url": "https://amazon.pt/product/123"
}
```

#### Response
```json
{
  "title": "Nome do Produto",
  "price": "29.99",
  "image": "https://example.com/image.jpg",
  "currency": "EUR",
  "availability": "Em Stock"
}
```

### delete-user

#### Endpoint
```
POST /functions/v1/delete-user
```

#### Request Body
```json
{
  "userId": "uuid-do-utilizador"
}
```

#### Response
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

## 📱 Widgets API

### WishlistAppBar
```dart
WishlistAppBar({
  required String title,
  List<Widget>? actions,
  bool showBackButton = true,
  VoidCallback? onBackPressed,
})
```

### WishlistButton
```dart
WishlistButton({
  required String text,
  VoidCallback? onPressed,
  bool isLoading = false,
  bool isPrimary = true,
  IconData? icon,
  double? width,
  double height = 48,
})
```

### WishlistTextField
```dart
WishlistTextField({
  required String label,
  String? hint,
  TextEditingController? controller,
  String? Function(String?)? validator,
  TextInputType? keyboardType,
  bool obscureText = false,
  Widget? prefixIcon,
  Widget? suffixIcon,
  int? maxLines = 1,
  int? maxLength,
  bool enabled = true,
})
```

### WishlistEmptyState
```dart
WishlistEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
  String? actionText,
  VoidCallback? onAction,
})
```

## 🔒 Segurança

### Validações Implementadas

#### Input Sanitization
- Remoção de caracteres perigosos
- Validação de tipos de dados
- Sanitização de URLs
- Proteção contra SQL injection

#### File Upload Security
- Validação de tipo MIME
- Verificação de magic bytes
- Limite de tamanho de arquivo
- Sanitização de nomes de arquivo

#### Rate Limiting
- Limites por utilizador
- Limites por IP
- Janelas de tempo configuráveis
- Proteção contra abuso

#### Row Level Security (RLS)
```sql
-- Política para users
CREATE POLICY "Users can view their own profile" ON users
  FOR SELECT USING (auth.uid() = id);

-- Política para wishlists
CREATE POLICY "Users can manage their own wishlists" ON wishlists
  FOR ALL USING (auth.uid() = user_id);

-- Política para wish_items
CREATE POLICY "Users can manage items in their wishlists" ON wish_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM wishlists 
      WHERE wishlists.id = wish_items.wishlist_id 
      AND wishlists.user_id = auth.uid()
    )
  );
```

## 📈 Performance

### Otimizações Implementadas

#### Lazy Loading
- Carregamento sob demanda de imagens
- Paginação de listas
- Cache inteligente

#### Image Optimization
- Compressão automática
- Redimensionamento
- Formatos otimizados

#### Database Optimization
- Índices estratégicos
- Queries otimizadas
- Connection pooling

#### Network Optimization
- Request batching
- Response caching
- Compression

## 🧪 Testes

### Estrutura de Testes

#### Unit Tests
```dart
// test/unit/services/auth_service_test.dart
void main() {
  group('AuthService', () {
    test('should sign in with valid credentials', () async {
      // Test implementation
    });
  });
}
```

#### Widget Tests
```dart
// test/widget/screens/login_screen_test.dart
void main() {
  testWidgets('should show login form', (WidgetTester tester) async {
    // Test implementation
  });
}
```

#### Integration Tests
```dart
// test/integration/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full app flow', (WidgetTester tester) async {
    // Test implementation
  });
}
```

## 📝 Logs e Debugging

### Estrutura de Logs

#### Debug Logs
```dart
debugPrint('Loading wishlists for user: $userId');
```

#### Error Logs
```dart
ErrorService.logError('auth_failed', error, stackTrace);
```

#### Performance Logs
```dart
PerformanceService.recordOperation('load_wishlists', () async {
  // Operation
});
```

### Debugging Tools

#### Flutter Inspector
- Widget tree inspection
- Performance profiling
- Memory analysis

#### Supabase Dashboard
- Database queries
- Authentication logs
- Storage usage

#### Custom Debug Tools
- Error tracking
- Performance monitoring
- User analytics

---

**Última atualização**: Janeiro 2025
**Versão**: 1.0.0
