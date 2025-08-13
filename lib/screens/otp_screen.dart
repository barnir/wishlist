import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber; // Changed from verificationId

  const OTPScreen({super.key, required this.phoneNumber}); // Changed from verificationId

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _submitOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.verifyPhoneOtp(
        widget.phoneNumber,
        _otpController.text.trim(),
      );
      if (response.user != null) {
        if (mounted) {
          // Pop twice to go back to the profile screen or home screen
          Navigator.of(context).pop(); // Pop OTPScreen
          Navigator.of(context).pop(); // Pop TelefoneLoginScreen or LinkPhoneScreen
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
      appBar: AppBar(title: const Text('Verificar Código')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _otpController,
                decoration: const InputDecoration(labelText: 'Código de Verificação'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o código de verificação';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submitOTP,
                  child: const Text('Verificar'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}