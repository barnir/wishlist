import 'package:flutter/material.dart';
import '../theme_extensions.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:mywishstash/services/auth_service.dart';
import 'package:mywishstash/screens/otp_screen.dart';
import '../widgets/app_snack.dart';
import 'package:mywishstash/utils/app_logger.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';

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
    
    // Check for invalid state: user with phone only (shouldn't happen)
    if (user != null && 
        user.phoneNumber != null && 
        user.phoneNumber!.isNotEmpty &&
        (user.email == null || user.email!.isEmpty) &&
        (user.displayName == null || user.displayName!.isEmpty)) {
      
      logW('Invalid phone-only state; forcing sign out', tag: 'UI');
      _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }
    
    setState(() {
      // Better fallback chain for user identification
      _userEmail = user?.email?.isNotEmpty == true 
          ? user!.email!
          : user?.displayName?.isNotEmpty == true
              ? user!.displayName!
              : AppLocalizations.of(context)?.registrationUserPlaceholder ?? 'Utilizador em processo de registo';
    });
  }

  Future<void> _cancelRegistration() async {
    // Show confirmation dialog
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.cancelRegistrationTitle ?? 'Cancelar Registo'),
          content: Text(AppLocalizations.of(context)?.cancelRegistrationMessage ?? 'Tem a certeza que deseja cancelar o registo? Perderá o progresso atual e terá de começar novamente.'),
          actions: [
            // Secondary (dismiss / keep) action first (left)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)?.continueRegistration ?? 'Continuar Registo'),
            ),
            // Primary destructive confirm on the right
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: context.semanticColors.danger),
              child: Text(AppLocalizations.of(context)?.cancelRegistrationTitle ?? 'Cancelar Registo'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true) {
      try {
        await _authService.cancelRegistration();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        if (mounted) {
          AppSnack.show(context, (AppLocalizations.of(context)?.errorCancelRegistration(e.toString()) ?? 'Erro ao cancelar registo: $e'), type: SnackType.error);
        }
      }
    }
  }

  Future<void> _sendVerificationCode() async {
    if (_telefoneCompleto == null || _telefoneCompleto!.isEmpty) {
  AppSnack.show(context, AppLocalizations.of(context)?.invalidPhoneWarning ?? 'Por favor, insira um número de telemóvel válido.', type: SnackType.warning);
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
  AppSnack.show(context, e.toString(), type: SnackType.error);
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _cancelRegistration();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)?.completeRegistrationTitle ?? 'Completar Registo'),
          automaticallyImplyLeading: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _cancelRegistration,
          ),
          actions: [
            TextButton(
              onPressed: _cancelRegistration,
              child: Text(
                AppLocalizations.of(context)?.cancel ?? 'Cancelar',
                style: TextStyle(color: context.semanticColors.danger),
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: !_showPhoneForm ? _buildChoiceScreen() : _buildPhoneForm(),
        ),
      ),
    );
  }

  Widget _buildChoiceScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.phone_android,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 32),
        Text(
          AppLocalizations.of(context)?.incompleteProcessTitle ?? 'Processo Incompleto',
          style: const TextStyle(
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
              color: context.semanticColors.successContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.semanticColors.success.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: context.semanticColors.success),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)?.continuingRegistrationFor ?? 'Continuando registo para:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          color: context.semanticColors.onSuccessContainer,
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
    Text(
          AppLocalizations.of(context)?.phoneVerificationIntro ?? 'Para completar o registo, é necessário verificar um número de telemóvel.',
          style: TextStyle(
            fontSize: 16,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            child: Text(
              AppLocalizations.of(context)?.continueWithPhone ?? 'Continuar com Telemóvel',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () async {
              try {
                await _authService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              } catch (e) {
                if (mounted) {
                  AppSnack.show(context, 'Erro ao fazer logout: $e', type: SnackType.error);
                }
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              AppLocalizations.of(context)?.chooseAnotherMethod ?? 'Escolher Outro Método',
              style: const TextStyle(fontSize: 16),
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
              Expanded(
                child: Text(
                  AppLocalizations.of(context)?.addPhoneTitle ?? 'Adicionar Telemóvel',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
  Text(
    AppLocalizations.of(context)?.enterPhoneInstruction ?? 'Insira o seu número de telemóvel para receber um código de verificação.',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 16,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
      ),
          const SizedBox(height: 24),
          IntlPhoneField(
            initialCountryCode: 'PT',
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)?.phoneNumberLabelLocal ?? 'Número de Telemóvel',
              border: const OutlineInputBorder(),
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
                child: Text(
                  AppLocalizations.of(context)?.sendCode ?? 'Enviar Código',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
