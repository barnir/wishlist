import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart';
import '../services/firestore_service.dart';

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
  bool _isEditingName = false;
  final _nameController = TextEditingController();
  bool _isPrivate = false;

  bool _isSearchingContacts = false;
  String? _contactsError;
  List<Contact>? _rawContactos;
  List<QueryDocumentSnapshot> _amigosEncontrados = [];

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    
    _loadProfileData();
  }




  String? get userId => FirebaseAuth.instance.currentUser?.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  Future<bool> verificaPermissaoContactos() async {
    var status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
    }
    return status.isGranted;
  }

  Future<void> procurarAmigosPorContactos() async {
    setState(() {
      _isSearchingContacts = true;
      _contactsError = null;
      _rawContactos = null;
      _amigosEncontrados = [];
    });

    try {
      final permissionGranted = await verificaPermissaoContactos();
      if (!permissionGranted) {
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

      final telefones = _rawContactos!
          .expand((c) => c.phones)
          .map((p) => p.normalizedNumber)
          .where((n) => n.isNotEmpty)
          .toList();

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

    try {
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
        verificationFailed: (FirebaseAuthException e) async {
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
    } catch (e) {
      setState(() {
        _erro = 'Erro ao enviar código: $e';
        _isLoading = false;
      });
    }
  }

  void _mostrarDialogoMerge(BuildContext context, PhoneAuthCredential credential) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Número já associado"),
        content: const Text(
            "Este número de telemóvel está associado a outra conta. Deseja fundir os dados desta conta à sua conta atual? Será necessário autenticar na conta antiga."),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text("Fazer merge"),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _realizarMergeDeContas(credential);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _realizarMergeDeContas(PhoneAuthCredential credential) async {
    try {
      // Logout da conta atual
      await FirebaseAuth.instance.signOut();

      // Login na conta antiga com telefone
      UserCredential oldUserCred = await FirebaseAuth.instance.signInWithCredential(credential);
      User? oldUser = oldUserCred.user;
      if (oldUser == null) throw Exception("Falha na autenticação da conta antiga.");

      // Lê dados da conta antiga
      final oldUserData = await _firestore.collection('users').doc(oldUser.uid).get();
      final oldFriends = await _firestore
          .collection('users')
          .doc(oldUser.uid)
          .collection('friends')
          .get();
      final oldWishlists = await _firestore
          .collection('wishlists')
          .where('ownerId', isEqualTo: oldUser.uid)
          .get();

      // Logout da conta antiga
      await FirebaseAuth.instance.signOut();

      // Reautentica com Google para entrar na conta principal
      final newUser = await _reloginGoogle();
      if (newUser == null) throw Exception("Falha na reautenticação da conta principal.");

      // Migra dados para a conta principal
      if (oldUserData.exists) {
        await _firestore.collection('users').doc(newUser.uid).set(
          oldUserData.data()!,
          SetOptions(merge: true),
        );
      }
      for (final f in oldFriends.docs) {
        await _firestore
            .collection('users')
            .doc(newUser.uid)
            .collection('friends')
            .doc(f.id)
            .set(f.data());
      }
      for (final wl in oldWishlists.docs) {
        await wl.reference.update({'ownerId': newUser.uid});
      }

      // Opcional: apagar dados da conta antiga
      await _firestore.collection('users').doc(oldUser.uid).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merge concluído com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer merge: $e')),
      );
    }
  }

Future<User?> _reloginGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      serverClientId: '515293340951-94s0arso1q5uciton05l3mso47709dia.apps.googleusercontent.com',
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null) {
      return null;
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    return userCredential.user;
  } catch (e) {
    return null;
  }
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
      if (e.code == 'credential-already-in-use') {
        final phoneCred = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: _codeController.text.trim(),
        );
        _mostrarDialogoMerge(context, phoneCred);
      } else {
        setState(() {
          _erro = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = e.toString();
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
            IntlPhoneField(
              initialCountryCode: 'PT',
              decoration: const InputDecoration(
                labelText: 'Novo número de telemóvel',
                border: OutlineInputBorder(),
              ),
              onChanged: (phone) {
                _phoneController.text = phone.completeNumber;
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _enviarCodigo,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Enviar Código'),
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
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Verificar Código'),
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

  Future<void> _saveName() async {
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    try {
      await user?.updateDisplayName(_nameController.text.trim());
      await _firestore.collection('users').doc(userId).update({'displayName': _nameController.text.trim()});

      setState(() {
        _isEditingName = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome atualizado com sucesso!')),
      );
    } catch (e) {
      setState(() {
        _erro = 'Erro ao atualizar o nome: $e';
        _isLoading = false;
      });
    }
  }

  Widget _nameSection() {
    String? displayName = user?.displayName;

    if (_isEditingName) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_erro != null) ...[
            Text(_erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Novo nome',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveName,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('Guardar Nome'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(displayName ?? 'Nome não definido',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        TextButton(onPressed: () { setState(() { _isEditingName = true; _nameController.text = displayName ?? ''; }); }, child: const Text("Editar"))
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
                      backgroundImage: user?.photoURL != null
                          ? NetworkImage(user!.photoURL!)
                          : null,
                      child: user?.photoURL == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _nameSection(),
                    const SizedBox(height: 6),
                    Text(user?.email ?? '',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _phoneSection(),
              const SizedBox(height: 30),
                Row(
                children: [
                  const Text('Perfil Privado:'),
                  Switch(
                    
                    value: _isPrivate,
                    
                    onChanged: (bool newValue) {
                      if (!_isLoading) {
                       _savePrivacySetting(newValue);
                      }
                    },
                  ),
                ],
              ),



              ElevatedButton.icon(
                icon: const Icon(Icons.contacts),
                label: const Text('Procurar amigos nos contactos'),
                onPressed: _isSearchingContacts ? null : procurarAmigosPorContactos,
              ),
              if (_isSearchingContacts)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              if (_contactsError != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_contactsError!,
                      style: const TextStyle(color: Colors.red)),
                ),
              if (_amigosEncontrados.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Sugestões de Amigos:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
