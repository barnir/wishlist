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
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithEmailAndPassword(_emailController.text.trim(), _passwordController.text);
  await ImagePrefetchService().warmUp();
      if (!mounted) return;
  // Não navegar diretamente: o StreamBuilder em main.dart trata do routing
  // (incluindo verificação de telefone/perfil). Apenas retornamos.
    } catch (_) {
      _showSnack('Erro ao entrar', err: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginGoogle() async {
    if (_isLoading) return;
    final allowed = await checkRateLimit('login', 'google', onBlocked: (m) => _showSnack(m, err: true));
    if (!allowed) return;
    setState(() => _isLoading = true);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: theme.colorScheme.onPrimary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Bem-vindo de volta!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Acede à tua conta para gerir as tuas wishlists',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _emailController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'email@exemplo.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) => ValidationUtils.validateEmail(v, context),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_isLoading,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: '********',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) => ValidationUtils.validatePassword(v, context),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _isLoading ? null : _loginEmail,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Entrar com Email',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Divider(color: theme.colorScheme.outline)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('ou'),
                            ),
                            Expanded(child: Divider(color: theme.colorScheme.outline)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _loginGoogle,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              'assets/images/google_logo.png',
                              width: 20,
                              height: 20,
                              errorBuilder: (c, e, s) => Icon(Icons.g_mobiledata, color: theme.colorScheme.primary),
                            ),
                          ),
                          label: Text(
                            'Continuar com Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
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
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        color: theme.colorScheme.surface.withOpacity(0.6),
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
