import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wishlist_app/services/auth_service.dart';
// Migrated from legacy FirebaseDatabaseService to WishlistRepository
import 'package:wishlist_app/repositories/wishlist_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
import 'package:wishlist_app/services/monitoring_service.dart';
import 'package:wishlist_app/services/image_cache_service.dart';
import 'package:wishlist_app/services/haptic_service.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/ui_components.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:wishlist_app/utils/validation_utils.dart';
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
  final _wishlistRepo = WishlistRepository();
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
      final wishlist = await _wishlistRepo.fetchById(widget.wishlistId!);
      if (wishlist != null) {
        setState(() {
          _nameController.text = wishlist.name;
          _isPrivate = wishlist.isPrivate;
          _existingImageUrl = wishlist.imageUrl;
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
        // Direct create via Firestore to obtain ID then update (repository lacks create helper yet)
        final docRef = FirebaseFirestore.instance.collection('wishlists').doc();
        final newId = docRef.id;
        await docRef.set({
          'name': ValidationUtils.sanitizeTextInput(_nameController.text),
          'is_private': _isPrivate,
          'image_url': null,
          'owner_id': _authService.currentUser?.uid,
          'created_at': FieldValue.serverTimestamp(),
        });

        // 2. If we have a new image, upload it then update wishlist
        if (tempFileForUpload != null) {
          try {
            uploadedImageUrl = await _cloudinaryService.uploadWishlistImage(
              tempFileForUpload, 
              newId,
              oldImageUrl: null, // New wishlist, no old image
            );
            if (uploadedImageUrl != null) {
              await docRef.update({'image_url': uploadedImageUrl});
              _existingImageUrl = uploadedImageUrl;
              await ImageCacheService.putFile(uploadedImageUrl, _imageBytes!);
              setState(() {
                _imageFuture = ImageCacheService.getFile(uploadedImageUrl!);
              });
              MonitoringService.logImageUploadSuccess('wishlist', id: newId, bytes: _imageBytes?.length);
            }
          } catch (e) {
            MonitoringService.logImageUploadFail('wishlist', e, id: newId);
            _showError('Imagem criada mas falhou upload: $e');
          }
        }
      } else {
        // UPDATE FLOW
        final id = widget.wishlistId!;

        if (tempFileForUpload != null) {
          // New image selected -> upload first to get secure URL
            try {
              uploadedImageUrl = await _cloudinaryService.uploadWishlistImage(
                tempFileForUpload, 
                id,
                oldImageUrl: _existingImageUrl, // Pass existing image for cleanup
              );
              _existingImageUrl = uploadedImageUrl;
              if (uploadedImageUrl != null) {
                MonitoringService.logImageUploadSuccess('wishlist', id: id, bytes: _imageBytes?.length);
              }
            } catch (e) {
              MonitoringService.logImageUploadFail('wishlist', e, id: id);
              _showError('Falha upload imagem: $e');
            }
        }

        await FirebaseFirestore.instance.collection('wishlists').doc(id).update({
          'name': ValidationUtils.sanitizeTextInput(_nameController.text),
          'is_private': _isPrivate,
          'image_url': uploadedImageUrl ?? _existingImageUrl,
          'updated_at': FieldValue.serverTimestamp(),
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
    title: widget.wishlistId == null
    ? (AppLocalizations.of(context)?.createWishlistTitle ?? 'Criar Wishlist')
    : (AppLocalizations.of(context)?.editWishlistTitle ?? 'Editar Wishlist'),
  ),
      body: _isLoading && widget.wishlistId != null
          ? WishlistLoadingIndicator(
              message: AppLocalizations.of(context)?.loadingWishlist ?? 'A carregar wishlist...',
            )
          : SingleChildScrollView(
              padding: UIConstants.paddingM,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    Text(
                      AppLocalizations.of(context)?.wishlistDetailsSection ?? 'Detalhes da Wishlist',
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
                              AppLocalizations.of(context)?.wishlistImageSection ?? 'Imagem da Wishlist',
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
                                                      AppLocalizations.of(context)?.tapToAdd ?? 'Toca para adicionar',
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
                                              AppLocalizations.of(context)?.processingImage ?? 'A processar...',
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
                              AppLocalizations.of(context)?.recommendedImageSize ?? 'Recomendado: 400x400px ou superior',
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
                      label: AppLocalizations.of(context)?.wishlistNameLabel ?? 'Nome da Wishlist',
                      hint: AppLocalizations.of(context)?.wishlistNameHint ?? 'Digite o nome da sua wishlist',
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.card_giftcard),
                      validator: (value) => ValidationUtils.validateWishlistName(value, context),
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
                                AppLocalizations.of(context)?.privacySectionTitle ?? 'Privacidade',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          
                          Spacing.s,
                          
                          SwitchListTile(
                            title: Text(
                              AppLocalizations.of(context)?.privateWishlist ?? 'Wishlist Privada',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            subtitle: Text(
                              _isPrivate
                                  ? (AppLocalizations.of(context)?.privateWishlistSubtitle ?? 'Apenas tu podes ver esta wishlist')
                                  : (AppLocalizations.of(context)?.publicWishlistSubtitle ?? 'Outros utilizadores podem ver esta wishlist'),
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
                          ? (AppLocalizations.of(context)?.createWishlistTitle ?? 'Criar Wishlist')
                          : (AppLocalizations.of(context)?.saveChanges ?? 'Guardar Alterações'),
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
