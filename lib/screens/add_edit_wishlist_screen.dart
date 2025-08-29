import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/firebase_database_service.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
import 'package:wishlist_app/services/image_cache_service.dart';
import 'package:wishlist_app/services/haptic_service.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';

class AddEditWishlistScreen extends StatefulWidget {
  final String? wishlistId;
  const AddEditWishlistScreen({super.key, this.wishlistId});

  @override
  State<AddEditWishlistScreen> createState() => _AddEditWishlistScreenState();
}

class _AddEditWishlistScreenState extends State<AddEditWishlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  final _databaseService = FirebaseDatabaseService();
  final _cloudinaryService = CloudinaryService();

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
      final wishlistData = await _databaseService.getWishlist(
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
    HapticService.lightImpact();
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

    File? tempFileForUpload;
    String? uploadedImageUrl;

    try {
      // If user picked a new image, persist it temporarily to upload
      if (_imageBytes != null) {
        setState(() => _isUploading = true);
        tempFileForUpload = await File(
          '${(await getTemporaryDirectory()).path}/temp_upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ).writeAsBytes(_imageBytes!);
      }

      if (widget.wishlistId == null) {
        // CREATE FLOW
        // 1. Create wishlist without image (so we get Firestore ID)
        final created = await _databaseService.saveWishlist({
          'name': _nameController.text.trim(),
          'is_private': _isPrivate,
          'image_url': null, // placeholder, updated after upload
          'user_id': _authService.currentUser?.uid,
        });

        final newId = created['id'] as String;

        // 2. If we have a new image, upload it then update wishlist
        if (tempFileForUpload != null) {
          try {
            uploadedImageUrl = await _cloudinaryService.uploadWishlistImage(tempFileForUpload, newId);
            if (uploadedImageUrl != null) {
              await _databaseService.updateWishlist(newId, {
                'image_url': uploadedImageUrl,
              });
              _existingImageUrl = uploadedImageUrl;
              await ImageCacheService.putFile(uploadedImageUrl, _imageBytes!);
              setState(() {
                _imageFuture = ImageCacheService.getFile(uploadedImageUrl!);
              });
            }
          } catch (e) {
            _showError('Imagem criada mas falhou upload: $e');
          }
        }
      } else {
        // UPDATE FLOW
        final id = widget.wishlistId!;

        if (tempFileForUpload != null) {
          // New image selected -> upload first to get secure URL
            try {
              uploadedImageUrl = await _cloudinaryService.uploadWishlistImage(tempFileForUpload, id);
              _existingImageUrl = uploadedImageUrl;
            } catch (e) {
              _showError('Falha upload imagem: $e');
            }
        }

        await _databaseService.updateWishlist(id, {
          'name': _nameController.text.trim(),
          'is_private': _isPrivate,
          'image_url': uploadedImageUrl ?? _existingImageUrl,
        });

        if (uploadedImageUrl != null) {
          await ImageCacheService.putFile(uploadedImageUrl, _imageBytes!);
          setState(() {
            _imageFuture = ImageCacheService.getFile(uploadedImageUrl!);
          });
        }
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
      appBar: WishlistAppBar(
        title: widget.wishlistId == null ? 'Criar Wishlist' : 'Editar Wishlist',
      ),
      body: _isLoading && widget.wishlistId != null
          ? const WishlistLoadingIndicator(message: 'A carregar wishlist...')
          : SingleChildScrollView(
              padding: UIConstants.paddingM,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    Text(
                      'Detalhes da Wishlist',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    Spacing.m,
                    
                    // Image picker section - modernizado
                    Center(
                      child: WishlistCard(
                        child: Column(
                          children: [
                            Text(
                              'Imagem da Wishlist',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            
                            Spacing.m,
                            
                            GestureDetector(
                              onTap: _isUploading ? null : _pickImage,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(UIConstants.radiusL),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline,
                                        width: 2,
                                        style: BorderStyle.solid,
                                      ),
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    ),
                                    child: FutureBuilder<File?>(
                                      future: _imageFuture,
                                      builder: (context, snapshot) {
                                        final imageFile = snapshot.data;
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(UIConstants.radiusL - 2),
                                          child: imageFile != null
                                              ? Image.file(
                                                  imageFile,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                )
                                              : Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_photo_alternate,
                                                      size: UIConstants.iconSizeXL,
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                                    Spacing.s,
                                                    Text(
                                                      'Toca para adicionar',
                                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (_isUploading)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface.withAlpha(204),
                                        borderRadius: BorderRadius.circular(UIConstants.radiusL),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircularProgressIndicator(
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            Spacing.s,
                                            Text(
                                              'A processar...',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            
                            Spacing.s,
                            
                            Text(
                              'Recomendado: 400x400px ou superior',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    Spacing.l,
                    
                    // Form fields section
                    WishlistTextField(
                      label: 'Nome da Wishlist',
                      hint: 'Digite o nome da sua wishlist',
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.card_giftcard),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Insere um nome'
                          : null,
                    ),
                    
                    Spacing.l,
                    
                    // Privacy settings
                    WishlistCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                size: UIConstants.iconSizeM,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              Spacing.horizontalS,
                              Text(
                                'Privacidade',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          
                          Spacing.s,
                          
                          SwitchListTile(
                            title: Text(
                              'Wishlist Privada',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            subtitle: Text(
                              _isPrivate 
                                ? 'Apenas tu podes ver esta wishlist'
                                : 'Outros utilizadores podem ver esta wishlist',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            value: _isPrivate,
                            onChanged: (newValue) {
                              HapticService.lightImpact();
                              setState(() => _isPrivate = newValue);
                            },
                            secondary: Icon(
                              _isPrivate ? Icons.lock : Icons.public,
                              color: _isPrivate 
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    
                    Spacing.xl,
                    
                    // Save button
                    WishlistButton(
                      text: widget.wishlistId == null
                          ? 'Criar Wishlist'
                          : 'Guardar Alterações',
                      onPressed: _isLoading || _isUploading ? null : _saveWishlist,
                      isLoading: _isLoading || _isUploading,
                      icon: widget.wishlistId == null ? Icons.add : Icons.save,
                      width: double.infinity,
                    ),
                    
                    Spacing.l,
                  ],
                ),
              ),
            ),
    );
  }
}
