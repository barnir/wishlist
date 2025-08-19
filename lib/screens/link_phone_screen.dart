import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/screens/otp_screen.dart';

class LinkPhoneScreen extends StatefulWidget {
  const LinkPhoneScreen({super.key});

  @override
  State<LinkPhoneScreen> createState() => _LinkPhoneScreenState();
}

class _LinkPhoneScreenState extends State<LinkPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _telefoneCompleto;

  Future<void> _sendVerificationCode() async {
    if (_telefoneCompleto == null || _telefoneCompleto!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um número de telemóvel válido.'),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.sendPhoneOtp(_telefoneCompleto!);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OTPScreen(phoneNumber: _telefoneCompleto!),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar código: ${e.toString()}')),
        );
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
      appBar: AppBar(title: const Text('Adicionar Telemóvel')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _sendVerificationCode,
                  child: const Text('Enviar Código'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
