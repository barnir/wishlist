import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _erro;

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
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Login bem-sucedido, redirecionar
    } on FirebaseAuthException catch (e) { 
      if (e.code == 'user-not-found') {
        _erro = 'Nenhum usuário encontrado com este e-mail.';
      } else if (e.code == 'wrong-password') {
        _erro = 'Senha incorreta.';
      } else {
        _erro = e.message;
      }
    } finally {    
      setState(() {
        _isLoading = false;
      });
    }
  }

Future<void> _loginComGoogle() async {
  setState(() {
    _isLoading = true;
    _erro = null;
  });
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      serverClientId: '515293340951-94s0arso1q5uciton05l3mso47709dia.apps.googleusercontent.com',
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    if (googleAuth.idToken == null) {
      setState(() {
        _erro = 'Não foi possível obter o idToken do Google.';
      });
      return;
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    // Redirecionamento ou UI para login bem-sucedido...
  } on FirebaseAuthException catch (e) {
    setState(() {
      _erro = e.message;
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
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
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState?.validate() == true) {
                            _loginComEmail();
                          }
                        },
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
}
