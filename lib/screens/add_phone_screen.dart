import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/screens/otp_screen.dart';

class AddPhoneScreen extends StatefulWidget {
  const AddPhoneScreen({super.key});

  @override
  State<AddPhoneScreen> createState() => _AddPhoneScreenState();
}

class _AddPhoneScreenState extends State<AddPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _telefoneCompleto;

  Future<void> _sendVerificationCode() async {
    if (_telefoneCompleto == null || _telefoneCompleto!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um número de telemóvel válido.')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    await _authService.verifyPhoneNumber(
      phoneNumber: _telefoneCompleto!,
      verificationCompleted: (credential) async {
        await _authService.linkPhoneNumber(credential);
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      },
      verificationFailed: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Ocorreu um erro')),
          );
        }
      },
      codeSent: (verificationId, forceResendingToken) {
        if (mounted) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => OTPScreen(verificationId: verificationId),
          ));
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
