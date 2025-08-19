import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
// Importa o pacote
import 'package:wishlist_app/screens/otp_screen.dart';
import 'package:wishlist_app/services/auth_service.dart';

class TelefoneLoginScreen extends StatefulWidget {
  const TelefoneLoginScreen({super.key});

  @override
  State<TelefoneLoginScreen> createState() => _TelefoneLoginScreenState();
}

class _TelefoneLoginScreenState extends State<TelefoneLoginScreen> {
  final _authService = AuthService();
  String? _telefoneCompleto;
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
      await _authService.sendPhoneOtp(_telefoneCompleto!);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OTPScreen(phoneNumber: _telefoneCompleto!),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao enviar código: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login com Telemóvel'),
      ), // Título corrigido
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 12),
            ],
            IntlPhoneField(
              initialCountryCode: 'PT',
              decoration: const InputDecoration(
                labelText: 'Número de Telemóvel',
                border: OutlineInputBorder(),
              ),
              onChanged: (phone) {
                _telefoneCompleto = phone.completeNumber;
              },
            ),
            const SizedBox(height: 18),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _enviarCodigo,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Enviar Código'),
              ),
          ],
        ),
      ),
    );
  }
}
