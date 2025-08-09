import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:google_sign_in/google_sign_in.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  User? get user => FirebaseAuth.instance.currentUser;
  String? get userId => user?.uid;

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

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (userId == null) return;
    final userData = await _firestore.collection('users').doc(userId).get();
    if (userData.exists) {
      if (!mounted) return;
      setState(() {
        _nameController.text = userData.data()?['displayName'] ?? '';
        _isPrivate = userData.data()?['isPrivate'] ?? false;
      });
    }
  }

  Future<void> _savePrivacySetting(bool newValue) async {
    if (userId == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'isPrivate': newValue});
      if (!mounted) return;
      setState(() {
        _isPrivate = newValue;
        _isLoading = false;
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: Text(
                'Definição de privacidade atualizada para ${newValue ? 'Privado' : 'Público'}!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao atualizar a privacidade: $e';
        _isLoading = false;
      });
    }
  }

  Future<bool> verificaPermissaoContactos() async {
    final status = await Permission.contacts.status;
    if (!status.isGranted) {
      await Permission.contacts.request();
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
        if (!mounted) return;
        setState(() {
          _contactsError = 'Permissão negada';
          _isSearchingContacts = false;
        });
        return;
      }

      final contactos =
          await FlutterContacts.getContacts(withProperties: true);
      if (contactos.isEmpty) {
        if (!mounted) return;
        setState(() {
          _contactsError = 'Nenhum contacto encontrado';
          _isSearchingContacts = false;
        });
        return;
      }

      if (!mounted) return;
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

      if (!mounted) return;
      setState(() {
        _amigosEncontrados = amigosTemp;
        _isSearchingContacts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contactsError = 'Erro ao aceder aos contactos: $e';
        _isSearchingContacts = false;
      });
    }
  }

  Future<void> adicionarAmigo(String amigoId, String nomeAmigo) async {
    if (user == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final ref =
        _firestore.collection('users').doc(user!.uid).collection('friends');
    final existe = await ref.doc(amigoId).get();

    if (!mounted) return;
    if (!existe.exists) {
      await ref.doc(amigoId).set({
        'nome': nomeAmigo,
        'addedAt': FieldValue.serverTimestamp(),
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Adicionado $nomeAmigo aos teus amigos')),
      );
    } else {
      scaffoldMessenger.showSnackBar(
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
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
          if (!mounted) return;
          setState(() {
            _isEditingPhone = false;
            _codeSent = false;
            _isLoading = false;
          });
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Telefone adicionado ao perfil!')),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            _erro = e.message;
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao enviar código: $e';
        _isLoading = false;
      });
    }
  }

  void _mostrarDialogoMerge(
      BuildContext context, PhoneAuthCredential credential) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Número já associado"),
        content: const Text(
            "Este número de telemóvel está associado a outra conta. Deseja fundir os dados desta conta à sua conta atual? Será necessário reautenticar com o seu método de login original."),
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

  Future<User?> _reauthenticateUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    for (final provider in currentUser.providerData) {
      if (provider.providerId == GoogleAuthProvider.PROVIDER_ID) {
        final googleUser = await googleSignIn.authenticate();
        if (googleUser == null) return null;
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        await currentUser.reauthenticateWithCredential(credential);
        return FirebaseAuth.instance.currentUser;
      } else if (provider.providerId == EmailAuthProvider.PROVIDER_ID) {
        if (!mounted) return null;
        final password = await _askForPassword();
        if (password == null) return null;
        if (!mounted) return null;
        final credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: password,
        );
        await currentUser.reauthenticateWithCredential(credential);
        return FirebaseAuth.instance.currentUser;
      }
    }
    return null;
  }

  Future<String?> _askForPassword() async {
    String? password;
    await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final passwordController = TextEditingController();
        return AlertDialog(
          title: const Text('Reautenticação Necessária'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Confirmar'),
              onPressed: () {
                password = passwordController.text;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return password;
  }

  Future<void> _realizarMergeDeContas(PhoneAuthCredential credential) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseAuth.instance.signOut();

      final oldUserCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final oldUser = oldUserCred.user;
      if (oldUser == null) {
        throw Exception("Falha na autenticação da conta antiga.");
      }

      final oldUserData =
          await _firestore.collection('users').doc(oldUser.uid).get();
      final oldFriends = await _firestore
          .collection('users')
          .doc(oldUser.uid)
          .collection('friends')
          .get();
      final oldWishlists = await _firestore
          .collection('wishlists')
          .where('ownerId', isEqualTo: oldUser.uid)
          .get();

      await FirebaseAuth.instance.signOut();

      final newUser = await _reauthenticateUser();
      if (newUser == null) {
        throw Exception("Falha na reautenticação da conta principal.");
      }

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

      await _firestore.collection('users').doc(oldUser.uid).delete();

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Merge concluído com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro ao fazer merge: $e')),
      );
    }
  }

  Future<void> _verificarCodigo() async {
    if (_verificationId == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localContext = context;

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
      if (!mounted) return;
      setState(() {
        _isEditingPhone = false;
        _codeSent = false;
        _isLoading = false;
      });
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Telefone adicionado ao perfil!')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'credential-already-in-use') {
        final phoneCred = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: _codeController.text.trim(),
        );
        _mostrarDialogoMerge(localContext, phoneCred);
      } else {
        setState(() {
          _erro = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
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
        Icon(Icons.phone,
            color: phone != null && phone.isNotEmpty ? Colors.green : Colors.grey),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
              phone != null && phone.isNotEmpty ? phone : 'Nenhum número adicionado'),
        ),
        TextButton.icon(
          icon: Icon(phone == null || phone.isEmpty ? Icons.add : Icons.edit),
          label: Text(phone == null || phone.isEmpty ? 'Adicionar' : 'Alterar'),
          onPressed: _startAddPhone,
        ),
      ],
    );
  }

  Future<void> _saveName() async {
    if (userId == null) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    try {
      await user?.updateDisplayName(_nameController.text.trim());
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'displayName': _nameController.text.trim()});

      if (!mounted) return;
      setState(() {
        _isEditingName = false;
        _isLoading = false;
      });

      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Nome atualizado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao atualizar o nome: $e';
        _isLoading = false;
      });
    }
  }

  Widget _nameSection() {
    final displayName = user?.displayName;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () {
                    setState(() {
                      _isEditingName = false;
                    });
                  },
                  child: const Text('Cancelar')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveName,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Guardar'),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(displayName ?? 'Nome não definido',
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        TextButton(
            onPressed: () {
              setState(() {
                _isEditingName = true;
                _nameController.text = displayName ?? '';
              });
            },
            child: const Text("Editar"))
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
                        style:
                            TextStyle(color: Colors.grey[700], fontSize: 16)),
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.contacts),
                label: const Text('Procurar amigos nos contactos'),
                onPressed:
                    _isSearchingContacts ? null : procurarAmigosPorContactos,
              ),
              if (_isSearchingContacts)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
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
                  final nome = amigo.get('displayName') ?? 'Sem nome';
                  final telefone = amigo.get('phoneNumber') ?? '';
                  final idAmigo = amigo.id;
                  return ListTile(
                    leading: const Icon(Icons.person_add_alt_1),
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
                  final navigator = Navigator.of(context);
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  navigator.pushReplacementNamed('/login');
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.person_remove),
                label: const Text('Eliminar Conta'),
                onPressed: () => _confirmDeleteAccount(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmController = TextEditingController();
    final passwordController = TextEditingController();
    final currentProviderId = user?.providerData.first.providerId;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final navigator = Navigator.of(dialogContext);
        return AlertDialog(
          title: const Text('Eliminar Conta'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text(
                    'Esta ação é irreversível e eliminará todos os seus dados.'),
                const SizedBox(height: 10),
                if (currentProviderId == EmailAuthProvider.PROVIDER_ID) ...[
                  const Text(
                      'Por favor, insira a sua password para confirmar:'),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 10),
                ],
                const Text('Para confirmar, escreva "SIM" na caixa abaixo:'),
                TextField(
                  controller: confirmController,
                  decoration: const InputDecoration(hintText: 'SIM'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                navigator.pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
              onPressed: () async {
                if (confirmController.text == 'SIM') {
                  navigator.pop();
                  await _deleteAccount(passwordController.text);
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                        content: Text('Confirmação inválida. Escreva SIM.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(String? password) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _isLoading = true;
      _erro = null;
    });
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Reauthenticate if necessary
      if (currentUser.providerData.first.providerId ==
          EmailAuthProvider.PROVIDER_ID) {
        if (password == null || password.isEmpty) {
          throw FirebaseAuthException(
              code: 'no-password',
              message: 'Password é necessária para reautenticação.');
        }
        final credential = EmailAuthProvider.credential(
            email: currentUser.email!, password: password);
        await currentUser.reauthenticateWithCredential(credential);
      } else if (currentUser.providerData.first.providerId ==
          GoogleAuthProvider.PROVIDER_ID) {
        final googleUser = await googleSignIn.authenticate();
        if (googleUser == null) {
          throw FirebaseAuthException(
              code: 'google-sign-in-cancelled',
              message: 'Login com o Google cancelado.');
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        await currentUser.reauthenticateWithCredential(credential);
      }

      // Delete user data from Firestore
      await _firestore.collection('users').doc(currentUser.uid).delete();
      final userWishlists = await _firestore
          .collection('wishlists')
          .where('ownerId', isEqualTo: currentUser.uid)
          .get();
      for (final wishlistDoc in userWishlists.docs) {
        final items =
            await wishlistDoc.reference.collection('items').get();
        for (final itemDoc in items.docs) {
          await itemDoc.reference.delete();
        }
        await wishlistDoc.reference.delete();
      }

      // Delete the user account
      await currentUser.delete();

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Conta eliminada com sucesso!')),
      );
      navigator.pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro ao eliminar conta: $e';
        _isLoading = false;
      });
    }
  }
}
