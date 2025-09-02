import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mywishstash/widgets/app_snack.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mywishstash/services/auth_service.dart';
import 'package:mywishstash/repositories/wishlist_repository.dart';
import 'package:mywishstash/services/cloudinary_service.dart';
import 'package:mywishstash/services/monitoring_service.dart';
import 'package:mywishstash/services/image_cache_service.dart';
import 'package:mywishstash/services/haptic_service.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/ui_components.dart';
import '../widgets/selectable_image_preview.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';
import 'package:mywishstash/widgets/loading_message.dart';
import 'package:mywishstash/utils/validation_utils.dart';
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
  Uint8List? _imageBytes; // raw bytes for newly picked image
  String? _existingImageUrl; // Added to store original image URL
  String? _localPreviewPath; // local file path for immediate preview (new selection)

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
          // existing image handled via OptimizedCloudinaryImage
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
        _localPreviewPath = tempFile.path; // use new unified preview path
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
        // CREATE FLOW via repository
        final name = ValidationUtils.sanitizeTextInput(_nameController.text);
        final ownerId = _authService.currentUser?.uid;
        if (ownerId == null) throw Exception('Utilizador não autenticado');

        // Create wishlist first without image to get ID
        final newId = await _wishlistRepo.create(
          name: name,
          ownerId: ownerId,
          isPrivate: _isPrivate,
          imageUrl: null,
        );
        if (newId == null) throw Exception('Falha ao criar wishlist');

        // Upload image if selected then update
        if (tempFileForUpload != null) {
          try {
            uploadedImageUrl = await _cloudinaryService.uploadWishlistImage(
              tempFileForUpload,
              newId,
              oldImageUrl: null,
            );
            if (uploadedImageUrl != null) {
              await _wishlistRepo.update(newId, {'image_url': uploadedImageUrl});
              _existingImageUrl = uploadedImageUrl;
              await ImageCacheService.putFile(uploadedImageUrl, _imageBytes!);
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

        await _wishlistRepo.update(id, {
          'name': ValidationUtils.sanitizeTextInput(_nameController.text),
          'is_private': _isPrivate,
          'image_url': uploadedImageUrl ?? _existingImageUrl,
        });

        if (uploadedImageUrl != null) {
          await ImageCacheService.putFile(uploadedImageUrl, _imageBytes!);
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
    AppSnack.show(
      context,
      message,
      type: SnackType.error,
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
      ? const Center(child: LoadingMessage(messageKey: 'loadingWishlist'))
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
                            
                            SelectableImagePreview(
                              existingUrl: _existingImageUrl,
                              localPreviewPath: _localPreviewPath,
                              onTap: _pickImage,
                              isUploading: _isUploading,
                              transformationType: ImageType.wishlistIcon,
                              size: 120,
                              circle: false,
                              borderRadius: UIConstants.radiusL,
                              fallbackIcon: Icon(
                                Icons.add_photo_alternate,
                                size: UIConstants.iconSizeXL,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
