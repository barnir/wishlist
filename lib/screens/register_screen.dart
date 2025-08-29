import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';

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

  bool _isLoading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {}); // Atualiza a UI quando a password muda
    });
  }

  Future<void> _registar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.createUserWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nomeController.text.trim(),
      );

      // No need to navigate manually - StreamBuilder will handle it
      // User will be automatically taken to AddPhoneScreen since no profile exists yet
      debugPrint('✅ Email registration successful - StreamBuilder will handle navigation');
      
    } catch (e) {
      debugPrint('Registration error: $e');
      setState(() => _erro = 'Erro ao registar: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validarEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email obrigatório';
    }
    // Regex mais robusto para validação de email
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
      return 'Formato de email inválido';
    }
    return null;
  }

  String? _validarNome(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nome obrigatório';
    }
    if (value.trim().length < 2) {
      return 'Nome demasiado curto';
    }
    return null;
  }

  String? _validarPassword(String? value) {
    if (value == null || value.length < 8) {
      return 'Password deve ter pelo menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password deve conter uma maiúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password deve conter uma minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password deve conter um número';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password deve conter um símbolo especial';
    }
    return null;
  }

  String? _validarConfirmaPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords não coincidem';
    }
    return null;
  }

  Widget _buildPasswordRequirement(String text, bool isValid) {
    final theme = Theme.of(context);
    final validColor = isValid ? Colors.green[600]! : 
        (theme.brightness == Brightness.dark ? Colors.red[400]! : Colors.red[600]!);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: validColor,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: validColor,
              fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
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
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validarNome,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validarEmail,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validarPassword,
                  obscureText: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requisitos da password:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildPasswordRequirement('Pelo menos 8 caracteres', 
                          _passwordController.text.length >= 8),
                      _buildPasswordRequirement('Uma maiúscula (A-Z)', 
                          RegExp(r'[A-Z]').hasMatch(_passwordController.text)),
                      _buildPasswordRequirement('Uma minúscula (a-z)', 
                          RegExp(r'[a-z]').hasMatch(_passwordController.text)),
                      _buildPasswordRequirement('Um número (0-9)', 
                          RegExp(r'[0-9]').hasMatch(_passwordController.text)),
                      _buildPasswordRequirement('Um símbolo especial (!@#\$%^&*)', 
                          RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmarPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validarConfirmaPassword,
                  obscureText: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _registar,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text('Registar'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Já tens conta? Fazer login!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
