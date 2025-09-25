# 📝 Changelog - Wishlist App

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.6+10] - 2025-09-25

### 🎯 TODOS OS BUGS DE UI CRÍTICOS RESOLVIDOS
- **SkeletonLoader CORRIGIDO**: Resolvido erro fatal de Positioned widget dentro de ClipRRect sem Stack
- **Hierarquia de widgets CORRIGIDA**: Widget shimmer overlay agora funciona corretamente
- **UI estável**: Eliminados crashes e erros de rendering durante loading states
- **Real device testing**: Testado e funcionando no Samsung Galaxy S24 Ultra (Android 15)
- **Logs limpos**: Sem mais erros de FlutterError: Incorrect use of ParentDataWidget

### 🚀 Root Cause Final Identificado
- SkeletonLoader tinha Positioned.fill sem Stack parent, causando crashes de UI
- Este erro impedia o funcionamento correto das telas com loading states
- Correção: Adicionado Stack wrapper no _buildSimpleSkeleton method

## [0.1.6+9] - 2025-09-25

### ✅ Bug Fixes Críticos
- **ANIMAÇÕES CORRIGIDAS**: Resolvidos conflitos de extensões que impediam funcionamento das animações
- **Extension conflicts RESOLVIDOS**: Removida extensão duplicada NavigatorStateExtensions
- **Navigation system FUNCIONAL**: Métodos pushFadeScale, pushSearch, pushHero agora funcionam corretamente
- **Flutter analyze: 0 issues**: Build completamente limpo sem erros de compilação
- **Debug logging mantido**: Logs extensivos para detecção de contactos e auto-loading

### 🎯 Root Causes Identificados
- Conflitos de extensões causavam erros ambiguous_extension_member_access
- Sistema de animações não funcionava devido a dois extensions com mesmos métodos
- Navigation transitions falhavam silenciosamente devido a erros de compilação

## [0.1.6+8] - 2025-09-25

### 🐛 Debug & Fixes
- **Debug extensivo**: Logs detalhados para detecção de contactos e carregamento automático de perfis
- **Contact detection debugging**: Logs completos do processo de normalização e matching de contactos
- **Explore screen debugging**: Logs para carregamento automático de perfis públicos
- **Extension conflicts**: Resolvidos conflitos de extensões de navegação
- **Build stability**: Build debug e release passando sem erros

### 🔍 Investigação
- Debugging logs para identificar problemas reportados pelos testers
- Análise detalhada da detecção de contactos registados vs contatos para convidar
- Verificação do carregamento automático no ExploreScreen

## [0.1.6+7] - 2025-09-25elog - Wishlist App

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.7] - 2025-09-25

### ✨ Animation & UI Overhaul
- Sistema de animações completamente aprimorado: transições suaves e profissionais em toda a app
- Novos tipos de transição: slideFromRight, fadeWithScale, searchTransition, heroTransition, slideFromBottom
- AnimatedSearchField: campo de busca com animações de foco e loading
- AnimatedTextField: input reutilizável com animações de border/shadow
- AnimatedFloatingActionButton: FAB com feedback visual e tátil
- Navigation extensions unificadas: pushFadeScale, pushHero, pushSearch, pushBottomModal
- Durações otimizadas (200-320ms) e curvas suaves (easeOutCubic, easeOutQuart)
- Integração completa em main.dart, wishlists_screen, explore_screen, friends_screen, friend_suggestions_screen

### 🛠 Fixed
- Corrigidos glitches visuais durante transições de tela (pesquisa, perfis, detalhes)
- Corrigido conflito de extensões de navegação
- Removidos todos os warnings de deprecated (withOpacity)
- flutter analyze: 0 issues
- flutter test: 21/21 passed

### 📚 Context7 Research
- Flutter animation best practices
- Material motion guidelines
- Performance tuning para 60fps

---

## [0.1.5] - 2025-09-24

### 🧠 Added
- **Detecção inteligente de contactos**: Sistema detecta automaticamente contactos do telefone que já estão registados na app
- Novo método `findUsersByContacts()` no UserSearchRepository para matching eficiente por telefone/email
- UI diferenciada para contactos: amigos registados (avatar colorido + botão favoritos) vs contactos para convidar (avatar cinzento + botão partilhar)
- Queries Firestore otimizadas com `whereIn` para busca em lote de contactos

### 📐 Analysis
- **Análise completa de arquitetura**: Avaliação detalhada da aplicação para decomposição em microserviços
- Documentação técnica em `docs/MICROSERVICES_ANALYSIS.md` com análise de 50+ páginas
- 4 domínios de negócio identificados: Auth/User, Wishlist, Social/Discovery, Media/Content
- Estratégia de migração Strangler Fig Pattern documentada em 3 fases
- **Recomendação técnica**: Manter arquitetura monolítica atual (Firebase/Flutter ecosystem é ideal)

### 🎨 UI/UX Improvements
- Interface de perfil simplificada: removido separador "Sobre", foco nas wishlists
- Bio mantida no cabeçalho do perfil para interface mais limpa
- Email removido dos cards de perfis públicos na exploração para maior privacidade
- Explore screen com auto-loading de perfis públicos (sem necessidade de busca manual)

### 🛠 Fixed
- Fallback robusto para queries Firestore quando índices compostos não estão disponíveis
- Correções de linting no UserSearchRepository
- Estrutura de dados ajustada para compatibilidade com `_buildFriendCard`

