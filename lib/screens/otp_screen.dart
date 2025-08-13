import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;

  const OTPScreen({super.key, required this.verificationId});

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
      // Supabase phone authentication uses signInWithOtp and verifyOtp.
      // The current AuthService methods for phone auth are unimplemented.
      // This part needs to be refactored once Supabase phone auth is implemented.
      throw Exception('Autenticação por telefone não implementada para Supabase.');

      // Example of how it might look with Supabase (conceptual):
      // final AuthResponse response = await _authService.verifyOtp(
      //   phone: '+' + widget.verificationId, // Assuming verificationId is phone number
      //   token: _otpController.text.trim(),
      //   type: OtpType.sms,
      // );
      // if (response.user != null) {
      //   if (mounted) {
      //     Navigator.of(context).pop();
      //     Navigator.of(context).pop();
      //   }
      // }
    } on Exception catch (e) { // Changed from FirebaseAuthException
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