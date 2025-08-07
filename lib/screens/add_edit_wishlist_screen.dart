import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditWishlistScreen extends StatefulWidget {
  const AddEditWishlistScreen({Key? key}) : super(key: key);

  @override
  State<AddEditWishlistScreen> createState() => _AddEditWishlistScreenState();
}

class _AddEditWishlistScreenState extends State<AddEditWishlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isPrivate = false;
  bool _isLoading = false;
  String? _erro;

  Future<void> _saveWishlist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('wishlists').add({
        'name': _nameController.text.trim(),
        'ownerId': userId,
        'private': _isPrivate,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.of(context).pop(true); // Indicate success
    } catch (e) {
      setState(() => _erro = 'Erro ao guardar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Wishlist')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_erro != null) ...[
                Text(_erro!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome da Wishlist'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Insere um nome'
                        : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Privada:'),
                  Switch(
                    value: _isPrivate,
                    onChanged: (newValue) =>
                        setState(() => _isPrivate = newValue),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveWishlist,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Criar Wishlist'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
