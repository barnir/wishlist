import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wishlist_app/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/services/image_cache_service.dart';
import 'package:path_provider/path_provider.dart';

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
  bool _isUploading = false;
  Uint8List? _imageBytes;
  Future<File?>? _imageFuture;
  String? _existingImageUrl; // Added to store original image URL

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
          _existingImageUrl = doc['imageUrl']; // Store original image URL
          if (_existingImageUrl != null) {
            _imageFuture = ImageCacheService.getFile(_existingImageUrl!);
          }
        });
      }
    } catch (e) {
      _showError('Erro ao carregar wishlist: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      final tempFile = File(pickedFile.path);
      setState(() {
        _imageBytes = imageBytes;
        _imageFuture = Future.value(tempFile);
      });
    }
  }

  Future<void> _saveWishlist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? finalImageUrl = _existingImageUrl; // Start with existing URL
    if (_imageBytes != null) {
      setState(() => _isUploading = true);
      try {
        // Create a temporary file from bytes for upload
        final tempFileForUpload = await File('${(await getTemporaryDirectory()).path}/temp_upload_${DateTime.now().millisecondsSinceEpoch}.jpg').writeAsBytes(_imageBytes!); // Import path_provider

        await _firestoreService.saveWishlist(
          name: _nameController.text.trim(),
          isPrivate: _isPrivate,
          imageFile: tempFileForUpload, // Pass File
          wishlistId: widget.wishlistId,
        );
        if (finalImageUrl != null) {
          await ImageCacheService.putFile(finalImageUrl, _imageBytes!); // Cache with new URL
          setState(() {
            _imageFuture = ImageCacheService.getFile(finalImageUrl);
          });
        }
      } catch (e) {
        _showError('Erro ao carregar imagem: $e');
      } finally {
        setState(() => _isUploading = false);
      }
    } else {
      // If no new image is picked, save without imageBytes, use existing imageUrl
      await _firestoreService.saveWishlist(
        name: _nameController.text.trim(),
        isPrivate: _isPrivate,
        imageUrl: _existingImageUrl, // Pass existing image URL
        wishlistId: widget.wishlistId,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
    if (mounted) {
      setState(() => _isLoading = false);
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
                      onTap: _isUploading ? null : _pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          FutureBuilder<File?>(
                            future: _imageFuture,
                            builder: (context, snapshot) {
                              final imageFile = snapshot.data;
                              return CircleAvatar(
                                radius: 50,
                                backgroundImage: imageFile != null ? FileImage(imageFile) : null,
                                child: imageFile == null && !_isUploading
                                    ? const Icon(Icons.add_a_photo, size: 50)
                                    : null,
                              );
                            },
                          ),
                          if (_isUploading)
                            const CircularProgressIndicator(),
                        ],
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
                      onPressed: _isLoading || _isUploading ? null : _saveWishlist,
                      child: _isLoading || _isUploading
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
