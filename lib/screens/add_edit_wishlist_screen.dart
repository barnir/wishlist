import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wishlist_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddEditWishlistScreen extends StatefulWidget {
  final String? wishlistId;
  const AddEditWishlistScreen({super.key, this.wishlistId});

  @override
  State<AddEditWishlistScreen> createState() => _AddEditWishlistScreenState();
}

class _AddEditWishlistScreenState extends State<AddEditWishlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _firestoreService = FirestoreService();

  bool _isPrivate = false;
  bool _isLoading = false;
  File? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.wishlistId != null) {
      _loadWishlistData();
    }
  }

  Future<void> _loadWishlistData() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance.collection('wishlists').doc(widget.wishlistId).get();
      if (doc.exists) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _isPrivate = doc['private'] ?? false;
          _imageUrl = doc['imageUrl'];
        });
      }
    } catch (e) {
      _showError('Erro ao carregar wishlist: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveWishlist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _firestoreService.saveWishlist(
        name: _nameController.text.trim(),
        isPrivate: _isPrivate,
        imageFile: _imageFile,
        imageUrl: _imageUrl,
        wishlistId: widget.wishlistId,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('Erro ao guardar: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.wishlistId == null ? 'Criar Wishlist' : 'Editar Wishlist')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading && widget.wishlistId != null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : _imageUrl != null
                                ? CachedNetworkImageProvider(_imageUrl!)
                                : null,
                        child: _imageFile == null && _imageUrl == null
                            ? const Icon(Icons.add_a_photo, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                          : Text(widget.wishlistId == null ? 'Criar Wishlist' : 'Guardar Alterações'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}