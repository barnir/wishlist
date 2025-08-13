import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:wishlist_app/services/auth_service.dart';

class TelefoneLoginScreen extends StatefulWidget {
  const TelefoneLoginScreen({super.key});

  @override
  State<TelefoneLoginScreen> createState() => _TelefoneLoginScreenState();
}

class _TelefoneLoginScreenState extends State<TelefoneLoginScreen> {
  final _authService = AuthService();
  String? _telefoneCompleto;
  final _codeController = TextEditingController();
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
      await _authService.sendPhoneOtp(
        _telefoneCompleto!,
      );
      setState(() {
        _codeSent = true;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = 'Erro ao enviar código: ${e.toString()}';
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
      await _authService.verifyPhoneOtp(
        _telefoneCompleto!,
        _codeController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } on Exception catch (e) {
      setState(() {
        _error = 'Erro ao verificar código: ${e.toString()}';
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