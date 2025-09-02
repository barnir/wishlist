# 📱 Wishlist App (Exclusivamente Android)

Uma aplicação Flutter moderna para gestão de listas de desejos, com **internacionalização completa**, **integração Cloudinary otimizada** e interface Material 3. Projeto com **qualidade técnica perfeita** - zero Flutter analyze issues.

## 🚀 Características

### ✨ **Funcionalidades Principais**
- 🔐 **Autenticação Múltipla**: Email, telefone e Google Sign-In
- 🌍 **Internacionalização Completa**: Português e Inglês com ARB files
- 📋 **Gestão de Wishlists**: Criar, editar e organizar listas de desejos
- 🛍️ **Web Scraping Inteligente**: Extração automática via Firebase Cloud Functions
- 📸 **Cloudinary Integration**: Upload e otimização automática de imagens
- 🎨 **Material 3 Design**: Interface moderna com temas light/dark/system
- 🔄 **Firebase Realtime**: Sincronização instantânea via Firestore
- 📱 **Android Only**: Projeto suportado e mantido apenas para Android (sem web/iOS/desktop)

### 🛡️ **Segurança & Qualidade**
- **Zero Technical Debt**: Flutter analyze com 0 issues
- **Context Safety**: Guards implementadas em todas operações async
- **Validação Centralizada**: Sistema ValidationUtils internacionalizado
- **Firebase Security**: Cloud Functions para operações seguras
- **Image Security**: Cloudinary com transformações otimizadas
- **Anti-abuse**: Rate limiting e monitorização

### ⚡ **Performance**
- **Image Prefetch Service**: Carregamento inteligente de imagens
- **Cloudinary Optimization**: Transformações context-aware
- **Material 3 Compliance**: APIs atualizadas e não-deprecated
- **Lazy Loading**: Sistema de cache e loading otimizado
- **Clean Architecture**: Separação clara de responsabilidades

## 📋 Pré-requisitos

- **Flutter SDK**: ^3.22.0
- **Dart**: ^3.4.0 
- **Android Studio** ou **VS Code**
- **Firebase Project** (gratuito)
- **Cloudinary Account** (gratuito)
- **Dispositivo Android** ou **Emulador**

## 🛠️ Instalação

### 1. **Clone o Repositório**
```bash
git clone https://github.com/barnir/wishlist.git
cd wishlist_app
```

### 2. **Instalar Dependências**
```bash
flutter pub get
```

### 3. **Configurar Firebase**

