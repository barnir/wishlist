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
  bool _showPhoneForm = false;
  String? _telefoneCompleto;
  String? _userEmail;
  
  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  
  void _loadUserInfo() {
    final user = _authService.currentUser;
    debugPrint('=== AddPhoneScreen Debug ===');
    debugPrint('Current user: $user');
    debugPrint('User email: ${user?.email}');
    debugPrint('User display name: ${user?.displayName}');
    debugPrint('User phone: ${user?.phoneNumber}');
    
    // Check for invalid state: user with phone only (shouldn't happen)
    if (user != null && 
        user.phoneNumber != null && 
        user.phoneNumber!.isNotEmpty &&
        (user.email == null || user.email!.isEmpty) &&
        (user.displayName == null || user.displayName!.isEmpty)) {
      
      debugPrint('⚠️ INVALID STATE: User authenticated with phone only - this should not happen!');
      debugPrint('   - Signing out and redirecting to login');
      _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }
    
    setState(() {
      // Better fallback chain for user identification
      _userEmail = user?.email?.isNotEmpty == true 
          ? user!.email!
          : user?.displayName?.isNotEmpty == true
              ? user!.displayName!
              : 'Utilizador em processo de registo';
    });
    debugPrint('Set _userEmail to: $_userEmail');
  }

  Future<void> _cancelRegistration() async {
    // Show confirmation dialog
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancelar Registo'),
          content: const Text(
            'Tem a certeza que deseja cancelar o registo? '
            'Perderá o progresso atual e terá de começar novamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continuar Registo'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancelar Registo'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      try {
        await _authService.cancelRegistration();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cancelar registo: $e')),
          );
        }
      }
    }
  }

  Future<void> _sendVerificationCode() async {
    if (_telefoneCompleto == null || _telefoneCompleto!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um número de telemóvel válido.'),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.sendPhoneOtp(_telefoneCompleto!);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                OTPScreen(phoneNumber: _telefoneCompleto!), // Pass phone number
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())), // Display the error message
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
      appBar: AppBar(
        title: const Text('Completar Registo'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _cancelRegistration,
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: !_showPhoneForm ? _buildChoiceScreen() : _buildPhoneForm(),
      ),
    );
  }

  Widget _buildChoiceScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.phone_android,
          size: 80,
          color: Colors.blue,
        ),
        const SizedBox(height: 32),
        const Text(
          'Processo Incompleto',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (_userEmail != null && _userEmail != 'Utilizador logado') ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Continuando registo para:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 32), // Align with icon above
                    Expanded(
                      child: Text(
                        _userEmail!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Para completar o registo, é necessário verificar um número de telemóvel.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _showPhoneForm = true;
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Continuar com Telemóvel',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              await _authService.signOut();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Escolher Outro Método',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _showPhoneForm = false;
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(
                child: Text(
                  'Adicionar Telemóvel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Insira o seu número de telemóvel para receber um código de verificação.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
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
          const SizedBox(height: 24),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendVerificationCode,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Enviar Código',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
