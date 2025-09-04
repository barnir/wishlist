import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mywishstash/repositories/wish_item_repository.dart';
import 'package:mywishstash/repositories/wishlist_repository.dart';
import 'package:mywishstash/models/wishlist.dart';
import 'package:mywishstash/services/cloudinary_service.dart' as cloudinary_service;
import 'package:mywishstash/services/monitoring_service.dart';
import 'package:mywishstash/services/image_cache_service.dart';
import 'package:mywishstash/services/web_scraper_service.dart';
import 'package:mywishstash/services/share_enrichment_service.dart';
import 'package:mywishstash/services/auth_service.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';
import 'package:mywishstash/utils/validation_utils.dart';
import 'package:mywishstash/utils/performance_utils.dart';
import 'package:mywishstash/widgets/status_chip.dart';
import '../models/category.dart';
import 'package:mywishstash/services/category_usage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../widgets/selectable_image_preview.dart';
import 'package:mywishstash/widgets/skeleton_loader.dart';
class AddEditItemScreen extends StatefulWidget {
  final String? wishlistId;
  final String? itemId;
  final String? name;
  final String? link;

  const AddEditItemScreen({super.key, this.wishlistId, this.itemId, this.name, this.link});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> with PerformanceOptimizedState {
  final _formKey = GlobalKey<FormState>();
  final _wishItemRepo = WishItemRepository();
  final _wishlistRepo = WishlistRepository();
  final _webScraperService = WebScraperServiceSecure();
  final _shareService = ShareEnrichmentService();
  final _cloudinaryService = cloudinary_service.CloudinaryService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _linkController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _newWishlistNameController;
  String? _selectedCategory;
  double? _rating;
  Uint8List? _imageBytes;
  bool _isUploading = false;
  String? _existingImageUrl;
  String? _localPreviewPath;

  bool _isSaving = false;
  bool _isScraping = false;
  String? _scrapingStatus;
  String? _erro;

  String? _selectedWishlistId;
  List<Wishlist> _wishlists = [];
  bool _isLoadingWishlists = false;
  bool _isCreatingWishlist = false;
  bool _pendingEnrichment = false;
  String? _enrichmentCacheId;

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
    if (widget.wishlistId == null && widget.link != null) {
      _loadWishlists();
    }
  }