#### 3.1 Criar Projeto Firebase
1. Aceda a [console.firebase.google.com](https://console.firebase.google.com)
2. Crie um novo projeto
3. Ative Authentication, Firestore e Cloud Functions
4. Configure o arquivo `google-services.json` em `android/app/`

#### 3.2 Configurar Cloudinary
1. Aceda a [cloudinary.com](https://cloudinary.com)
2. Crie uma conta gratuita
3. Anote o **Cloud Name**, **API Key** e **API Secret**

#### 3.3 Configurar Variáveis de Ambiente (Cliente Flutter)
Crie um arquivo `.env` na raiz do projeto contendo APENAS as chaves realmente lidas pela app:

```env
# Cloudinary (uploads UNSIGNED)
CLOUDINARY_CLOUD_NAME=seu_cloud_name
CLOUDINARY_UPLOAD_PRESET=wishlist_unsigned

# Google Sign-In (opcional – web client ID para server auth code flow)
GOOGLE_SIGN_IN_SERVER_CLIENT_ID=seu_client_id_google
```

Notas importantes:
- NÃO colocar API Key nem API Secret do Cloudinary no cliente (risco de abuso / quota / manipulação).
- Configuração Firebase (API key, project id, etc.) vem exclusivamente do `google-services.json` colocado em `android/app/` – não duplicar no `.env`.
- Se precisar usar a Cloudinary API Secret (ex: limpeza, deleção administrativa) faça isso apenas em Cloud Functions usando variáveis de ambiente seguras (`firebase functions:config:set` ou Secret Manager) e NÃO no repositório.

Backend (Cloud Functions) – exemplo de configuração segura (não commitado):
```
firebase functions:config:set cloudinary.cloud_name="seu_cloud_name" cloudinary.api_key="xxxxx" cloudinary.api_secret="xxxxx"
```
E no código Functions ler via `process.env`/`functions.config()` em vez de `.env` do cliente.

### 4. **Deploy Cloud Functions**
```bash
cd functions
npm install
firebase deploy --only functions
```

### 5. **Executar a Aplicação**
```bash
flutter run
```

## 🏗️ Arquitetura do Projeto

```
lib/
├── config.dart                    # Configurações da aplicação
├── main.dart                      # Ponto de entrada
├── theme.dart                     # Material 3 themes (light/dark/system)
├── firebase_background_handler.dart # Push notifications handler
├── constants/                     # Constantes da aplicação
│   └── ui_constants.dart
├── generated/                     # Arquivos gerados automaticamente
│   └── l10n/                     # Internacionalização (PT/EN)
│       ├── app_localizations.dart
│       ├── app_localizations_en.dart
│       └── app_localizations_pt.dart
├── l10n/                         # Arquivos ARB de tradução
│   ├── app_en.arb
│   └── app_pt.arb
├── models/                       # Modelos de dados
│   ├── category.dart
│   ├── sort_options.dart
│   ├── user_favorite.dart
│   ├── wish_item.dart
│   ├── wish_item_status.dart
│   └── wishlist.dart
├── screens/                      # Telas da aplicação
│   ├── add_edit_item_screen.dart
│   ├── add_edit_wishlist_screen.dart
│   ├── add_phone_screen.dart
│   ├── explore_screen.dart
│   ├── friends_screen.dart
│   ├── friend_suggestions_screen.dart
│   ├── help_screen.dart
│   ├── login_screen.dart
│   ├── otp_screen.dart
│   ├── profile_screen.dart
│   ├── register_screen.dart
│   ├── setup_name_screen.dart
│   ├── user_profile_screen.dart
│   ├── wishlists_screen.dart
│   └── wishlist_details_screen.dart
├── services/                     # Serviços e lógica de negócio
│   ├── auth_service.dart
│   ├── cloudinary_service.dart
│   ├── contacts_service.dart
│   ├── favorites_service.dart
│   ├── fcm_service.dart
│   ├── firebase_auth_service.dart
│   ├── firebase_database_service.dart
│   ├── firebase_functions_service.dart
│   ├── haptic_service.dart
│   ├── image_cache_service.dart
│   ├── image_prefetch_service.dart
│   ├── language_service.dart
│   ├── monitoring_service.dart
│   ├── notification_service.dart
│   ├── rate_limiter_service.dart
│   ├── security_service.dart
│   ├── theme_service.dart
│   ├── web_scraper_service.dart
│   └── wish_item_status_service.dart
├── utils/                        # Utilitários
│   ├── page_transitions.dart
│   └── validation_utils.dart
└── widgets/                      # Widgets reutilizáveis
    ├── animated_widgets.dart
    ├── filter_bottom_sheet.dart
    ├── item_status_dialog.dart
    ├── language_selector_bottom_sheet.dart
    ├── lazy_image.dart
    ├── memoized_widgets.dart
    ├── optimized_cloudinary_image.dart
    ├── profile_edit_bottom_sheets.dart
    ├── profile_widgets.dart
    ├── skeleton_loading.dart
    ├── swipe_action_widget.dart
    ├── theme_selector_bottom_sheet.dart
    ├── ui_components.dart
    ├── wishlist_total.dart
    └── wish_item_tile.dart
```

## 🔧 Configuração do Firebase

### Cloud Functions
Funções ativas atuais:

#### `deleteUser`
```typescript
// Apaga dados do utilizador autenticado (scoped) sem operações destrutivas globais
// Remove user doc, wishlists + wish_items e tenta limpar imagens Cloudinary relacionadas
// (profile_<uid>, wishlist_<wishlistId>, product_<wishItemId>).
exports.deleteUser = onCall(async (request) => { /* ver código em functions/src/index.ts */ });
```

#### `secureScraper`
```typescript
// Web scraping seguro com validação de domínios
exports.secureScraper = onCall({
  region: "europe-west1", 
  cors: true
}, async (request) => {
  // Scraping com validação e rate limiting
});
```

Triggers Firestore (nível backend – não expostos diretamente no cliente):
- `wish_items` create/update/delete → atualização automática de agregados em documentos `wishlists` (`item_count`, `total_value`).

Funções administrativas destrutivas foram removidas para endurecimento de segurança (não existem endpoints de purge/audit/cleanup nesta versão).

### Firestore Database Structure

#### Collection `users`
```typescript
interface User {
  id: string;
  email?: string;
  phone_number: string;
  display_name?: string;
  bio?: string;
  avatar_url?: string;
  registration_complete: boolean;
  created_at: Timestamp;
  updated_at: Timestamp;
}
```

#### Collection `wishlists`
```typescript
interface Wishlist {
  id: string;
  user_id: string;
  name: string;
  description?: string;
  is_public: boolean;
  created_at: Timestamp;
  updated_at: Timestamp;
}
```

#### Collection `wish_items`
```typescript
interface WishItem {
  id: string;
  wishlist_id: string;
  name: string;
  description?: string;
  price?: number;
  image_url?: string;
  cloudinary_public_id?: string;
  product_url?: string;
  category?: string;
  priority: number;
  rating?: number;
  is_purchased: boolean;
  created_at: Timestamp;
  updated_at: Timestamp;
}
```
## 📱 Funcionalidades Detalhadas

### 🌍 **Sistema de Internacionalização**

#### Línguas Suportadas
- **Português (PT)**: Língua padrão
- **English (EN)**: Tradução completa

#### Implementação
```dart
// Uso de traduções
final l10n = AppLocalizations.of(context);
Text(l10n?.welcomeMessage ?? 'Bem-vindo');

// Validação internacionalizada
String? validator(String? value) {
  return ValidationUtils.validateRequired(value, l10n);
}
```

#### ARB Files Structure
```json
// app_pt.arb
{
  "welcomeMessage": "Bem-vindo ao Wishlist App",
  "addItemTitle": "Adicionar Item",
  "validationRequired": "Campo obrigatório"
}

// app_en.arb  
{
  "welcomeMessage": "Welcome to Wishlist App",
  "addItemTitle": "Add Item", 
  "validationRequired": "Required field"
}
```

### � **Sistema de Autenticação**

#### Métodos Suportados
1. **Email/Password**: Registro e login tradicional
2. **Phone/OTP**: Autenticação via SMS (Firebase Auth)
3. **Google Sign-In**: Login social integrado

#### Fluxo de Autenticação
```dart
// Firebase Auth integration
final result = await FirebaseAuthService.signInWithGoogle();
if (result.success) {
  // Navegar para dashboard
} else {
  // Mostrar erro localizado
  _showError(l10n?.authErrorMessage ?? 'Auth failed');
}
```

### 📸 **Sistema Cloudinary**

#### Funcionalidades
- **Upload Otimizado**: Imagens redimensionadas automaticamente
- **Transformações Context-Aware**: Diferentes tamanhos por contexto
- **Automatic Cleanup**: Eliminação de imagens órfãs na conta
- **Fallback System**: Suporte para imagens locais e URLs

#### Transformações Disponíveis
```dart
enum CloudinaryTransformation {
  wishlistIcon,    // 120x120, optimized for icons
  productLarge,    // 800x600, high quality for details
  productThumb,    // 300x200, fast loading for lists
}
```

#### Widget Otimizado
```dart
OptimizedCloudinaryImage(
  publicId: item.cloudinaryPublicId,
  transformation: CloudinaryTransformation.productLarge,
  fallbackUrl: item.imageUrl,
  width: 300,
  height: 200,
  borderRadius: BorderRadius.circular(12),
)
```

### 🛍️ **Web Scraping Seguro**

#### Domínios Suportados
- **Amazon** (múltiplas regiões)
- **eBay** (PT, ES, FR, UK)
- **Worten** (PT)
- **Fnac** (PT, FR)
- **PCDiga** (PT)
- E mais...

#### Processo de Scraping
```dart
// Via Firebase Cloud Function
final result = await WebScraperService().scrape(url);
if (result['success']) {
  final extractedData = result['data'];
  // Preencher campos automaticamente
  _nameController.text = extractedData['title'] ?? '';
  _priceController.text = extractedData['price'] ?? '0.00';
}
```

#### Segurança
- **Domain Validation**: Apenas domínios permitidos
- **Rate Limiting**: Proteção contra abuso
- **Server-Side Execution**: Via Firebase Cloud Functions
- **Error Handling**: Fallbacks e retry logic

### 🎨 **Sistema de Temas Material 3**

#### Temas Disponíveis
- **Light Theme**: Tema claro otimizado
- **Dark Theme**: Tema escuro com contraste adequado  
- **System Theme**: Segue configuração do sistema

#### Seleção de Tema
```dart
// Theme Service centralizado
await ThemeService.setTheme(ThemeOption.dark);

// Widget de seleção
ThemeSelectorBottomSheet(
  currentTheme: ThemeService.getCurrentTheme(),
  onThemeChanged: (theme) => ThemeService.setTheme(theme),
)
```

#### Cores Personalizadas
```dart
// Seed color consistente
const Color seedColor = Color(0xFFFF6B9D);

// Material 3 color scheme generation
final colorScheme = ColorScheme.fromSeed(
  seedColor: seedColor,
  brightness: brightness,
);
```
## 🔧 Desenvolvimento

### ✅ Métricas de Qualidade

#### Status Atual (30 Agosto 2025)
- **Flutter analyze**: ✅ **0 issues** 
- **Build stability**: ✅ Zero compilation errors
- **API compliance**: ✅ Todas as APIs deprecated atualizadas
- **Material 3**: ✅ Compliance completa
- **Context safety**: ✅ Guards implementadas
- **String standards**: ✅ Interpolation adequada

#### Estrutura de Código

#### Convenções de Nomenclatura
- **Arquivos**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variáveis**: `camelCase`
- **Constantes**: `UPPER_SNAKE_CASE`

#### Organização de Imports
```dart
// Dart imports
import 'dart:io';
import 'dart:convert';

// Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Third-party packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Local imports
import 'package:wishlist_app/config.dart';
import 'package:wishlist_app/services/firebase_auth_service.dart';
```

### Context Safety Implementation
```dart
// Sempre usar guards em operações async
Future<void> _handleAsyncOperation() async {
  final l10n = AppLocalizations.of(context); // Capture before async
  
  final result = await someAsyncOperation();
  
  if (!mounted) return; // Guard após async
  
  if (context.mounted) { // Guard antes de usar context
    Navigator.pushNamed(context, '/next-screen');
  }
}
```

### 🧪 Testes

#### Estrutura de Testes
```
test/
├── unit/
│   ├── services/
│   │   ├── firebase_auth_service_test.dart
│   │   ├── cloudinary_service_test.dart
│   │   └── validation_utils_test.dart
│   ├── models/
│   │   ├── wishlist_test.dart
│   │   └── wish_item_test.dart
│   └── utils/
├── widget/
│   ├── screens/
│   │   ├── login_screen_test.dart
│   │   └── wishlists_screen_test.dart
│   └── widgets/
│       ├── optimized_cloudinary_image_test.dart
│       └── ui_components_test.dart
└── integration/
    └── app_test.dart
```

#### Executar Testes
```bash
# Verificar qualidade primeiro
flutter analyze

# Testes unitários
flutter test

# Testes de widget
flutter test test/widget/

# Testes de integração
flutter test test/integration/
```

### � Debugging

#### Logs Estruturados
```dart
// Usar debugPrint em vez de print
debugPrint('🔍 Loading wishlists for user: $userId');

// Logs centralizados com MonitoringService
MonitoringService().trackEvent('wishlist_loaded', properties: {
  'user_id': userId,
  'items_count': items.length,
});
```

#### Performance Monitoring
```dart
// Monitorizar operações críticas
await MonitoringService().recordOperation('cloudinary_upload', () async {
  return await CloudinaryService.uploadImage(imageFile);
});
```

## 🚀 Deploy

### Preparação para Produção

#### 1. **Verificação de Qualidade**
```bash
# OBRIGATÓRIO: Verificar que não há issues
flutter analyze
# Deve retornar: "No issues found!"

# Build otimizado
flutter build apk --release

# Verificar tamanho
flutter build apk --analyze-size
```

#### 2. **Configurações de Produção**
- ✅ Flutter analyze com 0 issues
- ✅ Remover logs de debug
- ✅ Otimizar imagens via Cloudinary
- ✅ Configurar Firebase App Distribution
- ✅ Testar em dispositivos reais

#### 3. **Google Play Store**
1. Criar conta de desenvolvedor
2. Preparar assets (ícones, screenshots)
3. Configurar privacy policy
4. Submeter para revisão

### Variáveis de Ambiente

#### Desenvolvimento
```env
FIREBASE_PROJECT_ID=wishlist-dev-12345
CLOUDINARY_CLOUD_NAME=dev-cloud
DEBUG=true
```

#### Produção
```env
FIREBASE_PROJECT_ID=wishlist-prod-67890
CLOUDINARY_CLOUD_NAME=prod-cloud
DEBUG=false
```
## 📊 Monitorização e Analytics

### Métricas de Performance
- **Startup Time**: Tempo de inicialização da app
- **Image Loading**: Performance do Cloudinary
- **Firebase Operations**: Latência de operações Firestore
- **Memory Usage**: Monitorização de recursos
- **Crash Rate**: Tracking via MonitoringService

### Logs Estruturados
```dart
// Categorização de eventos
MonitoringService().trackEvent('user_action', properties: {
  'action': 'create_wishlist',
  'user_id': userId,
  'timestamp': DateTime.now().toIso8601String(),
});

// Tracking de erros
MonitoringService().trackError('cloudinary_upload_failed', {
  'error': error.toString(),
  'user_id': userId,
  'file_size': fileSize,
});
```

## 🔒 Segurança

### Medidas Implementadas
- **Context Safety**: Guards em todas operações async
- **Input Validation**: ValidationUtils centralizado e internacionalizado
- **Firebase Security Rules**: Proteção a nível de Firestore
- **Cloud Functions**: Operações sensíveis no servidor
- **Cloudinary Security**: Upload seguro com transformações

### Boas Práticas Implementadas
- ✅ Zero Flutter analyze issues (obrigatório)
- ✅ Context guards em operações async
- ✅ Validação centralizada de inputs
- ✅ APIs não-deprecated utilizadas
- ✅ String interpolation adequada
- ✅ Imports otimizados
- ✅ Material 3 compliance

## 🤝 Contribuição

### Como Contribuir
1. **Fork** o projeto
2. **Verifique** que `flutter analyze` retorna 0 issues
3. **Crie** uma branch para a feature (`git checkout -b feature/AmazingFeature`)
4. **Mantenha** qualidade técnica perfeita
5. **Commit** as mudanças (`git commit -m 'Add some AmazingFeature'`)
6. **Push** para a branch (`git push origin feature/AmazingFeature`)
7. **Abra** um Pull Request

### Padrões de Código OBRIGATÓRIOS
- **Flutter analyze**: Deve retornar 0 issues
- **Context Safety**: Guards em operações async
- **String Interpolation**: Usar `${}` em vez de concatenação `+`
- **Material 3**: Apenas APIs não-deprecated
- **Internationalization**: Usar AppLocalizations para strings UI
- **Import Organization**: Seguir convenções estabelecidas

## 🆘 Suporte

### Problemas Comuns

#### Flutter Analyze Issues
```bash
# PRIMEIRO PASSO: Sempre verificar qualidade
flutter analyze
# Se houver issues, corrigi-los antes de continuar

# Limpar cache se necessário
flutter clean
flutter pub get
```

#### Problemas de Build
```bash
# Limpar completamente
flutter clean
flutter pub get
flutter build apk --release
```

#### Erro de Firebase
1. Verificar `google-services.json` em `android/app/`
2. Confirmar Firebase project configuration
3. Verificar Cloud Functions deployment

#### Cloudinary Issues
1. Verificar credenciais no `.env`
2. Confirmar upload presets
3. Verificar transformations configuration

### 📞 Contacto
- **Issues**: [GitHub Issues](https://github.com/barnir/wishlist/issues)
- **Repository**: [GitHub Repository](https://github.com/barnir/wishlist)
- **Documentation**: [Project Wiki](https://github.com/barnir/wishlist/wiki)

## 📈 Status do Projeto

### ✅ Implementado e Estável
- 🌍 **Internacionalização completa** (PT/EN)
- 🎨 **Material 3 design system** (light/dark/system)
- 🔧 **Qualidade técnica perfeita** (0 Flutter analyze issues)
- 📸 **Cloudinary integration** otimizada
- 🔐 **Firebase authentication** multi-método
- 🛍️ **Web scraping** via Cloud Functions
- 📱 **Push notifications** implementadas

### � Próximas Funcionalidades Planejadas
1. **Sistema de Status de Items** - "Vou comprar", "Já comprei" 
2. **Sistema de Amigos** - Friend requests e social features
3. **Categorias Inteligentes** - Auto-categorization com ML
4. **Sistema de Reviews** - Rating e commenting system

## 🙏 Agradecimentos

- **Flutter Team** pelo framework incrível
- **Firebase Team** pela infraestrutura robusta  
- **Cloudinary** pela plataforma de imagens
- **Material Design** pelo sistema de design moderno
- **Comunidade Flutter** pelo suporte contínuo

---

**Desenvolvido com ❤️ e qualidade técnica perfeita para a comunidade Flutter**

> 🎯 **Objetivo**: Demonstrar que é possível construir aplicações Flutter de qualidade industrial com zero technical debt e compliance total às melhores práticas.

#### 3. **Google Play Store**
1. Criar conta de desenvolvedor
2. Preparar assets (ícones, screenshots)
3. Configurar privacy policy
4. Submeter para revisão

### Variáveis de Ambiente

#### Desenvolvimento
```env
FIREBASE_PROJECT_ID=wishlist-dev-12345
CLOUDINARY_CLOUD_NAME=dev-cloud
DEBUG=true
```

#### Produção
```env
FIREBASE_PROJECT_ID=wishlist-prod-67890
CLOUDINARY_CLOUD_NAME=prod-cloud
DEBUG=false
```

## 📊 Monitorização e Analytics

### Métricas de Performance
- **Tempo de Carregamento**: Startup e operações
- **Uso de Memória**: Monitorização de recursos
- **Taxa de Erro**: Tracking de crashes
- **Engagement**: Interações do utilizador

### Logs Estruturados
```dart
// Categorização de erros
ErrorService.logError('network_timeout', error, stackTrace);
ErrorService.logError('auth_failed', error, stackTrace);
ErrorService.logError('storage_upload_failed', error, stackTrace);
```

## 🔒 Segurança

### Medidas Implementadas
- **Validação de Input**: Sanitização de todos os dados
- **Rate Limiting**: Proteção contra abuso
- **HTTPS Only**: Comunicação encriptada
- **RLS Policies**: Segurança a nível de base de dados
- **Magic Bytes**: Validação de tipos de arquivo

### Boas Práticas
- ✅ Nunca expor chaves de API no código
- ✅ Validar todos os inputs do utilizador
- ✅ Usar HTTPS para todas as comunicações
- ✅ Implementar rate limiting
- ✅ Logs de auditoria

## 🤝 Contribuição

### Como Contribuir
1. **Fork** o projeto
2. **Crie** uma branch para a feature (`git checkout -b feature/AmazingFeature`)
3. **Commit** as mudanças (`git commit -m 'Add some AmazingFeature'`)
4. **Push** para a branch (`git push origin feature/AmazingFeature`)
5. **Abra** um Pull Request

### Padrões de Código
- Seguir as convenções de nomenclatura
- Adicionar testes para novas funcionalidades
- Documentar código complexo
- Manter a cobertura de testes > 80%

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🆘 Suporte

### Problemas Comuns

#### Erro de Autenticação
```bash
# Verificar configuração do Google Sign-In
flutter clean
flutter pub get
```

#### Problemas de Build
```bash
# Limpar cache
flutter clean
flutter pub get
flutter build apk --release
```

#### Erro de Supabase
1. Verificar URL e chave no `.env`
2. Confirmar configuração do projeto
3. Verificar políticas RLS

### Contacto
- **Email**: suporte@wishlistapp.com
- **Issues**: [GitHub Issues](https://github.com/seu-usuario/wishlist_app/issues)
- **Documentação**: [Wiki](https://github.com/seu-usuario/wishlist_app/wiki)

## 🙏 Agradecimentos

- **Flutter Team** pelo framework incrível
- **Supabase** pela infraestrutura backend
- **Material Design** pelo sistema de design
- **Comunidade Flutter** pelo suporte contínuo

---

**Desenvolvido com ❤️ para a comunidade Flutter**
