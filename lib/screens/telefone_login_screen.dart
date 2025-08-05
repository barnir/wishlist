import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelefoneLoginScreen extends StatefulWidget {
  const TelefoneLoginScreen({Key? key}) : super(key: key);

  @override
  State<TelefoneLoginScreen> createState() => _TelefoneLoginScreenState();
}

class _TelefoneLoginScreenState extends State<TelefoneLoginScreen> {
  String? _telefoneCompleto;
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  String? _error;

  Future<void> _enviarCodigo() async {
    if (_telefoneCompleto == null || _telefoneCompleto!.isEmpty) {
      setState(() {
        _error = 'Por favor, insere um número de telemóvel válido.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _telefoneCompleto!,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) Navigator.pop(context, true);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _error = e.message;
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _error = 'Erro ao enviar código: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verificarCodigo() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() {
        _error = 'Por favor, insere o código SMS recebido.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login com Telemóvel')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            if (!_codeSent) ...[
              IntlPhoneField(
                initialCountryCode: 'PT',
                decoration: const InputDecoration(
                  labelText: 'Número de Telemóvel',
                  border: OutlineInputBorder(),
                ),
                onChanged: (phone) {
                  _telefoneCompleto = phone.completeNumber;
                },
                onCountryChanged: (country) {
                  _telefoneCompleto = null; // reset para novo país
                },
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _isLoading ? null : _enviarCodigo,
                child:
                    _isLoading ? const CircularProgressIndicator() : const Text('Enviar Código'),
              ),
            ] else ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Código SMS',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _isLoading ? null : _verificarCodigo,
                child:
                    _isLoading ? const CircularProgressIndicator() : const Text('Verificar Código'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
