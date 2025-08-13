import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o seu e-mail.';
    }
    if (!value.contains('@')) {
      return 'Por favor, insira um e-mail válido.';
    }
    return null;
  }

  String? _validarSenha(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira a sua senha.';
    }
    if (value.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres.';
    }
    return null;
  }

  Future<void> _loginComEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _erro = 'Erro ao fazer login: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginComGoogle() async {
    setState(() => _isLoading = true);

    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_erro != null) ...[
                  Text(_erro!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  validator: _validarEmail,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: _validarSenha,
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginComEmail,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Entrar com E-mail'),
                ),
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  icon: const Icon(Icons.phone_android),
                  label: const Text('Entrar com Telemóvel'),
                  onPressed: _isLoading ? null : _loginComTelemovel,
                ),
                const SizedBox(height: 9),
                OutlinedButton.icon(
                  icon: const Icon(Icons.android),
                  label: const Text('Entrar com Google'),
                  onPressed: _isLoading ? null : _loginComGoogle,
                ),
                const SizedBox(height: 18),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}