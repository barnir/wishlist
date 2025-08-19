import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
import 'package:wishlist_app/services/image_cache_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wishlist_app/services/web_scraper_service.dart';
import 'package:http/http.dart' as http;

import '../models/category.dart';

class AddEditItemScreen extends StatefulWidget {
  final String? wishlistId;
  final String? itemId;
  final String? name;
  final String? link;

  const AddEditItemScreen({
    super.key,
    this.wishlistId,
    this.itemId,
    this.name,
    this.link,
  });

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseDatabaseService = SupabaseDatabaseService();
  final _webScraperService = WebScraperService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _linkController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _newWishlistNameController;
  String? _selectedCategory;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  Future<File?>? _imageFuture;
  String? _existingImageUrl;

  bool _isSaving = false;
  String? _erro;

  String? _selectedWishlistId;
  List<Map<String, dynamic>> _wishlists = [];
  bool _isLoadingWishlists = false;
  bool _isCreatingWishlist = false;
  bool _showCreateWishlistForm = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _descriptionController = TextEditingController();
    _linkController = TextEditingController(text: widget.link);
    _quantityController = TextEditingController(text: '1');
    _priceController = TextEditingController(text: '0');
    _newWishlistNameController = TextEditingController();
    _selectedCategory = categories.first.name;

    if (widget.itemId != null && widget.wishlistId != null) {
      _loadItemData();
    } else {
      _handleSharedLink();
    }

    if (widget.wishlistId == null) {
      _loadWishlists();
    }
  }

  Future<void> _handleSharedLink() async {
    if (widget.link != null && widget.link!.isNotEmpty) {
      try {
        final scrapedData = await _webScraperService.scrape(widget.link!);
        _nameController.text = scrapedData['title'] ?? '';
        _priceController.text = scrapedData['price'] ?? '0.00';
        final imageUrl = scrapedData['image'];
        if (imageUrl != null && imageUrl.isNotEmpty) {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final tempFile = File(
              '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
            await tempFile.writeAsBytes(response.bodyBytes);
            setState(() {
              _imageBytes = response.bodyBytes;
              _imageFuture = Future.value(tempFile);
            });
          }
        }
      } catch (e) {
        // Handle error silently or show a message
      }
    }
  }

  Future<void> _loadWishlists() async {
    setState(() {
      _isLoadingWishlists = true;
    });
    try {
      final wishlists = await _supabaseDatabaseService
          .getWishlistsForCurrentUser();
      setState(() {
        _wishlists = wishlists;
        if (_wishlists.isNotEmpty) {
          _selectedWishlistId = _wishlists.first['id'];
        }
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar wishlists: $e';
      });
    } finally {
      setState(() {
        _isLoadingWishlists = false;
      });
    }
  }

  Future<void> _createWishlist() async {
    if (_newWishlistNameController.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _isCreatingWishlist = true;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final newWishlist = await _supabaseDatabaseService.saveWishlist(
        name: _newWishlistNameController.text.trim(),
        isPrivate: false, // Default to public for quick add
        userId: userId,
      );
      _newWishlistNameController.clear();
      if (newWishlist != null) {
        // No need to call _loadWishlists() again, just add the new one to the list
        setState(() {
          _wishlists.add(newWishlist);
          _selectedWishlistId = newWishlist['id'];
          _showCreateWishlistForm = false; // Hide the form after creation
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro ao criar wishlist: $e';
      });
    } finally {
      setState(() {
        _isCreatingWishlist = false;
      });
    }
  }

  Future<void> _loadItemData() async {
    setState(() => _isSaving = true);
    try {
      final itemData = await _supabaseDatabaseService.getWishItem(
        widget.wishlistId!,
        itemId: widget.itemId,
      );

      if (itemData != null) {
        _nameController.text = itemData['name'] ?? '';
        _descriptionController.text = itemData['description'] ?? '';
        _linkController.text = itemData['link'] ?? '';
        _priceController.text = (itemData['price'] ?? '0').toString();
        _selectedCategory = itemData['category'] ?? categories.first.name;
        _existingImageUrl = itemData['image_url'];
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
    _newWishlistNameController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final finalWishlistId = widget.wishlistId ?? _selectedWishlistId;
    if (finalWishlistId == null) {
      setState(() {
        _erro = "Por favor, selecione ou crie uma wishlist.";
      });
      return;
    }

    setState(() => _isSaving = true);

    String? finalImageUrl = _existingImageUrl;
    if (_imageBytes != null) {
      setState(() => _isUploading = true);
      try {
        final tempFileForUpload = await File(
          '${(await getTemporaryDirectory()).path}/temp_upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ).writeAsBytes(_imageBytes!);

        await _supabaseDatabaseService.saveWishItem(
          wishlistId: finalWishlistId,
          name: _nameController.text.trim(),
          price:
              double.tryParse(
                _priceController.text.trim().replaceAll(',', '.'),
              ) ??
              0.0,
          category: _selectedCategory!,
          link: _linkController.text.trim(),
          imageFile: tempFileForUpload,
          itemId: widget.itemId,
        );
        if (finalImageUrl != null) {
          await ImageCacheService.putFile(finalImageUrl, _imageBytes!);
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
      await _supabaseDatabaseService.saveWishItem(
        wishlistId: finalWishlistId,
        name: _nameController.text.trim(),
        price:
            double.tryParse(
              _priceController.text.trim().replaceAll(',', '.'),
            ) ??
            0.0,
        category: _selectedCategory!,
        link: _linkController.text.trim(),
        imageUrl: _existingImageUrl,
        itemId: widget.itemId,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
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
                    if (widget.wishlistId == null) ...[
                      if (_isLoadingWishlists)
                        const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_wishlists.isNotEmpty)
                              DropdownButtonFormField<String>(
                                initialValue: _selectedWishlistId,
                                decoration: InputDecoration(
                                  labelText: 'Escolha uma Wishlist',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                ),
                                items: _wishlists.map((wishlist) {
                                  return DropdownMenuItem<String>(
                                    value: wishlist['id'],
                                    child: Text(wishlist['name']),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedWishlistId = newValue;
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Por favor, escolha uma wishlist'
                                    : null,
                              ),
                            if (_wishlists.isEmpty && !_showCreateWishlistForm)
                              Center(
                                child: TextButton(
                                  onPressed: () => setState(
                                    () => _showCreateWishlistForm = true,
                                  ),
                                  child: const Text(
                                    'Nenhuma wishlist encontrada. Crie uma nova.',
                                  ),
                                ),
                              ),
                            if (_showCreateWishlistForm ||
                                (_wishlists.isEmpty && _showCreateWishlistForm))
                              Column(
                                children: [
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _newWishlistNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Nome da nova wishlist',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                    ),
                                    validator: (value) {
                                      if (_showCreateWishlistForm &&
                                          (value == null || value.isEmpty)) {
                                        return 'Insira um nome para a wishlist';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _isCreatingWishlist
                                      ? const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        )
                                      : ElevatedButton(
                                          onPressed: _createWishlist,
                                          child: const Text('Criar Wishlist'),
                                        ),
                                ],
                              ),
                          ],
                        ),
                      const SizedBox(height: 20),
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
                                backgroundImage: imageFile != null
                                    ? FileImage(imageFile)
                                    : null,
                                child: imageFile == null && !_isUploading
                                    ? const Icon(Icons.add_a_photo, size: 50)
                                    : null,
                              );
                            },
                          ),
                          if (_isUploading)
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
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
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Insere o nome do item'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
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
                              decimal: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return null;
                              final n = double.tryParse(
                                value.replaceAll(',', '.'),
                              );
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
