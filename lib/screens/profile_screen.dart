import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditingPhone = false;
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;
  bool _isLoading = false;
  String? _erro;

  User? get user => FirebaseAuth.instance.currentUser;

  // Iniciar fluxo de adição/edição do telefone
  Future<void> _startAddPhone() async {
    setState(() {
      _isEditingPhone = true;
      _erro = null;
      _codeSent = false;
      _phoneController.clear();
      _codeController.clear();
    });
  }

  Future<void> _enviarCodigo() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneController.text.trim(),
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await user?.linkWithCredential(credential);
        setState(() {
          _isEditingPhone = false;
          _codeSent = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Telefone adicionado ao perfil!')),
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _erro = e.message;
          _isLoading = false;
        });
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _verificarCodigo() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      await user?.linkWithCredential(credential);
      setState(() {
        _isEditingPhone = false;
        _codeSent = false;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telefone adicionado ao perfil!')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _erro = e.message;
        _isLoading = false;
      });
    }
  }

  Widget _phoneSection() {
    final phone = user?.phoneNumber;

    if (_isEditingPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_erro != null) ...[
            Text(_erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          if (!_codeSent) ...[
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Novo número de telemóvel (+351...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _enviarCodigo,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text
                  : const Text
