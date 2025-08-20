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
    try {
      await SmsAutoFill().listenForCode();
    } catch (e) {
      // Handle any errors with SMS auto-fill
      debugPrint('Error setting up SMS auto-fill: $e');
    }
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
        // Navigate to home screen and clear the navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
            PinFieldAutoFill(
              currentCode: _otpCode,
              codeLength: 6,
              onCodeSubmitted: (code) {
                // This is called when the user submits the code manually
                _submitOTP(code);
              },
              onCodeChanged: (code) {
                setState(() {
                  _otpCode = code ?? '';
                });
                if (code != null && code.length == 6) {
                  // Automatically submit when the code is filled
                  _submitOTP(code);
                }
              },
              decoration: BoxLooseDecoration(
                strokeColorBuilder: FixedColorBuilder(Colors.grey.shade300),
                bgColorBuilder: FixedColorBuilder(Colors.white),
                gapSpace: 8,
                strokeWidth: 1,
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_otpCode.length == 6) {
                        _submitOTP(_otpCode);
                      }
                    },
                    child: const Text('Verificar'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      try {
                        await _authService.sendPhoneOtp(widget.phoneNumber);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Código reenviado com sucesso!'),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao reenviar: ${e.toString()}')),
                        );
                      }
                    },
                    child: const Text('Reenviar Código'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
