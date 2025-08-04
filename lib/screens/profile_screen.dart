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
    String? phone = user?.phoneNumber;

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
              child: _isLoading ? const CircularProgressIndicator() : const Text('Enviar Código'),
            ),
          ] else ...[
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código SMS',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _verificarCodigo,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Verificar Código'),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.phone, color: phone != null ? Colors.green : Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(phone ?? 'Nenhum número adicionado'),
        ),
        TextButton.icon(
          icon: Icon(phone == null ? Icons.add : Icons.edit),
          label: Text(phone == null ? 'Adicionar' : 'Alterar'),
          onPressed: _startAddPhone,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null ? const Icon(Icons.person, size: 40) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(user?.displayName ?? 'Nome não definido',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(user?.email ?? '',
                      style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _phoneSection(),
            const SizedBox(height: 30),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Terminar sessão'),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
