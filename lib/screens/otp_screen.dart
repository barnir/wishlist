import 'dart:async';
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
  bool _hasSubmitted = false; // Prevent multiple submissions
  String _otpCode = '';

  @override
  void initState() {
    super.initState();
    _initSmsListener();
  }

  void _initSmsListener() async {
    try {
      debugPrint('=== SMS AutoFill Debug Information ===');
      
      // Request SMS permissions
      final smsPermission = await Permission.sms.status;
      debugPrint('SMS Permission status: $smsPermission');
      
      if (smsPermission != PermissionStatus.granted) {
        final result = await Permission.sms.request();
        debugPrint('SMS Permission request result: $result');
        
        if (result != PermissionStatus.granted) {
          debugPrint('SMS permissions denied - auto-fill will not work');
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
      
      // Get app signature first - this is crucial for SMS retriever API
      final signature = await SmsAutoFill().getAppSignature;
      debugPrint('App signature: $signature');
      debugPrint('Phone number for OTP: ${widget.phoneNumber}');
      
      // Start listening for SMS
      await SmsAutoFill().listenForCode();
      debugPrint('SMS AutoFill listener started successfully');
      
      // Also set up a manual fallback check
      _startManualSmsCheck();
      
    } catch (e) {
      // Handle any errors with SMS auto-fill
      debugPrint('Error setting up SMS auto-fill: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  void _startManualSmsCheck() {
    debugPrint('Starting manual SMS check as fallback...');
    // This is a fallback mechanism
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Check if we already have a code
      if (_otpCode.length >= 6) {
        timer.cancel();
        debugPrint('Manual SMS check: Code already filled');
        return;
      }
      
      // Cancel after 2 minutes
      if (timer.tick > 60) {
        timer.cancel();
        debugPrint('Manual SMS check: Timeout after 2 minutes');
        return;
      }
      
      debugPrint('Manual SMS check tick: ${timer.tick} - Still waiting for SMS...');
    });
  }

  Future<void> _submitOTP(String code) async {
    // Prevent multiple submissions
    if (_hasSubmitted || _isLoading) {
      debugPrint('Submission ignored - already processing: hasSubmitted=$_hasSubmitted, isLoading=$_isLoading');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasSubmitted = true;
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
          // Navigate to home screen (which will show the main app with navigation) and clear the navigation stack
          navigator.pushNamedAndRemoveUntil('/', (route) => false);
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
          // Only reset hasSubmitted on error (success will navigate away)
          if (response?.user == null) {
            _hasSubmitted = false;
          }
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
                  // Only auto-submit if the code contains only digits
                  if (RegExp(r'^\d{6}$').hasMatch(code)) {
                    debugPrint('Auto-submitting code: $code');
                    // Submit immediately for SMS auto-fill
                    _submitOTP(code);
                  } else {
                    debugPrint('Invalid code format (not 6 digits): $code');
                  }
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
