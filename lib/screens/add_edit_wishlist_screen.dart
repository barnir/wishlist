import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditWishlistScreen extends StatefulWidget {
  final String? wishlistId;
  const AddEditWishlistScreen({super.key, this.wishlistId});
  

  @override
  State<AddEditWishlistScreen> createState() => _AddEditWishlistScreenState();
}

class _AddEditWishlistScreenState extends State<AddEditWishlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isPrivate = false;
  bool _isLoading = false;
  String? _erro;
  String? _wishlistId;

  @override
  void initState() {
    super.initState();
    _wishlistId = widget.wishlistId;
    if (_wishlistId != null) {
      _loadWishlistData();
    }
  }

  Future<void> _loadWishlistData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('wishlists').doc(_wishlistId).get();
      if (doc.exists) {
        _nameController.text = doc['name'] ?? '';
        _isPrivate = doc['private'] ?? false;
      }
    } catch (e) {
      setState(() => _erro = 'Erro ao carregar wishlist: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWishlist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final data = {
        'name': _nameController.text.trim(),
        'ownerId': userId,
        'private': _isPrivate,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_wishlistId == null) {
        await FirebaseFirestore.instance.collection('wishlists').add(data);
      } else {
        await FirebaseFirestore.instance.collection('wishlists').doc(_wishlistId).update(data);
      }

      if (!mounted) return; // Check if the widget is still mounted
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
      appBar: AppBar(title: Text(_wishlistId == null ? 'Criar Wishlist' : 'Editar Wishlist')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading && _wishlistId != null
            ? const Center(child: CircularProgressIndicator())
            : Form(
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
                          : Text(_wishlistId == null ? 'Criar Wishlist' : 'Guardar Alterações'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