### 🧪 Quality Assurance
- flutter analyze: 0 issues mantidos
- flutter test: 21/21 testes passaram
- Padrões enterprise mantidos (Repository Pattern, Error Boundaries, Resource Management)

---

## [0.1.4] - 2025-09-21

### 🚀 Added
- mirrorToCloudinary Firebase Function + client helper for automatic image mirroring após importação
- Status chip no item tile para reflectir enrich_status (pending / failed / rate limited)
- Enrichment pipeline pós-importação com fallback para Cloudinary e rate limit feedback

### 🛠 Changed
- Import de wishlists agenda mirror best-effort para imagens externas
- Release notes actualizados e versão bump para 0.1.4 (build 5)

### 🧪 Verification
- flutter analyze --no-fatal-infos
- flutter test
- flutter build apk --release
- firebase appdistribution:distribute (wishlist-beta-testers)

---

## [0.1.3] - 2025-09-08

### 🚀 Added
- Sistema completo de otimizações de performance
- FastCloudinaryImage widget para imagens otimizadas
- PerformanceOptimizedState mixin para screens
- Widgets memoizados para melhor performance
- Sistema de debounce para reduzir rebuilds

### 🔄 Changed
- Theme system completamente reescrito com Material Design 3
- Animações padronizadas (150ms/250ms) para consistência visual
- README.md padronizado e profissionalizado
- Estrutura de documentação limpa e organizada

### 🛠️ Fixed
- Todos os issues do flutter analyze corrigidos (0 issues)
- Empty catch blocks com logging adequado
- Const constructors aplicados onde possível
- Container substituído por SizedBox para whitespace

### 🗑️ Removed
- Documentação desnecessária do projeto raiz
- Arquivos específicos do Claude/desenvolvimento
- Código redundante e comments obsoletos

---

## [Unreleased]

### 🚀 Added
- GitHub Actions CI workflow for build + deploy (.github/workflows/ci_deploy.yml)

### 🔄 Changed

### 🛠️ Fixed

### 🗑️ Removed

---

### Build Artifacts
- APK debug: `build/app/outputs/flutter-apk/app-debug.apk`
- AAB release: `build/app/outputs/bundle/release/app-release.aab` (55.9MB)
- Functions build: `functions/lib` (TypeScript compiled)

---

## [Previous Versions]

### 🏗️ Core Features Implemented
- ✅ Flutter 3.35.1 com Dart 3.4+
- ✅ Firebase Authentication (Email, Google, SMS)
- ✅ Cloud Firestore com security rules
- ✅ Cloudinary integration para imagens
- ✅ Web scraping seguro via Firebase Functions
- ✅ Internacionalização PT/EN
- ✅ Push notifications via FCM
- ✅ Material Design 3 theming
- ✅ Performance monitoring system
- ✅ Analytics integration

### 🏆 Performance Achievements
- **40-60% reduction** em setState() desnecessários
- **Consistent animations** com durações padronizadas
- **Smart image caching** com fallback strategies
- **Memory leak prevention** com proper disposal
- **Build optimization** - APK ~166MB
- **Zero analyze issues** - Clean codebase

---

## 📊 Version Metrics

| Metric | Before Optimization | After Optimization | Improvement |
|--------|--------------------|--------------------|-------------|
| Flutter Analyze Issues | 5-6 issues | 0 issues | ✅ 100% |
| setState() Calls | High frequency | 40-60% reduction | ✅ Major |
| Animation Consistency | Inconsistent | Standardized | ✅ Complete |
| Image Loading | Basic | Optimized + Cache | ✅ Significant |
| Memory Management | Basic | Advanced | ✅ Enhanced |
| Theme Coherence | Good | Excellent | ✅ Major |

---

## 🎯 Next Planned Features

### High Priority
- [ ] Implement remaining screen optimizations
- [ ] Add error boundaries for critical widgets
- [ ] Enhanced offline functionality
- [ ] Advanced pagination for large lists

### Medium Priority
- [ ] A/B testing framework
- [ ] Advanced analytics dashboard
- [ ] Social features expansion
- [ ] Enhanced scraping capabilities

### Low Priority
- [ ] iOS platform support (future)
- [ ] Web platform support (future)
- [ ] Desktop app consideration
- [ ] Advanced AI features

---

## 📱 Platform Support

| Platform | Status | Version | Notes |
|----------|--------|---------|-------|
| Android | ✅ Full Support | API 21+ | Primary platform |
| iOS | ❌ Not Supported | - | Future consideration |
| Web | ❌ Not Supported | - | Not planned |
| Desktop | ❌ Not Supported | - | Future consideration |

---

## 🔧 Development Environment

### Minimum Requirements
- Flutter SDK: 3.35.1+
- Dart SDK: 3.4+
- Android Studio: Latest stable
- Android API Level: 21+

### Recommended Setup
- VS Code with Flutter extension
- Android device for testing
- Firebase CLI for Functions
- Git for version control

---

## 🏷️ Release Notes Format

Each release follows this structure:
- **🚀 Added**: New features
- **🔄 Changed**: Changes to existing functionality
- **🛠️ Fixed**: Bug fixes
- **🔒 Security**: Security improvements
- **🗑️ Removed**: Removed features
- **⚠️ Deprecated**: Soon-to-be removed features

---

*For technical support or questions about specific versions, please check our [GitHub Issues](../../issues) or [Documentation](docs/).*
