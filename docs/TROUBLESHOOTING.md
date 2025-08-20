# 🔧 Guia de Troubleshooting - Wishlist App

## 🚨 Problemas Comuns e Soluções

### 🔐 Autenticação

#### **Problema**: Erro no Google Sign-In
```
Error: The class 'GoogleSignIn' doesn't have an unnamed constructor
```

**Solução**:
```bash
# Verificar versão do google_sign_in
flutter pub deps | grep google_sign_in

# Atualizar para versão compatível
flutter pub add google_sign_in:^6.2.1
flutter pub get
```

#### **Problema**: OTP não chega via SMS
```
Error: Failed to send OTP
```

**Soluções**:
1. **Verificar número de telefone**:
   ```dart
   // Formato correto: +351912345678
   final phoneNumber = '+351912345678';
   ```

2. **Verificar configuração Supabase**:
   - Aceder ao Supabase Dashboard
   - Verificar configuração de SMS
   - Confirmar créditos disponíveis

3. **Testar com número diferente**:
   ```dart
   // Usar número de teste
   final testPhone = '+1234567890';
   ```

#### **Problema**: Login com email falha
```
Error: Invalid login credentials
```

**Soluções**:
1. **Verificar formato do email**:
   ```dart
   // Formato correto
   final email = 'user@example.com';
   ```

2. **Verificar password**:
   - Mínimo 6 caracteres
   - Pelo menos uma letra maiúscula
   - Pelo menos um número
   - Pelo menos um símbolo

3. **Reset de password**:
   ```dart
   await _supabaseClient.auth.resetPasswordForEmail(email);
   ```

### 📊 Base de Dados

#### **Problema**: Erro de conexão com Supabase
```
Error: Connection failed
```

**Soluções**:
1. **Verificar configuração**:
   ```dart
   // lib/config.dart
   static const String supabaseUrl = 'https://seu-projeto.supabase.co';
   static const String supabaseAnonKey = 'sua-chave-anonima';
   ```

2. **Verificar internet**:
   ```dart
   // Testar conectividade
   final connectivityResult = await Connectivity().checkConnectivity();
   if (connectivityResult == ConnectivityResult.none) {
     // Sem internet
   }
   ```

3. **Verificar projeto Supabase**:
   - Aceder ao Dashboard
   - Verificar se o projeto está ativo
   - Confirmar URL e chave

#### **Problema**: Erro de permissão RLS
```
Error: new row violates row-level security policy
```

**Soluções**:
1. **Verificar políticas RLS**:
   ```sql
   -- Verificar políticas existentes
   SELECT * FROM pg_policies WHERE tablename = 'users';
   ```

2. **Verificar autenticação**:
   ```dart
   final user = _supabaseClient.auth.currentUser;
   if (user == null) {
     // Utilizador não autenticado
   }
   ```

3. **Recriar políticas**:
   ```sql
   -- Política para users
   CREATE POLICY "Users can view their own profile" ON users
     FOR SELECT USING (auth.uid() = id);
   ```

### 📸 Storage

#### **Problema**: Upload de imagem falha
```
Error: File too large
```

**Soluções**:
1. **Verificar tamanho do arquivo**:
   ```dart
   final fileSize = await imageFile.length();
   if (fileSize > 5 * 1024 * 1024) { // 5MB
     // Arquivo muito grande
   }
   ```

2. **Comprimir imagem**:
   ```dart
   final compressedImage = await FlutterImageCompress.compressWithFile(
     imageFile.path,
     quality: 85,
   );
   ```

3. **Verificar tipo de arquivo**:
   ```dart
   final mimeType = lookupMimeType(imageFile.path);
   final allowedTypes = ['image/jpeg', 'image/png', 'image/webp'];
   if (!allowedTypes.contains(mimeType)) {
     // Tipo não permitido
   }
   ```

#### **Problema**: Imagem não carrega
```
Error: Failed to load image
```

**Soluções**:
1. **Verificar URL**:
   ```dart
   if (imageUrl.isEmpty || !Uri.parse(imageUrl).isAbsolute) {
     // URL inválida
   }
   ```

2. **Usar LazyImage**:
   ```dart
   LazyImage(
     imageUrl: imageUrl,
     placeholder: SkeletonCard(),
     errorWidget: Icon(Icons.error),
   )
   ```

3. **Verificar cache**:
   ```dart
   await CacheService.remove('image_$imageUrl');
   ```

### 🛍️ Web Scraping

#### **Problema**: Scraping não funciona
```
Error: Domain not allowed
```

**Soluções**:
1. **Verificar domínio**:
   ```dart
   final allowedDomains = [
     'amazon.pt', 'amazon.com',
     'ebay.pt', 'ebay.com',
     // ... outros domínios
   ];
   ```

2. **Usar Edge Function**:
   ```dart
   final result = await _supabaseClient.functions.invoke(
     'secure-scraper',
     body: {'url': url},
   );
   ```

3. **Fallback para ScraperAPI**:
   ```dart
   if (Config.scraperApiKey.isNotEmpty) {
     // Usar ScraperAPI como fallback
   }
   ```

