import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/firebase_auth_service.dart';
import '../constants/ui_constants.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({super.key, required this.phoneNumber});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> with WidgetsBindingObserver {
  final _authService = AuthService();
  final _firebaseAuthService = FirebaseAuthService();
  final _otpControllers = List.generate(6, (index) => TextEditingController());
  final _focusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  bool _hasSubmitted = false;
  String? _storedPhoneNumber;

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
      _showSnackBar('Por favor, insira o código completo de 6 dígitos.');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _hasSubmitted = true;
    });

    try {
      debugPrint('=== Verifying Firebase OTP ===');
      debugPrint('Code: $code');
      
      final userCredential = await _authService.verifyPhoneOtp(
        widget.phoneNumber,
        code,
      );
      
      // Check if verification was successful - either via userCredential or fallback (null return but user is authenticated)
      final currentUser = AuthService().currentUser;
      final isSuccessful = userCredential?.user != null || (userCredential == null && currentUser != null);
      
      if (isSuccessful && mounted) {
        debugPrint('OTP verification successful${userCredential == null ? ' (via fallback)' : ''}');
        debugPrint('🚀 Navigating to home route for automatic screen detection');
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      debugPrint('OTP verification error: $e');
      if (mounted) {
        String errorMessage = 'Código inválido. Tente novamente.';
        if (e.toString().contains('No verification ID found')) {
          errorMessage = 'Sessão expirou. Por favor, volte e reenvie o código.';
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
    
    // Auto-submit when all 6 digits are entered
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length == 6 && !_isLoading) {
      _submitOTP();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar Código')),
      body: Padding(
        padding: UIConstants.paddingL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Insira o código de 6 dígitos enviado para ${widget.phoneNumber}.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'O Firebase irá detectar automaticamente o SMS.',
              textAlign: TextAlign.center,
              style: TextStyle(
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
                    child: const Text('Verificar'),
                  ),
                  Spacing.m,
                  TextButton(
                    onPressed: () async {
                      try {
                        await _authService.sendPhoneOtp(widget.phoneNumber);
                        if (mounted) {
                          _showSnackBar('Código reenviado com sucesso!');
                        }
                      } catch (e) {
                        if (mounted) {
                          _showSnackBar('Erro ao reenviar código.');
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