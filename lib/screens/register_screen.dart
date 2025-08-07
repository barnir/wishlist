import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _erro;

  Future<void> _registar() async {
    setState(() { _isLoading = true; _erro = null; });
    if (!_formKey.currentState!.validate()) {
      setState(() { _isLoading = false; });
      return;
    }
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Guarda o nome no perfil do utilizador
      await FirebaseAuth.instance.currentUser!.updateDisplayName(_nomeController.text.trim()); 
      Navigator.pushReplacementNamed(context, '/profile');
      // Redirecciona/utiliza navegação conforme a lógica da app
    } on FirebaseAuthException catch (e) {
      setState(() { _erro = e.message; });
    } finally {
      setState(() { _isLoading = false; });
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
