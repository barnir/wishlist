import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/screens/otp_screen.dart';

class LinkPhoneScreen extends StatefulWidget {
  const LinkPhoneScreen({super.key});

  @override
  State<LinkPhoneScreen> createState() => _LinkPhoneScreenState();
}

class _LinkPhoneScreenState extends State<LinkPhoneScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    await _authService.verifyPhoneNumber(
      phoneNumber: _phoneController.text.trim(),
      verificationCompleted: (credential) async {
        // Auto-retrieval or instant verification
        await _authService.linkPhoneNumber(credential);
        if (mounted) {
          Navigator.of(context).pop();
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
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Número de Telemóvel'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o seu número de telemóvel';
                  }
                  return null;
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
