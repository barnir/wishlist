# 🤝 Contributing to Wishlist App

Obrigado pelo seu interesse em contribuir para a Wishlist App! Este documento contém as guidelines e processes para contribuir efetivamente para o projeto.

---

## 📋 Índice

- [Code of Conduct](#-code-of-conduct)
- [Getting Started](#-getting-started)
- [Development Workflow](#-development-workflow)
- [Coding Standards](#-coding-standards)
- [Pull Request Process](#-pull-request-process)
- [Issue Reporting](#-issue-reporting)
- [Testing Guidelines](#-testing-guidelines)

---

## 🛡️ Code of Conduct

Este projeto segue um código de conduta baseado no respeito mútuo:

- **Seja respeitoso** em todas as interações
- **Seja construtivo** nas críticas e feedback
- **Seja colaborativo** e ajude outros contribuidores
- **Seja inclusivo** e bem-vindo a todos os níveis de experiência

---

## 🚀 Getting Started

### Pré-requisitos

Antes de começar, certifique-se de ter:

```bash
# Verificar versões necessárias
flutter --version    # 3.35.1+
dart --version       # 3.4+
node --version       # Para Firebase Functions
npm --version
```

### Setup do Ambiente de Desenvolvimento

1. **Fork e Clone**
```bash
git clone https://github.com/[seu-username]/wishlist_app.git
cd wishlist_app
```

2. **Configure o ambiente**
```bash
# Instalar dependências Flutter
flutter pub get

# Instalar dependências Functions
cd functions && npm install && cd ..

# Configurar ambiente
cp .env.example .env
# Configure suas chaves API no .env
```

3. **Verificar setup**
```bash
flutter analyze           # Deve mostrar "No issues found!"
flutter test             # Executar testes
flutter run              # Testar app
```

---

## 🔄 Development Workflow

### Branch Strategy

Usamos [Git Flow](https://git-flow.readthedocs.io/en/latest/):

```bash
main/              # Produção - apenas releases
develop/           # Desenvolvimento principal
feature/[name]     # Novas funcionalidades
hotfix/[name]      # Correções urgentes
release/[version]  # Preparação de releases
```

### Workflow Típico

1. **Crie uma branch a partir de develop**
```bash
git checkout develop
git pull origin develop
git checkout -b feature/minha-nova-feature
```

2. **Desenvolva seguindo os padrões**
```bash
# Faça commits frequentes e descritivos
git add .
git commit -m "feat: adiciona nova funcionalidade X"
```

3. **Mantenha sua branch atualizada**
```bash
git fetch origin
git rebase origin/develop
```

4. **Execute testes antes de push**
```bash
flutter analyze      # Zero issues obrigatório
flutter test        # Todos os testes devem passar
flutter build apk   # Build deve ser bem-sucedido
```

---

## 🎯 Coding Standards

### Flutter/Dart Guidelines

Seguimos as [Dart Style Guidelines](https://dart.dev/guides/language/effective-dart) oficiais:

#### **Naming Conventions**
```dart
// Classes: PascalCase
class WishlistService {}

// Variables/functions: camelCase  
String userName = 'João';
void saveUserData() {}

// Constants: lowerCamelCase
const apiTimeout = Duration(seconds: 30);

// Files: snake_case
wish_item_model.dart
auth_service.dart
```

#### **Code Organization**
```dart
// 1. Imports
import 'package:flutter/material.dart';
import 'package:mywishstash/services/auth_service.dart';

// 2. Class declaration
class MyWidget extends StatefulWidget {
  // 3. Properties
  final String title;
  
  // 4. Constructor
  const MyWidget({super.key, required this.title});
  
  // 5. Override methods
  @override
  State<MyWidget> createState() => _MyWidgetState();
}
```

#### **Performance Guidelines**
```dart
// ✅ Use performance optimizations
class MyScreen extends StatefulWidget with PerformanceOptimizedState {
  // Use safeSetState() instead of setState()
  void updateState() {
    safeSetState(() {
      // state changes
    });
  }
}

// ✅ Use const constructors when possible
const MyWidget({super.key});

// ✅ Use memoized widgets for expensive widgets
MemoizedOptimizedImage(url: imageUrl)

// ✅ Use proper animation durations
AnimationController(
  duration: PerformanceUtils.normalAnimation, // 250ms
  vsync: this,
)
```

### Architecture Patterns

#### **Service Layer**
```dart
// Singleton services
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
}

// Repository pattern
abstract class WishlistRepository {
  Future<List<Wishlist>> getWishlists();
  Future<void> createWishlist(Wishlist wishlist);
}
```

#### **Widget Structure**
```dart
// Screens focam na UI, services na lógica
class WishlistScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI only - delegate business logic to services
    );
  }
  
  void _onSave() async {
    // Delegate to service
    await WishlistService().saveWishlist(data);
  }
}
```

---

## 🔍 Pull Request Process

### Before Submitting

**Checklist obrigatório:**

- [ ] `flutter analyze` retorna zero issues
- [ ] `flutter test` todos os testes passam
- [ ] `flutter build apk` build bem-sucedido
- [ ] Código segue os padrões estabelecidos
- [ ] Documentação atualizada se necessário
- [ ] Commit messages seguem convenção

### PR Template

Use este template para PRs:

```markdown
## 📝 Descrição
Breve descrição das mudanças

## 🎯 Tipo de Mudança
- [ ] Bug fix (non-breaking change que corrige um issue)
- [ ] New feature (non-breaking change que adiciona funcionalidade)
- [ ] Breaking change (mudança que quebra funcionalidade existente)
- [ ] Documentation update

## 🧪 Como Testar
1. Passos para reproduzir
2. Comportamento esperado
3. Screenshots se aplicável

## ✅ Checklist
- [ ] Flutter analyze: 0 issues
- [ ] Todos os testes passam
- [ ] Build APK bem-sucedido
- [ ] Documentação atualizada
- [ ] Self-review realizado
```

### Review Process

1. **Automated Checks**: CI/CD verifica analyze, testes e build
2. **Code Review**: Pelo menos 1 reviewer aprovação
3. **Testing**: Manual testing em device real
4. **Merge**: Squash and merge para develop

---

## 🐛 Issue Reporting

### Bug Reports

Use este template para bugs:

```markdown
**Descreva o bug**
Uma descrição clara do que está errado.

**Para Reproduzir**
Passos para reproduzir:
1. Vá para '...'
2. Clique em '....'
3. Veja o erro

**Comportamento Esperado**
O que deveria acontecer.

**Screenshots**
Se aplicável, adicione screenshots.

**Ambiente (por favor complete):**
- Device: [e.g. Pixel 6]
- OS: [e.g. Android 13]
- App Version: [e.g. 1.2.3]
- Flutter Version: [e.g. 3.35.1]
```

### Feature Requests

```markdown
**A funcionalidade está relacionada a um problema?**
Descrição do problema que motiva a feature.

**Descreva a solução desejada**
Descrição clara da funcionalidade desejada.

**Descreva alternativas consideradas**
Outras abordagens que você considerou.

**Contexto adicional**
Screenshots, mockups, ou outros contextos.
```

---

## 🧪 Testing Guidelines

### Test Structure

```dart
// Organize testes por categoria
test/
├── models/           # Unit tests para modelos
├── services/         # Unit tests para serviços  
├── widgets/         # Widget tests
└── integration/     # Integration tests
```

### Writing Tests

```dart
// Unit test example
void main() {
  group('WishItem Model', () {
    test('should create WishItem from map', () {
      // Arrange
      final map = {'name': 'Test Item', 'price': 10.0};
      
      // Act
      final item = WishItem.fromMap(map);
      
      // Assert
      expect(item.name, equals('Test Item'));
      expect(item.price, equals(10.0));
    });
  });
}

// Widget test example
void main() {
  testWidgets('MyWidget displays correct title', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyWidget(title: 'Test Title'),
      ),
    );
    
    expect(find.text('Test Title'), findsOneWidget);
  });
}
```

### Running Tests

```bash
# Todos os testes
flutter test

# Específicos
flutter test test/models/
flutter test test/widgets/my_widget_test.dart

# Com coverage
flutter test --coverage
```

---

## 📚 Documentation

### Code Documentation

```dart
/// Serviço responsável pela autenticação de utilizadores.
/// 
/// Providencia métodos para login, logout, registo e gestão
/// de estados de autenticação através do Firebase Auth.
class AuthService {
  /// Autentica utilizador com email e password.
  /// 
  /// Retorna [User] se bem-sucedido, null se falhar.
  /// Throws [AuthException] se credenciais inválidas.
  Future<User?> signInWithEmail(String email, String password) async {
    // implementation
  }
}
```

### README Updates

Quando adicionar funcionalidades principais:
- Atualize a seção de funcionalidades
- Adicione comandos relevantes
- Inclua screenshots se necessário

---

## 🏆 Recognition

Contribuidores são reconhecidos através de:

- Menção nos release notes
- Listagem em contributors do projeto
- Badge special contributors (após 5+ PRs)

---

## 💬 Precisa de Ajuda?

- **Issues**: Para bugs e feature requests
- **Discussions**: Para questões gerais e ideias
- **Documentation**: Consulte [docs/](docs/) para guias técnicos

---

**Obrigado por contribuir! 🙏**

Cada contribuição ajuda a tornar a Wishlist App melhor para todos os utilizadores.
