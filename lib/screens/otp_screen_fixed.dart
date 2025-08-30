import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:wishlist_app/services/firebase_auth_service.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import '../constants/ui_constants.dart';
import '../main.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with WidgetsBindingObserver {
  final _firebaseAuthService = FirebaseAuthService();
  final _otpControllers = List.generate(6, (index) => TextEditingController());
  final _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _hasSubmitted = false;
  String? _storedPhoneNumber;
  int _secondsRemaining = 0;
  static const int _resendIntervalSeconds = 20;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Firebase Auth has native SMS auto-fill, no custom implementation needed
    debugPrint('=== Firebase OTP Screen Initialized ===');
    debugPrint('Phone number: ${widget.phoneNumber}');
    
    // Check for stored phone number to validate consistency
    _checkStoredPhoneNumber();
    
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
    _startCountdown();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint('OTP Screen: App resumed, checking for stored verification data');
      _checkStoredPhoneNumber();
    }
  }

  Future<void> _checkStoredPhoneNumber() async {
    try {
      _storedPhoneNumber = await _firebaseAuthService.getStoredPhoneNumber();
      if (_storedPhoneNumber != null) {
        debugPrint('Stored phone number found: $_storedPhoneNumber');
        if (_storedPhoneNumber != widget.phoneNumber) {
          debugPrint('Warning: Phone number mismatch. Current: ${widget.phoneNumber}, Stored: $_storedPhoneNumber');
        }
      }
    } catch (e) {
      debugPrint('Error checking stored phone number: $e');
    }
  }

  Future<void> _submitOTP() async {
    if (_hasSubmitted || _isLoading) {
      debugPrint('Submission ignored - already processing');
      return;
    }
    
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 6) {
      HapticFeedback.lightImpact();
      _showSnackBar('Por favor, insira todos os 6 dígitos.');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasSubmitted = true;
    });

    try {
      debugPrint('=== Verifying Firebase OTP ===');
      debugPrint('Code: $code');
      debugPrint('Method: ${_hasSubmitted ? "Auto-submit" : "Manual"}');
      
      final result = await _firebaseAuthService.verifyPhoneOtpEnhanced(
        widget.phoneNumber,
        code,
      );

      if (!mounted) return;
      
      debugPrint('OTP verification result: $result');
      
      switch (result) {
        case PhoneVerificationResult.success:
        case PhoneVerificationResult.alreadyLinked:
          debugPrint('OTP verification successful ($result)');
          // Use Future.microtask to ensure context is valid for navigation
          Future.microtask(() {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          });
          break;
        case PhoneVerificationResult.invalidCode:
          HapticFeedback.lightImpact();
          _showSnackBar(AppLocalizations.of(context)?.otpInvalidCode ?? 'Código inválido. Tente novamente.');
          setState(() => _hasSubmitted = false);
          break;
        case PhoneVerificationResult.codeExpired:
          HapticFeedback.mediumImpact();
          _showSnackBar(AppLocalizations.of(context)?.otpCodeExpired ?? 'Código expirou. Reenvie o código.');
          setState(() => _hasSubmitted = false);
          break;
        case PhoneVerificationResult.phoneInUse:
          HapticFeedback.mediumImpact();
          _showSnackBar(AppLocalizations.of(context)?.otpPhoneInUse ?? 'Telefone já associado a outra conta.');
          setState(() => _hasSubmitted = false);
          break;
        case PhoneVerificationResult.internalError:
          HapticFeedback.heavyImpact();
          debugPrint('Internal error during OTP verification - user can retry');
          _showSnackBar(AppLocalizations.of(context)?.otpInternalError ?? 'Erro interno. Tente novamente.');
          setState(() => _hasSubmitted = false);
          break;
      }
    } catch (e) {
      debugPrint('OTP verification error: $e');
      if (mounted) {
        String errorMessage = AppLocalizations.of(context)?.otpInvalidCode ?? 'Código inválido. Tente novamente.';
        if (e.toString().contains('No verification ID found')) {
          errorMessage = AppLocalizations.of(context)?.otpCodeExpired ?? 'Sessão expirou. Por favor, volte e reenvie o código.';
        }
        _showSnackBar(errorMessage);
        setState(() {
          _hasSubmitted = false;
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

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = _resendIntervalSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0 || _isLoading) return;
    try {
      setState(() => _isLoading = true);
      await _firebaseAuthService.resendPhoneOtp(widget.phoneNumber);
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context)?.otpCodeResent ?? 'Código reenviado.');
      HapticFeedback.selectionClick();
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
      HapticFeedback.lightImpact();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto-submit when all 6 digits are entered with improved safety
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length == 6 && !_isLoading && !_hasSubmitted) {
      // Add delay to ensure all text field updates are complete
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_isLoading && !_hasSubmitted) {
          debugPrint('Auto-submitting OTP: $code');
          _submitOTP();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)?.otpVerifyTitle ?? 'Verificar Código')),
      body: Padding(
        padding: UIConstants.paddingL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)?.otpInstructionPhone(widget.phoneNumber) ?? 'Insira o código de 6 dígitos enviado para ${widget.phoneNumber}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.otpAutoDetectNote ?? 'O Firebase irá detectar automaticamente o SMS.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Spacing.l,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _onCodeChanged(value, index),
                  ),
                );
              }),
            ),
            Spacing.l,
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _submitOTP,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: Text(AppLocalizations.of(context)?.otpVerifyButton ?? 'Verificar'),
                  ),
                  Spacing.m,
                  TextButton(
                    onPressed: _secondsRemaining == 0 ? _resendCode : null,
                    child: Text(
                      _secondsRemaining == 0
                          ? (AppLocalizations.of(context)?.otpResend ?? 'Reenviar Código')
                          : (AppLocalizations.of(context)?.otpResendIn(_secondsRemaining.toString()) ?? 'Reenviar em $_secondsRemaining s'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
