import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
import 'package:wishlist_app/services/image_cache_service.dart';
import 'package:path_provider/path_provider.dart';

import '../models/category.dart';

class AddEditItemScreen extends StatefulWidget {
  final String wishlistId;
  final String? itemId;

  const AddEditItemScreen({
    super.key,
    required this.wishlistId,
    this.itemId,
  });

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseDatabaseService = SupabaseDatabaseService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _linkController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  String? _selectedCategory;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  Future<File?>? _imageFuture;
  String? _existingImageUrl; // Added to store original image URL

  bool _isSaving = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _linkController = TextEditingController();
    _quantityController = TextEditingController(text: '1');
    _priceController = TextEditingController(text: '0');
    _selectedCategory = categories.first.name;

    if (widget.itemId != null) {
      _loadItemData();
    }
  }

  Future<void> _loadItemData() async {
    setState(() => _isSaving = true);
    try {
      final itemData = await _supabaseDatabaseService.getWishItem(widget.wishlistId, itemId: widget.itemId);

      if (itemData != null) {
        _nameController.text = itemData['name'] ?? '';
        _descriptionController.text = itemData['description'] ?? '';
        _linkController.text = itemData['link'] ?? '';
        // Assuming quantity is not directly stored in wish_items table, or needs to be added
        // _quantityController.text = (itemData['quantity'] ?? 1).toString();
        _priceController.text = (itemData['price'] ?? '0').toString();
        _selectedCategory = itemData['category'] ?? categories.first.name;
        _existingImageUrl = itemData['image_url']; // Store original image URL
        if (_existingImageUrl != null) {
          _imageFuture = ImageCacheService.getFile(_existingImageUrl!);
        }
      }
    } catch (e) {
      setState(() => _erro = 'Erro ao carregar item: $e');
    } finally {
      setState(() => _isSaving = false);
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    String? finalImageUrl = _existingImageUrl; // Start with existing URL
    if (_imageBytes != null) {
      setState(() => _isUploading = true);
      try {
        // Create a temporary file from bytes for upload
        final tempFileForUpload = await File('${(await getTemporaryDirectory()).path}/temp_upload_${DateTime.now().millisecondsSinceEpoch}.jpg').writeAsBytes(_imageBytes!); // Import path_provider

        await _supabaseDatabaseService.saveWishItem(
          wishlistId: widget.wishlistId,
          name: _nameController.text.trim(),
          price: double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ?? 0.0,
          category: _selectedCategory!,
          link: _linkController.text.trim(),
          imageFile: tempFileForUpload, // Pass File
          itemId: widget.itemId,
        );
        if (finalImageUrl != null) {
          await ImageCacheService.putFile(finalImageUrl, _imageBytes!); // Cache with new URL
          setState(() {
            _imageFuture = ImageCacheService.getFile(finalImageUrl);
          });
        }
      } catch (e) {
        setState(() => _erro = 'Erro ao carregar imagem: $e');
      } finally {
        setState(() => _isUploading = false);
      }
    } else {
      // If no new image is picked, save without imageBytes, use existing imageUrl
      await _supabaseDatabaseService.saveWishItem(
        wishlistId: widget.wishlistId,
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ?? 0.0,
        category: _selectedCategory!,
        link: _linkController.text.trim(),
        imageUrl: _existingImageUrl, // Pass existing image URL
        itemId: widget.itemId,
      );
    }

    if (!mounted) return; // Check if the widget is still mounted
    Navigator.of(context).pop(true); // Indicate success
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? 'Adicionar Item' : 'Editar Item'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isSaving || _isUploading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (_erro != null) ...[
                      Text(_erro!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                    ],
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
                      decoration: InputDecoration(
                        labelText: 'Nome do Item',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Insere o nome do item'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      items: categories.map((Category category) {
                        return DropdownMenuItem<String>(
                          value: category.name,
                          child: Row(
                            children: [
                              Icon(category.icon),
                              const SizedBox(width: 10),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        labelText: 'Link',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: 'Quantidade',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Insere a quantidade';
                              }
                              final n = int.tryParse(value);
                              if (n == null || n < 1) {
                                return 'Quantidade inválida';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: 'Preço',
                              prefixText: '€ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null; // Price is optional
                              final n = double.tryParse(value.replaceAll(',', '.'));
                              if (n == null || n < 0) return 'Preço inválido';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSaving || _isUploading ? null : _saveItem,
                      child: _isSaving || _isUploading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.itemId == null ? 'Adicionar' : 'Guardar',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}