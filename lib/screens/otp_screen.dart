import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:permission_handler/permission_handler.dart';
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
    _initSmsListener();
  }

  void _initSmsListener() async {
    try {
      // Request SMS permissions
      final smsPermission = await Permission.sms.status;
      debugPrint('SMS Permission status: $smsPermission');
      
      if (smsPermission != PermissionStatus.granted) {
        final result = await Permission.sms.request();
        debugPrint('SMS Permission request result: $result');
        
        if (result != PermissionStatus.granted) {
          debugPrint('SMS permission denied, auto-fill may not work');
          // Show user message about manual entry
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Permissão de SMS negada. Terá de inserir o código manualmente.'),
              ),
            );
          }
          return;
        }
      }
      
      // Get app signature first
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint('App signature: $signature');
      
      // Start listening for SMS
      await SmsAutoFill().listenForCode();
      
      debugPrint('SMS AutoFill listener started successfully');
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

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final response = await _authService.verifyPhoneOtp(
        widget.phoneNumber,
        code,
      );
      if (response.user != null) {
        if (mounted) {
          // Navigate to home screen and clear the navigation stack
          navigator.pushNamedAndRemoveUntil('/wishlists', (route) => false);
        }
      }
    } on Exception catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Insira o código de 6 dígitos enviado para ${widget.phoneNumber}.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'O código será preenchido automaticamente quando receber o SMS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            PinFieldAutoFill(
              currentCode: _otpCode,
              codeLength: 6,
              autoFocus: true,
              cursor: Cursor(
                width: 2,
                height: 20,
                color: Colors.blue,
                enabled: true,
              ),
              onCodeSubmitted: (code) {
                debugPrint('Code submitted manually: $code');
                _submitOTP(code);
              },
              onCodeChanged: (code) {
                debugPrint('Code changed: $code');
                setState(() {
                  _otpCode = code ?? '';
                });
                if (code != null && code.length == 6) {
                  debugPrint('Auto-submitting code: $code');
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
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      try {
                        await _authService.sendPhoneOtp(widget.phoneNumber);
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Código reenviado com sucesso!'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Erro ao reenviar: ${e.toString()}')),
                          );
                        }
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
