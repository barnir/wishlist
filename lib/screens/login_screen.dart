import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/firebase_database_service.dart';
import 'package:wishlist_app/services/rate_limiter_service.dart';
import 'package:wishlist_app/utils/validation_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with RateLimited {
  final _authService = AuthService();
  final _databaseService = FirebaseDatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loginComEmail() async {
    if (_formKey.currentState!.validate()) {
      // Rate limiting check
      final email = _emailController.text.trim();
      final canProceed = await checkRateLimit('login', email, onBlocked: (message) {
        _showSnackBar(message, isError: true);
      });
      
      if (!canProceed) return;

      setState(() {
        _isLoading = true;
      });
      try {
        await _authService.signInWithEmailAndPassword(
          email,
          _passwordController.text.trim(),
        );

        // After email login, check for phone number
        final user = _authService.currentUser;
        if (user != null) {
          final userProfile = await _databaseService.getUserProfile(user.uid);
          if (!mounted) return;
          if (userProfile == null ||
              userProfile['phone_number'] == null ||
              userProfile['phone_number'].toString().isEmpty) {
            Navigator.pushReplacementNamed(context, '/add_phone');
          } else {
            Navigator.pushReplacementNamed(context, '/wishlists');
          }
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Erro ao fazer login: ${e.toString()}', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _loginComGoogle() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _authService.signInWithGoogle();

    if (!mounted) return;

    switch (result) {
      case GoogleSignInResult.success:
        Navigator.pushReplacementNamed(context, '/wishlists');
        break;
      case GoogleSignInResult.missingPhoneNumber:
        Navigator.pushReplacementNamed(context, '/add_phone');
        break;
      case GoogleSignInResult.cancelled:
        _showSnackBar('Login com Google cancelado.', isError: true);
        break;
      case GoogleSignInResult.failed:
        _showSnackBar(
          'Ocorreu um erro ao fazer login com o Google.',
          isError: true,
        );
        break;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // App Icon/Logo
              Container(
                alignment: Alignment.center,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    size: 40,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Welcome Text
              Text(
                'Bem-vindo de volta!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Acede à tua conta para gerir as tuas wishlists',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Insere o teu email',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: ValidationUtils.validateEmail,
                      enabled: !_isLoading,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Insere a tua password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a sua password.';
                        }
                        return null;
                      },
                      enabled: !_isLoading,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Email Login Button
                    FilledButton(
                      onPressed: _isLoading ? null : _loginComEmail,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Entrar com Email',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ou',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Google Login Button
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _loginComGoogle,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      icon: Container(
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          'assets/images/google_logo.png',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.g_mobiledata,
                              size: 24,
                              color: theme.colorScheme.primary,
                            );
                          },
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
                    
                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não tens conta? ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading 
                              ? null 
                              : () => Navigator.pushNamed(context, '/register'),
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
            ],
          ),
        ),
      ),
    );
  }
}