#### **Problema**: Rate limiting
```
Error: Too many requests
```

**Soluções**:
1. **Verificar limites**:
   ```dart
   // Limites configurados
   // Scraping: 5 requests/user, 10 requests/IP por 2 minutos
   // Upload: 3 requests/user, 5 requests/IP por 5 minutos
   ```

2. **Implementar retry com backoff**:
   ```dart
   Future<T> retryWithBackoff<T>(
     Future<T> Function() operation, {
     int maxRetries = 3,
   }) async {
     for (int i = 0; i < maxRetries; i++) {
       try {
         return await operation();
       } catch (e) {
         if (i == maxRetries - 1) rethrow;
         await Future.delayed(Duration(seconds: pow(2, i)));
       }
     }
   }
   ```

### 🎨 UI/UX

#### **Problema**: App crash ao abrir
```
Error: Flutter app crashes on startup
```

**Soluções**:
1. **Verificar dependências**:
   ```bash
   flutter clean
   flutter pub get
   flutter pub outdated
   ```

2. **Verificar configuração**:
   ```dart
   // lib/main.dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     await Supabase.initialize(
       url: Config.supabaseUrl,
       anonKey: Config.supabaseAnonKey,
     );
     
     runApp(MyApp());
   }
   ```

3. **Verificar logs**:
   ```bash
   flutter run --verbose
   ```

#### **Problema**: Performance lenta
```
App is slow and unresponsive
```

**Soluções**:
1. **Usar lazy loading**:
   ```dart
   ListView.builder(
     itemCount: items.length,
     itemBuilder: (context, index) => WishlistItemTile(
       item: items[index],
     ),
   )
   ```

2. **Implementar cache**:
   ```dart
   final cachedData = await CacheService.getString('wishlists');
   if (cachedData != null) {
     return Wishlist.fromJson(jsonDecode(cachedData));
   }
   ```

3. **Otimizar imagens**:
   ```dart
   LazyImage(
     imageUrl: imageUrl,
     placeholder: SkeletonCard(),
     memCacheWidth: 300, // Limitar largura
   )
   ```

### 🔧 Build e Deploy

#### **Problema**: Build falha
```
Error: Build failed
```

**Soluções**:
1. **Limpar cache**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Verificar versões**:
   ```bash
   flutter doctor
   flutter --version
   ```

3. **Verificar dependências**:
   ```bash
   flutter pub deps
   flutter pub outdated
   ```

#### **Problema**: APK muito grande
```
APK size is too large
```

**Soluções**:
1. **Analisar tamanho**:
   ```bash
   flutter build apk --analyze-size
   ```

2. **Otimizar imagens**:
   - Comprimir imagens
   - Usar formatos otimizados (WebP)
   - Remover imagens não utilizadas

3. **Configurar ProGuard**:
   ```gradle
   // android/app/build.gradle
   android {
     buildTypes {
       release {
         minifyEnabled true
         shrinkResources true
         proguardFiles getDefaultProguardFile('proguard-android.txt')
       }
     }
   }
   ```

### 📱 Android Específico

#### **Problema**: Permissões não funcionam
```
Error: Permission denied
```

**Soluções**:
1. **Verificar AndroidManifest.xml**:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   ```

2. **Solicitar permissões em runtime**:
   ```dart
   final status = await Permission.camera.request();
   if (status.isGranted) {
     // Permissão concedida
   }
   ```

#### **Problema**: App não instala
```
Error: App not installed
```

**Soluções**:
1. **Desinstalar versão anterior**:
   ```bash
   adb uninstall com.example.wishlist_app
   ```

2. **Verificar assinatura**:
   ```bash
   flutter build apk --release
   ```

3. **Verificar compatibilidade**:
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <uses-sdk android:minSdkVersion="21" android:targetSdkVersion="33" />
   ```

### 🔍 Debugging Avançado

#### **Logs Estruturados**
```dart
// Sempre usar debugPrint
debugPrint('Loading wishlists for user: $userId');

// Logs de erro centralizados
ErrorService.logError('auth_failed', error, stackTrace);

// Performance monitoring
PerformanceService.recordOperation('load_wishlists', () async {
  // Operação a monitorizar
});
```

#### **Ferramentas de Debug**
```bash
# Flutter Inspector
flutter run --debug
# Pressionar 'i' no terminal

# Performance profiling
flutter run --profile

# Memory analysis
flutter run --trace-startup
```

#### **Supabase Debug**
```bash
# Verificar logs
supabase logs

# Verificar status
supabase status

# Reset local
supabase db reset
```

## 📞 Suporte

### Contactos
- **Email**: suporte@wishlistapp.com
- **Issues**: [GitHub Issues](https://github.com/seu-usuario/wishlist_app/issues)
- **Documentação**: [Wiki](https://github.com/seu-usuario/wishlist_app/wiki)

### Informações Úteis
- **Versão**: 1.0.0
- **Flutter**: ^3.8.1
- **Supabase**: ^2.9.1
- **Plataforma**: Android

---

**Última atualização**: Janeiro 2025
