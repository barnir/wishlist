import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String message = '';

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }

  Future<void> sendPasswordReset() async {
    if (user?.email == null) return;

    try {
      await _auth.sendPasswordResetEmail(email: user!.email!);
      setState(() {
        message = 'Email de redefinição de senha enviado para ${user!.email}';
      });
    } catch (e) {
      setState(() {
        message = 'Erro ao enviar email de redefinição: $e';
      });
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName ?? 'Usuário';
    final email = user?.email ?? 'Sem email';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(displayName),
              subtitle: Text(email),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendPasswordReset,
              child: const Text('Redefinir Senha (via Email)'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: signOut,
              child: const Text('Sair'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  message,
                  style: TextStyle(
                    color: message.startsWith('Erro') ? Colors.red : Colors.green,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
