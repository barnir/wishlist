import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  final _authService = AuthService();
  final _userService = UserService();

  bool _isLoading = false;
  String? _erro;

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

  Future<void> _registar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // Update display name in Supabase user metadata
      await _authService.updateUser(displayName: _nomeController.text.trim());

      if (!mounted) return;
      await _navigateToHomeOrLinkPhone();
    } catch (e) {
      setState(() => _erro = 'Erro ao registar: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email obrigatório';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Formato de email inválido';
    return null;
  }

  String? _validarNome(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nome obrigatório';
    if (value.trim().length < 2) return 'Nome demasiado curto';
    return null;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.length < 8) return 'Password deve ter pelo menos 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password deve conter uma maiúscula';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password deve conter uma minúscula';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password deve conter um número';
    return null;
  }

  String? _validarConfirmaPassword(String? value) {
    if (value != _passwordController.text) return 'Passwords não coincidem';
    return null;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registar nova conta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                if (_erro != null) ...[
                  Text(_erro!, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(labelText: 'Nome'),
                  validator: _validarNome,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: _validarEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  validator: _validarPassword,
                  obscureText: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _confirmarPasswordController,
                  decoration: InputDecoration(labelText: 'Confirmar Password'),
                  validator: _validarConfirmaPassword,
                  obscureText: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registar,
                  child: _isLoading ? CircularProgressIndicator() : Text('Registar'),
                ),
                Divider(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Já tens conta? Fazer login!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}