  Future<void> _handleSharedLink() async {
    if (widget.link == null || widget.link!.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    safeSetState(() {
      _isScraping = true;
      _scrapingStatus = l10n?.scrapingExtractingInfo;
    });
    try {
      final shareResult = await _shareService.processSharedText(widget.link!);
      final initial = shareResult.initial;
      if (!mounted) return;
      if (initial.url != null) {
        _pendingEnrichment = true;
        _enrichmentCacheId = null;
      }
      if (initial.title != null && initial.title!.isNotEmpty && _nameController.text.isEmpty) {
        _nameController.text = initial.title!;
      }
      if (initial.price != null) {
        _priceController.text = initial.price!;
      }
      final enrichmentFuture = shareResult.enrichmentFuture;
      if (enrichmentFuture != null) {
        enrichmentFuture.then((data) async {
          if (!mounted) return;
          final cacheId = data['cacheId'] as String?;
          if (cacheId != null && cacheId.isNotEmpty) {
            _enrichmentCacheId = cacheId;
          }
          if (data['rateLimited'] == true) {
            safeSetState(() {
              _scrapingStatus = AppLocalizations.of(context)?.enrichmentRateLimited;
              _pendingEnrichment = false;
            });
            return;
          }
            if (_nameController.text.isEmpty && (data['title'] as String?)?.isNotEmpty == true) {
              _nameController.text = data['title'];
            }
            final priceNum = data['price'];
            if (priceNum is num && (double.tryParse(_priceController.text) ?? 0) == 0) {
              _priceController.text = priceNum.toStringAsFixed(2);
            }
            final ratingVal = data['ratingValue'];
            if (ratingVal is num && (_rating == null || _rating == 0)) {
              _rating = ratingVal.toDouble().clamp(0.0, 5.0);
            }
            final suggestedCat = data['categorySuggestion'] as String?;
            if (suggestedCat != null && suggestedCat.isNotEmpty && _selectedCategory == categories.first.name) {
              if (categories.any((c) => c.name == suggestedCat)) {
                _selectedCategory = suggestedCat;
              }
            }
            final img = data['image'] as String?;
            if (img != null && img.isNotEmpty && _imageBytes == null && _existingImageUrl == null) {
              try {
                safeSetState(()=> _scrapingStatus = l10n?.scrapingLoadingImage);
                final response = await http.get(Uri.parse(img));
                if (response.statusCode == 200) {
                  final tempDir = await getTemporaryDirectory();
                  final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
                  await tempFile.writeAsBytes(response.bodyBytes);
                  if (mounted) {
                    safeSetState(() {
                      _imageBytes = response.bodyBytes;
                      _localPreviewPath = tempFile.path;
                    });
                  }
                }
              } catch (_) {}
            }
            safeSetState(() {
              _scrapingStatus = AppLocalizations.of(context)?.enrichmentCompleted;
              _pendingEnrichment = false;
            });
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _scrapingStatus == AppLocalizations.of(context)?.enrichmentCompleted) {
                safeSetState(() => _scrapingStatus = null);
              }
            });
        });
      }
      safeSetState(() {
        _scrapingStatus = l10n?.scrapingFillingFields ?? AppLocalizations.of(context)?.enrichmentPending;
      });
      if (enrichmentFuture != null) {
        enrichmentFuture.catchError((_) async {
          if (!mounted) return <String, dynamic>{};
          if (_nameController.text.isEmpty) {
            try {
              final scrapedData = await _webScraperService.scrape(widget.link!);
              if (mounted && scrapedData['title'] != null && scrapedData['title']!.isNotEmpty && _nameController.text.isEmpty) {
                _nameController.text = scrapedData['title'];
              }
            } catch (_) {}
          }
          _pendingEnrichment = false;
          return <String, dynamic>{};
        });
      }
    } catch (e) {
      safeSetState(() {
        _scrapingStatus = l10n?.scrapingError;
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          safeSetState(() => _scrapingStatus = null);
        }
      });
    } finally {
      if (mounted) {
        safeSetState(() => _isScraping = false);
      }
    }
  }

  Future<void> _loadWishlists() async {
    safeSetState(() => _isLoadingWishlists = true);
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return;
      final page = await _wishlistRepo.fetchUserWishlists(ownerId: userId, limit: 50);
      final wishlists = page.items;
      if (!mounted) return;
      safeSetState(() {
        _wishlists = wishlists;
        if (_wishlists.isNotEmpty) {
          _selectedWishlistId = _wishlists.first.id;
        }
      });
    } catch (e) {
      final l10n = AppLocalizations.of(context);
      safeSetState(() {
        _erro = l10n?.errorLoadingWishlists(e.toString()) ?? 'Erro ao carregar wishlists: $e';
      });
    } finally {
      if (mounted) {
        safeSetState(() => _isLoadingWishlists = false);
      }
    }
  }

  Future<void> _createWishlist() async {
    if (_newWishlistNameController.text.trim().isEmpty) return;
    final l10n = AppLocalizations.of(context);
    safeSetState(() => _isCreatingWishlist = true);
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        safeSetState(() {
          _erro = 'É necessário autenticar para criar uma wishlist.';
        });
        return;
      }
      final name = _newWishlistNameController.text.trim();
      final id = await _wishlistRepo.create(
        name: name,
        ownerId: userId,
        isPrivate: false,
        imageUrl: null,
      );
  if (id == null) throw Exception(l10n?.createWishlistError ?? 'Falha ao criar wishlist');
      _newWishlistNameController.clear();
      safeSetState(() {
        _wishlists.insert(0, Wishlist(
          id: id,
          name: name,
          ownerId: userId,
          isPrivate: false,
          createdAt: DateTime.now(),
          imageUrl: null,
        ));
        _selectedWishlistId = id;
      });
    } catch (e) {
      safeSetState(() {
        _erro = AppLocalizations.of(context)?.errorCreatingWishlist(e.toString()) ?? 'Erro ao criar wishlist: $e';
      });
    } finally {
      if (mounted) safeSetState(() => _isCreatingWishlist = false);
    }
  }

  Future<void> _loadItemData() async {
    safeSetState(() => _isSaving = true);
    try {
      final item = await _wishItemRepo.fetchById(widget.itemId!);
      if (!mounted) return;
      if (item != null) {
        _nameController.text = item.name;
        _descriptionController.text = item.description ?? '';
        _linkController.text = item.link ?? '';
        _priceController.text = (item.price ?? 0).toString();
        _selectedCategory = item.category.isNotEmpty ? item.category : categories.first.name;
        _existingImageUrl = item.imageUrl;
      }
    } catch (e) {
      safeSetState(() => _erro = AppLocalizations.of(context)?.errorLoadingItem(e.toString()) ?? 'Erro ao carregar item: $e');
    } finally {
      if (mounted) safeSetState(() => _isSaving = false);
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
      safeSetState(() {
        _imageBytes = imageBytes;
        _localPreviewPath = pickedFile.path;
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
      safeSetState(() {
        _erro = AppLocalizations.of(context)?.selectOrCreateWishlistPrompt ?? 'Por favor, selecione ou crie uma wishlist.';
      });
      return;
    }
    safeSetState(() => _isSaving = true);
    String? uploadedUrl;
    if (_imageBytes != null) {
      safeSetState(() => _isUploading = true);
      try {
        final tempFileForUpload = await File(
          '${(await getTemporaryDirectory()).path}/temp_upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ).writeAsBytes(_imageBytes!);
        if (!mounted) return;
        final targetId = widget.itemId ?? DateTime.now().millisecondsSinceEpoch.toString();
        uploadedUrl = await _cloudinaryService.uploadProductImage(
          tempFileForUpload,
          targetId,
          oldImageUrl: widget.itemId != null ? _existingImageUrl : null,
        );
        if (!mounted) return;
        _existingImageUrl = uploadedUrl;
        if (uploadedUrl?.isNotEmpty == true) {
          await ImageCacheService.putFile(uploadedUrl!, _imageBytes!);
        }
        MonitoringService.logImageUploadSuccess('item', id: targetId, bytes: _imageBytes?.length);
            } catch (e) {
        MonitoringService.logImageUploadFail('item', e);
        safeSetState(() => _erro = AppLocalizations.of(context)?.imageUploadFailed(e.toString()) ?? 'Falha upload imagem: $e');
      } finally {
        if (mounted) safeSetState(() => _isUploading = false);
      }
    }
    final ownerId = AuthService.getCurrentUserId();
    if (ownerId == null) {
      safeSetState(() {
        _erro = 'É necessário autenticar para guardar itens.';
        _isSaving = false;
      });
      return;
    }

    final data = <String, dynamic>{
      'wishlist_id': finalWishlistId,
      'name': ValidationUtils.sanitizeTextInput(_nameController.text),
      'description': _descriptionController.text.trim().isNotEmpty
          ? ValidationUtils.sanitizeTextInput(_descriptionController.text)
          : null,
      'price': double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ?? 0.0,
  'category': _selectedCategory ?? categories.first.name,
      'rating': _rating,
      'link': (() {
        final s = ValidationUtils.sanitizeUrlForSave(_linkController.text);
        return s.isEmpty ? null : s;
      })(),
      'image_url': uploadedUrl ?? _existingImageUrl,
      'quantity': int.tryParse(_quantityController.text.trim()) ?? 1,
  'owner_id': ownerId,
    };
    if (_enrichmentCacheId != null) data['enrich_metadata_ref'] = _enrichmentCacheId;
    if (_enrichmentCacheId != null && !_pendingEnrichment) {
      data['enrich_status'] = 'enriched';
    } else if (_pendingEnrichment) {
      data['enrich_status'] = 'pending';
    }
    bool ok = true;
    if (widget.itemId == null) {
      final id = await _wishItemRepo.create(data);
      ok = id != null;
    } else {
      ok = await _wishItemRepo.update(widget.itemId!, data);
    }
    if (!ok) {
      if (!mounted) return;
      safeSetState(() {
        _erro = 'Falha ao guardar alterações';
        _isSaving = false;
      });
      return;
    }
    try {
      if (_selectedCategory != null) {
        CategoryUsageService().recordUse(_selectedCategory!);
      }
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pop(true);
    if (mounted) safeSetState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemId == null ? (l10n?.addItemTitle ?? 'Adicionar Item') : (l10n?.editItemTitle ?? 'Editar Item')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoadingWishlists && _wishlists.isEmpty
          ? const SkeletonLoader(itemCount: 6)
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isSaving || _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          if (_erro != null) ...[
                            Text(_erro!, style: TextStyle(color: Theme.of(context).extension<AppSemanticColors>()!.danger)),
                            const SizedBox(height: 16),
                          ],
                          if (_isScraping || _scrapingStatus != null) ...[
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _scrapingStatus == null
                            ? const SizedBox.shrink()
                            : StatusChip(
                                key: ValueKey(_scrapingStatus),
                                status: _scrapingStatus == l10n?.enrichmentCompleted
                                    ? StatusChipStatus.completed
                                    : _scrapingStatus == l10n?.enrichmentRateLimited
                                        ? StatusChipStatus.rateLimited
                                        : StatusChipStatus.pending,
                              ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (widget.wishlistId == null && widget.link != null) ...[
                      if (_isLoadingWishlists)
                        const Center(child: CircularProgressIndicator())
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_wishlists.isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      key: const ValueKey('wishlist_dropdown_share'),
                                      initialValue: _selectedWishlistId,
                                      decoration: InputDecoration(
                                        labelText: l10n?.chooseWishlistLabel,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                        filled: true,
                                      ),
                                      isExpanded: true,
                                      borderRadius: BorderRadius.circular(12),
                                      dropdownColor: Theme.of(context).colorScheme.surface,
                                      items: _wishlists
                                          .map((w) => DropdownMenuItem<String>(
                                                value: w.id,
                                                child: Text(w.name, overflow: TextOverflow.ellipsis),
                                              ))
                                          .toList(),
                                      onChanged: (newValue) => safeSetState(() => _selectedWishlistId = newValue),
                                      validator: (value) => ValidationUtils.validateWishlistSelection(value, context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: l10n?.createWishlistAction ?? 'Criar wishlist',
                                    child: SizedBox(
                                      height: 58,
                                      width: 58,
                                      child: OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: _isCreatingWishlist ? null : () => _showQuickCreateWishlistDialog(context),
                                        child: _isCreatingWishlist
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                            : const Icon(Icons.add),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            if (_wishlists.isEmpty)
                              Center(
                                child: Column(
                                  children: [
                                    Text(l10n?.noWishlistFoundCreateNew ?? 'Nenhuma wishlist encontrada. Crie uma nova.'),
                                    const SizedBox(height: 12),
                                    _isCreatingWishlist
                                        ? const CircularProgressIndicator()
                                        : ElevatedButton.icon(
                                            onPressed: () => _showQuickCreateWishlistDialog(context),
                                            icon: const Icon(Icons.add),
                                            label: Text(l10n?.createWishlistAction ?? 'Criar Wishlist'),
                                          ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 20),
                    ],
                    SelectableImagePreview(
                      existingUrl: _existingImageUrl,
                      localPreviewPath: _localPreviewPath,
                      onTap: _pickImage,
                      isUploading: _isUploading,
                      transformationType: cloudinary_service.ImageType.productThumbnail,
                      size: 100,
                      circle: true,
                      fallbackIcon: const Icon(Icons.add_a_photo, size: 42),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n?.itemNameLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      validator: (value) => ValidationUtils.validateItemName(value, context),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: l10n?.categoryLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(12),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: categories
                          .map((c) => DropdownMenuItem<String>(
                                value: c.name,
                                child: Row(children: [Icon(c.icon), const SizedBox(width: 10), Text(c.name)]),
                              ))
                          .toList(),
                      onChanged: (newValue) => safeSetState(() => _selectedCategory = newValue),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n?.itemDescriptionLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      maxLines: 3,
                      validator: (value) => ValidationUtils.validateDescription(value, context),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        labelText: l10n?.linkLabel,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) => ValidationUtils.validateAndSanitizeUrl(value, context),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: l10n?.quantityLabel,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => ValidationUtils.validateQuantity(value, context),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: l10n?.priceLabel,
                            prefixText: '€ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) => ValidationUtils.validatePrice(value, context),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving || _isUploading ? null : _saveItem,
                      child: _isSaving || _isUploading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              widget.itemId == null ? (l10n?.addItemAction ?? 'Adicionar') : (l10n?.saveItemAction ?? 'Guardar'),
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showQuickCreateWishlistDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _newWishlistNameController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.createWishlistAction ?? 'Criar Wishlist'),
        content: TextField(
          controller: _newWishlistNameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n?.newWishlistNameLabel,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _confirmCreateWishlist(ctx),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _isCreatingWishlist ? null : () => _confirmCreateWishlist(ctx),
            child: _isCreatingWishlist
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n?.createWishlistAction ?? 'Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCreateWishlist(BuildContext dialogCtx) async {
    if (_newWishlistNameController.text.trim().isEmpty) return;
    Navigator.of(dialogCtx).pop();
    await _createWishlist();
  }
}
