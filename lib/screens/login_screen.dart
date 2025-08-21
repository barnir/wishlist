import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/user_service.dart';
import '../constants/ui_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _userService = UserService();
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
      setState(() {
        _isLoading = true;
      });
      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // After email login, check for phone number
        final user = _authService.currentUser;
        if (user != null) {
          final userProfile = await _userService.getUserProfile(user.id);
          if (!mounted) return;
          if (userProfile == null ||
              userProfile['phone_number'] == null ||
              userProfile['phone_number'].toString().isEmpty) {
            Navigator.pushReplacementNamed(context, '/add_phone');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
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
        Navigator.pushReplacementNamed(context, '/home');
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

  Future<void> _loginComTelemovel() async {
    Navigator.pushNamed(context, '/telefoneLogin');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar na Wishlist')),
      body: Center(
        child: SingleChildScrollView(
          padding: UIConstants.paddingL,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira o seu email.';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                      return 'Formato de email inválido.';
                    }
                    return null;
                  },
                ),
                Spacing.m,
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a sua password.';
                    }
                    return null;
                  },
                ),
                Spacing.l,
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginComEmail,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text('Entrar com Email'),
                ),
                Spacing.l,
                ElevatedButton.icon(
                  icon: const Icon(Icons.sms),
                  label: const Text('Entrar com Telemóvel'),
                  onPressed: _isLoading ? null : _loginComTelemovel,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                Spacing.m,
                ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Entrar com Google'),
                  onPressed: _isLoading ? null : _loginComGoogle,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                Spacing.l,
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Não tens conta? Regista-te!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
