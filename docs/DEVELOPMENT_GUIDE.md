# 🛠️ Guia de Desenvolvimento - Wishlist App

## 🎯 Introdução

Guia para programadores que querem contribuir para o projeto Wishlist App.

## 📋 Pré-requisitos

- **Flutter SDK**: ^3.8.1
- **Dart**: ^3.8.1
- **IDE**: Android Studio ou VS Code
- **Git**: Para controlo de versões
- **Supabase CLI**: Para Edge Functions

## 🚀 Configuração

### 1. **Instalar Flutter**
```bash
flutter doctor
```

### 2. **Setup do Projeto**
```bash
git clone https://github.com/seu-usuario/wishlist_app.git
cd wishlist_app
flutter pub get
```

### 3. **Configurar Supabase**
```bash
npm install -g supabase
supabase login
supabase link --project-ref seu-project-ref
```

## 📁 Estrutura do Projeto

```
lib/
├── config.dart                 # Configurações globais
├── main.dart                   # Ponto de entrada
├── theme.dart                  # Temas e estilos
├── models/                     # Modelos de dados
├── screens/                    # Telas da aplicação
├── services/                   # Serviços e lógica
└── widgets/                    # Widgets reutilizáveis
```

## 🔧 Convenções de Código

### Nomenclatura
- **Arquivos**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variáveis**: `camelCase`
- **Constantes**: `UPPER_SNAKE_CASE`

### Imports
```dart
// 1. Dart imports
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:supabase_flutter/supabase_flutter.dart';

// 4. Local imports
import 'package:wishlist_app/config.dart';
```

## 🎨 UI/UX Guidelines

### Material 3 Design
```dart
// Usar sempre o tema
Theme.of(context).colorScheme.primary
Theme.of(context).textTheme.headlineMedium
```

### Widgets Reutilizáveis
```dart
// ✅ Correto
WishlistAppBar(title: "Minhas Wishlists")
WishlistButton(text: "Adicionar", onPressed: _addItem)
WishlistTextField(label: "Nome")
```

## 🔐 Segurança

### Validação de Input
```dart
String? validateEmail(String? email) {
  if (email == null || email.isEmpty) {
    return 'Email é obrigatório';
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
    return 'Email inválido';
  }
  return null;
}
```

### Tratamento de Erros
```dart
try {
  await authService.signIn(email, password);
} catch (e) {
  ErrorService.logError('auth_failed', e, StackTrace.current);
}
```

## 📊 Performance

### Lazy Loading
```dart
// ✅ Correto
LazyImage(
  imageUrl: item.imageUrl,
  placeholder: SkeletonCard(),
)

ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => WishlistItemTile(item: items[index]),
)
```

### Cache
```dart
final cachedData = await CacheService.getString('wishlists');
if (cachedData != null) {
  return Wishlist.fromJson(jsonDecode(cachedData));
}
```

## 🧪 Testes

### Estrutura
```
test/
├── unit/                       # Testes unitários
├── widget/                     # Testes de widget
└── integration/                # Testes de integração
```

### Exemplo de Teste
```dart
void main() {
  group('AuthService', () {
    test('should validate email format', () {
      expect(authService.isValidEmail('test@example.com'), true);
      expect(authService.isValidEmail('invalid-email'), false);
    });
  });
}
```

### Executar Testes
```bash
flutter test
flutter test --coverage
```

## 🔄 Git Workflow

### Branches
- `main`: Código de produção
- `develop`: Código de desenvolvimento
- `feature/*`: Novas funcionalidades
- `bugfix/*`: Correções de bugs

### Commits
```bash
git commit -m "feat: add user profile screen"
git commit -m "fix: resolve OTP validation issue"
git commit -m "docs: update API documentation"
```

## 🚀 Deploy

### Build de Produção
```bash
flutter build appbundle --release
flutter build apk --analyze-size
```

### Google Play Store
1. Preparar assets (ícone, screenshots)
2. Build final com `flutter build appbundle --release`
3. Upload no Google Play Console
4. Submeter para revisão

## 🐛 Debugging

### Logs
```dart
debugPrint('Loading wishlists for user: $userId');
ErrorService.logError('network_timeout', error, stackTrace);
```

### Performance
```dart
PerformanceService.recordOperation('load_wishlists', () async {
  // Operação a monitorizar
});
```

### Problemas Comuns
```bash
# Limpar cache
flutter clean
flutter pub get

# Verificar dependências
flutter doctor
```

## 📚 Recursos

- [Flutter Documentation](https://flutter.dev/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [Material Design](https://material.io/design)

---

**Versão**: 1.0.0
