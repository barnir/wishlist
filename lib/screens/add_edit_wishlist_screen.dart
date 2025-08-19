import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
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
  final _supabaseDatabaseService = SupabaseDatabaseService();

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
      final wishlistData = await _supabaseDatabaseService.getWishlist(
        widget.wishlistId!,
      );
      if (wishlistData != null) {
        setState(() {
          _nameController.text = wishlistData['name'] ?? '';
          _isPrivate = wishlistData['is_private'] ?? false;
          _existingImageUrl =
              wishlistData['image_url']; // Store original image URL
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
    File? tempFileForUpload;

    try {
      if (_imageBytes != null) {
        setState(() => _isUploading = true);
        // Create a temporary file from bytes for upload
        tempFileForUpload = await File(
          '${(await getTemporaryDirectory()).path}/temp_upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ).writeAsBytes(_imageBytes!);
      }

      await _supabaseDatabaseService.saveWishlist(
        name: _nameController.text.trim(),
        isPrivate: _isPrivate,
        imageFile: tempFileForUpload, // Pass File if available
        imageUrl: _imageBytes == null
            ? _existingImageUrl
            : null, // Pass existing URL only if no new image
        wishlistId: widget.wishlistId,
      );

      if (finalImageUrl != null && _imageBytes != null) {
        // Only cache if a new image was uploaded
        await ImageCacheService.putFile(finalImageUrl, _imageBytes!);
        setState(() {
          _imageFuture = ImageCacheService.getFile(finalImageUrl);
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('Erro ao salvar wishlist: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
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
      appBar: AppBar(
        title: Text(
          widget.wishlistId == null ? 'Criar Wishlist' : 'Editar Wishlist',
        ),
      ),
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
                                backgroundImage: imageFile != null
                                    ? FileImage(imageFile)
                                    : null,
                                child: imageFile == null && !_isUploading
                                    ? const Icon(Icons.add_a_photo, size: 50)
                                    : null,
                              );
                            },
                          ),
                          if (_isUploading) const CircularProgressIndicator(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Wishlist',
                        border: OutlineInputBorder(),
                      ),
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading || _isUploading
                          ? null
                          : _saveWishlist,
                      child: _isLoading || _isUploading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                          : Text(
                              widget.wishlistId == null
                                  ? 'Criar Wishlist'
                                  : 'Guardar Alterações',
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
