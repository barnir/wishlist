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

  bool _isLoading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _navigateToHomeOrLinkPhone() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userProfile = await _userService.getUserProfile(user.id);
      if (userProfile == null || userProfile['phone_number'] == null || userProfile['phone_number'].isEmpty) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/add_phone'); // Assuming /add_phone navigates to LinkPhoneScreen
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  Future<void> _loginComGoogle() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      await _navigateToHomeOrLinkPhone();
    } catch (e) {
      setState(() => _erro = 'Erro ao fazer login com Google: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    );
  }

  
}