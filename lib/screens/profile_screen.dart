import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

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

  // Contactos e pesquisa
  bool _isSearchingContacts = false;
  String? _contactsError;
  List<Contact>? _rawContactos;

  // Amigos encontrados no Firestore (dados de utilizadores)
  List<QueryDocumentSnapshot> _amigosEncontrados = [];

  User? get user => FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obter contactos do telefone
  Future<void> procurarAmigosPorContactos() async {
    setState(() {
      _isSearchingContacts = true;
      _contactsError = null;
      _rawContactos = null;
      _amigosEncontrados = [];
    });

    try {
      if (!await FlutterContacts.requestPermission()) {
        setState(() {
          _contactsError = 'Permissão negada';
          _isSearchingContacts = false;
        });
        return;
      }
      final contactos = await FlutterContacts.getContacts(withProperties: true);

      if (contactos.isEmpty) {
        setState(() {
          _contactsError = 'Nenhum contacto encontrado';
          _isSearchingContacts = false;
        });
        return;
      }

      setState(() {
        _rawContactos = contactos.where((c) => c.phones.isNotEmpty).toList();
      });

      // Extrai números normalizados
      final telefones = _rawContactos!
          .expand((c) => c.phones)
          .map((p) => p.normalizedNumber)
          .where((n) => n.isNotEmpty)
          .toList();

      // Firestore suporta máximo 10-30 elementos em whereIn, divide lista em blocos de 10
      const batchSize = 10;
      List<QueryDocumentSnapshot> amigosTemp = [];

      for (var i = 0; i < telefones.length; i += batchSize) {
        var batch = telefones.skip(i).take(batchSize).toList();
        var query = await _firestore
            .collection('users')
            .where('phoneNumber', whereIn: batch)
            .get();

        amigosTemp.addAll(query.docs);
      }

      setState(() {
        _amigosEncontrados = amigosTemp;
        _isSearchingContacts = false;
      });
    } catch (e) {
      setState(() {
        _contactsError = 'Erro ao aceder aos contactos: $e';
        _isSearchingContacts = false;
      });
    }
  }

  // Adiciona amigo na subcoleção do utilizador atual
  Future<void> adicionarAmigo(String amigoId, String nomeAmigo) async {
    if (user == null) return;

    final ref = _firestore.collection('users').doc(user!.uid).collection('friends');

    final existe = await ref.doc(amigoId).get();

    if (!existe.exists) {
      await ref.doc(amigoId).set({
        'nome': nomeAmigo,
        'addedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Adicionado $nomeAmigo aos teus amigos')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Já tens $nomeAmigo nos teus amigos')),
      );
    }
  }

  // Iniciar fluxo de adição/edição do telefone (igual ao código anterior)
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
        child: SingleChildScrollView(
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
              ElevatedButton.icon(
                icon: const Icon(Icons.contacts),
                label: const Text('Procurar amigos nos contactos'),
                onPressed: _isSearchingContacts ? null : procurarAmigosPorContactos,
              ),
              if (_isSearchingContacts) const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
              if (_contactsError != null) Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_contactsError!, style: const TextStyle(color: Colors.red)),
              ),
              if (_amigosEncontrados.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Sugestões de Amigos:', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._amigosEncontrados.map((amigo) {
                  String nome = amigo.get('displayName') ?? 'Sem nome';
                  String telefone = amigo.get('phoneNumber') ?? '';
                  String idAmigo = amigo.id;
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(nome),
                    subtitle: Text(telefone),
                    trailing: TextButton(
                      onPressed: () => adicionarAmigo(idAmigo, nome),
                      child: const Text('Adicionar'),
                    ),
                  );
                })
              ],
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
      ),
    );
  }
}
