import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart'; // Importe seu arquivo de registro

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String email = '';
  String password = '';
  String error = '';
  bool _loading = false;

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      error = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password);
      // Login bem-sucedido - faça a navegação desejada aqui, ex:
      // Navigator.pushReplacementNamed(context, '/wishlist');
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            error = 'Usuário não encontrado.';
            break;
          case 'wrong-password':
            error = 'Senha incorreta.';
            break;
          case 'invalid-email':
            error = 'Email inválido.';
            break;
          case 'user-disabled':
            error = 'Usuário desabilitado.';
            break;
          default:
            error = 'Erro: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        error = 'Erro inesperado: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> loginWithGoogle() async {
    setState(() {
      _loading = true;
      error = '';
    });
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _loading = false;
        });
        return; // Cancelou login
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
      // Navegação após login no sucesso
    } catch (e) {
      setState(() {
        error = 'Falha no login com Google.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void goToRegister() {
    if (_loading) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegisterScreen()),
    );
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                focusNode: _emailFocus,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o email.';
                  }
                  if (!value.contains('@')) {
                    return 'Email inválido.';
                  }
                  return null;
                },
                onChanged: (value) => email = value,
              ),
              TextFormField(
                focusNode: _passwordFocus,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a senha.';
                  }
                  if (value.length < 6) {
                    return 'Senha deve ter ao menos 6 caracteres.';
                  }
                  return null;
                },
                onChanged: (value) => password = value,
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: login,
                      child: const Text('Entrar'),
                    ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Entrar com Google'),
                onPressed: _loading ? null : loginWithGoogle,
              ),
              TextButton(
                onPressed: goToRegister,
                child: const Text('Criar conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
