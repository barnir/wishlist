import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/user_service.dart';

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
  String? _erro;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loginComEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _erro = null;
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
          if (userProfile == null || userProfile['phone_number'] == null || userProfile['phone_number'].toString().isEmpty) {
            Navigator.pushReplacementNamed(context, '/add_phone');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }

      } catch (e) {
        if (mounted) {
          setState(() => _erro = 'Erro ao fazer login: ${e.toString()}');
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
      _erro = null;
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
        setState(() => _erro = 'Login com Google cancelado.');
        break;
      case GoogleSignInResult.failed:
        setState(() => _erro = 'Ocorreu um erro ao fazer login com o Google.');
        break;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginComTelemovel() async {
    Navigator.pushNamed(context, '/telefoneLogin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar na Wishlist')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_erro != null) ...[
                  Text(
                    _erro!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o seu email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a sua password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginComEmail,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: const Text('Entrar com Email'),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.sms),
                  label: const Text('Entrar com Telemóvel'),
                  onPressed: _isLoading ? null : _loginComTelemovel,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                  label: const Text('Entrar com Google'),
                  onPressed: _isLoading ? null : _loginComGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
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