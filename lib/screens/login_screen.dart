// Clean Login Screen (removes previous corrupted tail)
import 'package:flutter/material.dart';
import 'package:mywishstash/services/auth_service.dart';
import 'package:mywishstash/services/image_prefetch_service.dart';
import 'package:mywishstash/services/rate_limiter_service.dart';
import 'package:mywishstash/utils/validation_utils.dart';
import 'package:mywishstash/widgets/skeleton_loader.dart';
import '../widgets/app_snack.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with RateLimited {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showBlockingOverlay = false; // apenas para operações internas (email), não para Google

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String m, {bool err = false}) {
    if (!mounted) return;
    AppSnack.show(context, m, type: err ? SnackType.error : SnackType.info);
  }

  Future<void> _loginEmail() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;
    final allowed = await checkRateLimit('login', _emailController.text.trim(), onBlocked: (m) => _showSnack(m, err: true));
    if (!allowed) return;
    setState(() {
      _isLoading = true;
      _showBlockingOverlay = true; // mostra overlay só para login interno
    });
    try {
      await _auth.signInWithEmailAndPassword(_emailController.text.trim(), _passwordController.text);
  await ImagePrefetchService().warmUp();
      if (!mounted) return;
  // Não navegar diretamente: o StreamBuilder em main.dart trata do routing
  // (incluindo verificação de telefone/perfil). Apenas retornamos.
    } catch (_) {
      _showSnack('Erro ao entrar', err: true);
    } finally {
      if (mounted) setState(() { _isLoading = false; _showBlockingOverlay = false; });
    }
  }

  Future<void> _loginGoogle() async {
    if (_isLoading) return;
    final allowed = await checkRateLimit('login', 'google', onBlocked: (m) => _showSnack(m, err: true));
    if (!allowed) return;
    setState(() {
      _isLoading = true;
      _showBlockingOverlay = false; // não mostrar overlay para evitar "quadrado" por trás do menu
    });
    try {
      final r = await _auth.signInWithGoogle();
      switch (r) {
        case GoogleSignInResult.success:
          await ImagePrefetchService().warmUp();
          // Sucesso: deixar o StreamBuilder em main.dart decidir próximo ecrã
          // (evita saltar passos de verificação de telefone/perfil)
          if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
          break;
        case GoogleSignInResult.missingPhoneNumber:
          if (mounted) Navigator.pushReplacementNamed(context, '/add_phone');
          break;
        case GoogleSignInResult.cancelled:
          _showSnack('Login cancelado', err: true);
          break;
        case GoogleSignInResult.failed:
          _showSnack('Erro no login Google', err: true);
          break;
      }
    } catch (_) {
      _showSnack('Erro no login Google', err: true);
    } finally {
  if (mounted) setState(() { _isLoading = false; /* _showBlockingOverlay permanece false */ });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48), // More generous padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              // Material 3 style app branding
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24), // Material 3 standard radius
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Bem-vindo de volta!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Acede à tua conta para gerir as tuas wishlists',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Material 3 outlined text field
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'email@exemplo.com',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              size: 24,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (v) => ValidationUtils.validateEmail(v, context),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              size: 24,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (v) => ValidationUtils.validatePassword(v, context),
                        ),
                        const SizedBox(height: 32),
                        // Material 3 filled button
                        FilledButton(
                          onPressed: _isLoading ? null : _loginEmail,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56), // Material 3 standard height
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  'Entrar com Email',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 24),
                        // Material 3 divider
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: theme.colorScheme.outlineVariant,
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'ou',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: theme.colorScheme.outlineVariant,
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Material 3 outlined button for Google
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _loginGoogle,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            side: BorderSide(
                              color: theme.colorScheme.outline,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: theme.colorScheme.surface,
                            foregroundColor: theme.colorScheme.onSurface,
                          ),
                          icon: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              'assets/images/google_logo.png',
                              width: 24,
                              height: 24,
                              errorBuilder: (c, e, s) => Icon(
                                Icons.g_mobiledata,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                          ),
                          label: Text(
                            'Continuar com Google',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Não tens conta? ',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            GestureDetector(
                              onTap: _isLoading ? null : () => Navigator.pushNamed(context, '/register'),
                              child: Text(
                                'Regista-te',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  if (_showBlockingOverlay && _isLoading)
                    Positioned.fill(
                      child: Container(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                        child: const Center(
                          child: SizedBox(
                            width: 120,
                            height: 120,
                            child: SkeletonLoader(itemCount: 1),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
