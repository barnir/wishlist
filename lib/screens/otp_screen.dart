import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:wishlist_app/services/auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _authService = AuthService();
  bool _isLoading = false;
  String _otpCode = '';

  @override
  void initState() {
    super.initState();
    _listenForCode();
  }

  void _listenForCode() async {
    await SmsAutoFill().listenForCode();
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  Future<void> _submitOTP(String code) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authService.verifyPhoneOtp(
        widget.phoneNumber,
        code,
      );
      if (response.user != null && mounted) {
        // Navigate back to the root or the main screen after successful login
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Insira o código de 6 dígitos enviado para o seu telemóvel.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFieldPinAutoFill(
              currentCode: _otpCode,
              codeLength: 6,
              onCodeSubmitted: (code) {
                // This is called when the user submits the code manually
              },
              onCodeChanged: (code) {
                _otpCode = code;
                if (code.length == 6) {
                  // Automatically submit when the code is filled
                  _submitOTP(code);
                }
              },
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: () {
                  if (_otpCode.length == 6) {
                    _submitOTP(_otpCode);
                  }
                },
                child: const Text('Verificar'),
              ),
          ],
        ),
      ),
    );
  }
}
