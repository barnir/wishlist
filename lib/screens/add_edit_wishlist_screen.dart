import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

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
  File? _imageFile;
  String? _imageUrl;

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
        _imageUrl = doc['imageUrl'];
      }
    } catch (e) {
      setState(() => _erro = 'Erro ao carregar wishlist: $e');
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

  Future<String?> _uploadImage(String wishlistId) async {
    if (_imageFile == null) return null;

    final url = Uri.parse('https://api.cloudinary.com/v1_1/dqwh1uk68/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = 'wishlists_img'
      ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = json.decode(responseString);
        return jsonMap['secure_url'];
      } else {
        setState(() {
          _erro = 'Erro ao carregar imagem: ${response.reasonPhrase}';
        });
        return null;
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar imagem: $e';
      });
      return null;
    }
  }

  Future<void> _saveWishlist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      String? imageUrl = _imageUrl;

      if (_wishlistId == null) {
        final newWishlistRef = FirebaseFirestore.instance.collection('wishlists').doc();
        _wishlistId = newWishlistRef.id;
        if (_imageFile != null) {
          imageUrl = await _uploadImage(_wishlistId!);
        }
        await newWishlistRef.set({
          'name': _nameController.text.trim(),
          'ownerId': userId,
          'private': _isPrivate,
          'createdAt': FieldValue.serverTimestamp(),
          'imageUrl': imageUrl,
        });
      } else {
        if (_imageFile != null) {
          imageUrl = await _uploadImage(_wishlistId!);
        }
        await FirebaseFirestore.instance.collection('wishlists').doc(_wishlistId).update({
          'name': _nameController.text.trim(),
          'private': _isPrivate,
          'imageUrl': imageUrl,
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
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
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : _imageUrl != null
                                ? NetworkImage(_imageUrl!)
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
                          : Text(_wishlistId == null ? 'Criar Wishlist' : 'Guardar Alterações'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
