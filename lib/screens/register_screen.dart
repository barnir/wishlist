import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String confirmPassword = '';
  String error = '';

  bool isPasswordCompliant(String password) {
    // Critérios para senha: mínimo 6 caracteres (Firebase exige 6)
    return password.length >= 6;
  }

  Future<void> register() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            error = 'Este email já está em uso.';
            break;
          case 'invalid-email':
            error = 'Email inválido.';
            break;
          case 'weak-password':
            error = 'Senha fraca.';
            break;
          default:
            error = 'Erro: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        error = 'Erro inesperado: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => email = v,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o email';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Senha'),
                obscureText: true,
                onChanged: (v) => password = v,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe a senha';
                  if (!isPasswordCompliant(v)) return 'Senha deve ter pelo menos 6 caracteres';
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Confirme a senha'),
                obscureText: true,
                onChanged: (v) => confirmPassword = v,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirme a senha';
                  if (v != password) return 'As senhas não coincidem';
                  return null;
                },
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(error, style: TextStyle(color: Colors.red)),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: register,
                child: Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
