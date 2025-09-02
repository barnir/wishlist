import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../theme_extensions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wishlist_app/repositories/wish_item_repository.dart';
import 'package:wishlist_app/repositories/wishlist_repository.dart';
import 'package:wishlist_app/models/wishlist.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
import 'package:wishlist_app/services/monitoring_service.dart';
import 'package:wishlist_app/services/image_cache_service.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/selectable_image_preview.dart';
import 'package:wishlist_app/services/web_scraper_service.dart';
import 'package:wishlist_app/services/share_enrichment_service.dart';
import 'package:http/http.dart' as http;
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:wishlist_app/utils/validation_utils.dart';

import '../models/category.dart';
import 'package:wishlist_app/services/category_usage_service.dart';

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
  final _wishItemRepo = WishItemRepository();
  final _wishlistRepo = WishlistRepository();
  final _webScraperService = WebScraperServiceSecure();
  final _shareService = ShareEnrichmentService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _linkController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _newWishlistNameController;
  String? _selectedCategory;
  double? _rating;
  Uint8List? _imageBytes; // New (unsaved) selection bytes
  bool _isUploading = false;
  String? _existingImageUrl;
  String? _localPreviewPath; // local file path for immediate preview
  final _cloudinaryService = CloudinaryService();

  bool _isSaving = false;
  bool _isScraping = false;
  String? _scrapingStatus;
  String? _erro;

  String? _selectedWishlistId;
  List<Wishlist> _wishlists = [];
  bool _isLoadingWishlists = false;
  bool _isCreatingWishlist = false;
  bool _pendingEnrichment = false; // indica enrichment pendente
  String? _enrichmentCacheId; // recebido do backend
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

  // Carrega listas apenas se não foi aberto a partir de uma wishlist E veio de um share (tem link)
  if (widget.wishlistId == null && widget.link != null) {
      _loadWishlists();
    }
  }

  Future<void> _handleSharedLink() async {
    if (widget.link != null && widget.link!.isNotEmpty) {
      final l10n = AppLocalizations.of(context); // Capture l10n at the start
      setState(() {
  _isScraping = true;
  _scrapingStatus = l10n?.scrapingExtractingInfo;
      });
      try {
        // 1. Parse rápido (texto do link/título inicial share pode já vir em widget.name)
        final shareResult = await _shareService.processSharedText(widget.link!);
        final initial = shareResult.initial;
        if (!mounted) return;
        // Marcar enriquecimento pendente (só se link válido)
        if (initial.url != null) {
          // Guardamos internamente status; será persistido ao salvar se ainda pendente
          _pendingEnrichment = true;
          _enrichmentCacheId = null; // aguardará retorno
        }
        if (initial.title != null && initial.title!.isNotEmpty && _nameController.text.isEmpty) {
          _nameController.text = initial.title!;
        }
        if (initial.price != null) {
          _priceController.text = initial.price!;
        }
        // 2. Enrichment assíncrono (não bloquear UI)
        final enrichmentFuture = shareResult.enrichmentFuture;
        if (enrichmentFuture != null) {
          enrichmentFuture.then((data) async {
            if (!mounted) return;
            // Captura cacheId para persistência futura
            final cacheId = data['cacheId'] as String?;
            if (cacheId != null && cacheId.isNotEmpty) {
              _enrichmentCacheId = cacheId;
            }
            if (data['rateLimited'] == true) {
              setState(() {
                _scrapingStatus = AppLocalizations.of(context)?.enrichmentRateLimited;
                _pendingEnrichment = false;
              });
              return;
            }
            // Evitar sobrescrever se usuário já editou
            if (_nameController.text.isEmpty && (data['title'] as String?)?.isNotEmpty == true) {
              _nameController.text = data['title'];
            }
            final priceNum = data['price'];
            if (priceNum is num && (double.tryParse(_priceController.text) ?? 0) == 0) {
              _priceController.text = priceNum.toStringAsFixed(2);
            }
            // Rating
            final ratingVal = data['ratingValue'];
            if (ratingVal is num && (_rating == null || _rating == 0)) {
              _rating = ratingVal.toDouble().clamp(0.0, 5.0);
            }
            // Categoria sugerida se usuário não alterou manualmente (ainda está primeira default)
            final suggestedCat = data['categorySuggestion'] as String?;
            if (suggestedCat != null && suggestedCat.isNotEmpty && _selectedCategory == categories.first.name) {
              if (categories.any((c) => c.name == suggestedCat)) {
                _selectedCategory = suggestedCat;
              }
            }
            final img = data['image'] as String?;
            if (img != null && img.isNotEmpty && _imageBytes == null && _existingImageUrl == null) {
              try {
                setState(()=> _scrapingStatus = l10n?.scrapingLoadingImage);
                final response = await http.get(Uri.parse(img));
                if (response.statusCode == 200) {
                  final tempDir = await getTemporaryDirectory();
                  final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
                  await tempFile.writeAsBytes(response.bodyBytes);
                  if (mounted) {
                    setState(() {
                      _imageBytes = response.bodyBytes;
                      _localPreviewPath = tempFile.path;
                    });
                  }
                }
              } catch (_) {}
            }
            setState(() {
              _scrapingStatus = AppLocalizations.of(context)?.enrichmentCompleted;
              _pendingEnrichment = false; // enrichment finalizado
            });
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _scrapingStatus == AppLocalizations.of(context)?.enrichmentCompleted) {
                setState(() => _scrapingStatus = null);
              }
            });
          });
        }

        // Status inicial muda para preenchimento rápido
        setState(() {
          _scrapingStatus = l10n?.scrapingFillingFields ?? AppLocalizations.of(context)?.enrichmentPending;
        });

        // Ainda executamos fallback antigo se enrichment falhar e título vazio
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
            _pendingEnrichment = false; // falhou
            return <String, dynamic>{};
          });
        }
      } catch (e) {
        setState(() {
          _scrapingStatus = l10n?.scrapingError;
        });
        
        // Clear error status after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _scrapingStatus = null;
            });
          }
        });
      } finally {
        setState(() {
          _isScraping = false;
        });
      }
    }
  }

  Future<void> _loadWishlists() async {
    setState(() {
      _isLoadingWishlists = true;
    });
    try {
  final userId = AuthService.getCurrentUserId();
  if (userId == null) return;
  // Simple first page fetch (could paginate later)
  final page = await _wishlistRepo.fetchUserWishlists(ownerId: userId, limit: 50);
  final wishlists = page.items;
    if (!mounted) return; // Guard after async
      setState(() {
        _wishlists = wishlists;
        if (_wishlists.isNotEmpty) {
          _selectedWishlistId = _wishlists.first.id;
        }
      });
    } catch (e) {
      setState(() {
  _erro = AppLocalizations.of(context)?.errorLoadingWishlists(e.toString()) ?? 'Erro ao carregar wishlists: $e';
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
      final userId = AuthService.getCurrentUserId()!;
      final name = _newWishlistNameController.text.trim();
      final id = await _wishlistRepo.create(
        name: name,
        ownerId: userId,
        isPrivate: false,
        imageUrl: null,
      );
      if (id == null) throw Exception('Falha ao criar wishlist');
      _newWishlistNameController.clear();
      setState(() {
        _wishlists.insert(0, Wishlist(
          id: id,
      name: name,
          ownerId: userId,
          isPrivate: false,
          createdAt: DateTime.now(),
          imageUrl: null,
        ));
        _selectedWishlistId = id;
  // quick create dialog handles visibility; legacy flag removed
      });
    } catch (e) {
      setState(() {
  _erro = AppLocalizations.of(context)?.errorCreatingWishlist(e.toString()) ?? 'Erro ao criar wishlist: $e';
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
  final item = await _wishItemRepo.fetchById(widget.itemId!);
  if (!mounted) return; // Guard after async

      if (item != null) {
        _nameController.text = item.name;
        _descriptionController.text = item.description ?? '';
        _linkController.text = item.link ?? '';
        _priceController.text = (item.price ?? 0).toString();
        _selectedCategory = item.category.isNotEmpty ? item.category : categories.first.name;
        _existingImageUrl = item.imageUrl;
  // existing image will be shown via OptimizedCloudinaryImage
      }
    } catch (e) {
  setState(() => _erro = AppLocalizations.of(context)?.errorLoadingItem(e.toString()) ?? 'Erro ao carregar item: $e');
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
      setState(() {
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
      setState(() {
        _erro = AppLocalizations.of(context)?.selectOrCreateWishlistPrompt ?? 'Por favor, selecione ou crie uma wishlist.';
      });
      return;
    }

    setState(() => _isSaving = true);

    String? uploadedUrl;
    if (_imageBytes != null) {
      setState(() => _isUploading = true);
      try {
  final tempFileForUpload = await File(
          '${(await getTemporaryDirectory()).path}/temp_upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ).writeAsBytes(_imageBytes!);
  if (!mounted) return; // Guard
        final targetId = widget.itemId ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        // Pass existing image URL for cleanup if editing an item
        uploadedUrl = await _cloudinaryService.uploadProductImage(
          tempFileForUpload, 
          targetId,
          oldImageUrl: widget.itemId != null ? _existingImageUrl : null,
        );
        
  if (!mounted) return; // Guard
        _existingImageUrl = uploadedUrl;
  if (uploadedUrl != null) {
          await ImageCacheService.putFile(uploadedUrl, _imageBytes!);
          MonitoringService.logImageUploadSuccess('item', id: targetId, bytes: _imageBytes?.length);
        }
      } catch (e) {
        MonitoringService.logImageUploadFail('item', e);
  setState(() => _erro = AppLocalizations.of(context)?.imageUploadFailed(e.toString()) ?? 'Falha upload imagem: $e');
      } finally {
        setState(() => _isUploading = false);
      }
    }

    final data = <String, dynamic>{
      'wishlist_id': finalWishlistId,
      'name': ValidationUtils.sanitizeTextInput(_nameController.text),
      'description': _descriptionController.text.trim().isNotEmpty 
          ? ValidationUtils.sanitizeTextInput(_descriptionController.text) : null,
      'price': double.tryParse(_priceController.text.trim().replaceAll(',', '.')) ?? 0.0,
      'category': _selectedCategory!,
      'rating': _rating,
      'link': (() { final s = ValidationUtils.sanitizeUrlForSave(_linkController.text); return s.isEmpty ? null : s; })(),
      'image_url': uploadedUrl ?? _existingImageUrl,
      'quantity': int.tryParse(_quantityController.text.trim()) ?? 1,
      'owner_id': AuthService.getCurrentUserId(), // ensure always present to satisfy rules & backfill legacy docs
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
      setState(() {
        _erro = 'Falha ao guardar alterações';
        _isSaving = false;
      });
      return; // do not pop
    }

    // Record local usage of the chosen category (best effort, non-blocking)
    try {
      if (_selectedCategory != null) {
        // Lazy import avoidance: service is lightweight
        // ignore: avoid_print
        CategoryUsageService().recordUse(_selectedCategory!);
      }
    } catch (_) {}

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
  title: Text(widget.itemId == null ? (AppLocalizations.of(context)?.addItemTitle ?? 'Adicionar Item') : (AppLocalizations.of(context)?.editItemTitle ?? 'Editar Item')),
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
                      Text(_erro!, style: TextStyle(color: Theme.of(context).extension<AppSemanticColors>()!.danger)),
                      const SizedBox(height: 16),
                    ],
                    
                    // Scraping status feedback
                    if (_isScraping || _scrapingStatus != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _scrapingStatus?.contains('Erro') == true
                              ? Theme.of(context).colorScheme.errorContainer
                              : _scrapingStatus?.contains('Concluído') == true
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _scrapingStatus?.contains('Erro') == true
                                ? Theme.of(context).colorScheme.error
                                : _scrapingStatus?.contains('Concluído') == true
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline.withAlpha(128),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_isScraping)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            else
                              Icon(
                                _scrapingStatus?.contains('Erro') == true
                                    ? Icons.error_outline
                                    : _scrapingStatus?.contains('Concluído') == true
                                        ? Icons.check_circle_outline
                                        : Icons.info_outline,
                                size: 16,
                                color: _scrapingStatus?.contains('Erro') == true
                                    ? Theme.of(context).colorScheme.error
                                    : _scrapingStatus?.contains('Concluído') == true
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _scrapingStatus ?? '',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: _scrapingStatus?.contains('Erro') == true
                                      ? Theme.of(context).colorScheme.onErrorContainer
                                      : _scrapingStatus?.contains('Concluído') == true
                                          ? Theme.of(context).colorScheme.onPrimaryContainer
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Seleção de wishlist apenas quando veio de partilha (share) e não estamos dentro de uma wishlist específica
                    if (widget.wishlistId == null && widget.link != null) ...[
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      key: ValueKey('wishlist_dropdown_share'),
                                      value: _selectedWishlistId,
                                      decoration: InputDecoration(
                                        labelText: AppLocalizations.of(context)?.chooseWishlistLabel,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        filled: true,
                                      ),
                                      items: _wishlists.map((wishlist) => DropdownMenuItem<String>(
                                        value: wishlist.id,
                                        child: Text(wishlist.name, overflow: TextOverflow.ellipsis),
                                      )).toList(),
                                      onChanged: (newValue) {
                                        setState(() => _selectedWishlistId = newValue);
                                      },
                                      validator: (value) => ValidationUtils.validateWishlistSelection(value, context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Tooltip(
                                    message: AppLocalizations.of(context)?.createWishlistAction ?? 'Criar wishlist',
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
                                          ? const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2))
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
                                    Text(AppLocalizations.of(context)?.noWishlistFoundCreateNew ?? 'Nenhuma wishlist encontrada. Crie uma nova.'),
                                    const SizedBox(height: 12),
                                    _isCreatingWishlist
                                      ? const CircularProgressIndicator()
                                      : ElevatedButton.icon(
                                          onPressed: () => _showQuickCreateWishlistDialog(context),
                                          icon: const Icon(Icons.add),
                                          label: Text(AppLocalizations.of(context)?.createWishlistAction ?? 'Criar Wishlist'),
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
                      transformationType: ImageType.productThumbnail,
                      size: 100,
                      circle: true,
                      fallbackIcon: const Icon(Icons.add_a_photo, size: 42),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.itemNameLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      validator: (value) => ValidationUtils.validateItemName(value, context),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.categoryLabel,
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
                        labelText: AppLocalizations.of(context)?.itemDescriptionLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      maxLines: 3,
                      validator: (value) => ValidationUtils.validateDescription(value, context),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)?.linkLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) => ValidationUtils.validateAndSanitizeUrl(value, context),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)?.quantityLabel,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                              labelText: AppLocalizations.of(context)?.priceLabel,
                              prefixText: '€ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) => ValidationUtils.validatePrice(value, context),
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
                              widget.itemId == null ? (AppLocalizations.of(context)?.addItemAction ?? 'Adicionar') : (AppLocalizations.of(context)?.saveItemAction ?? 'Guardar'),
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
      builder: (ctx) {
        return AlertDialog(
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
              child: _isCreatingWishlist ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : Text(l10n?.createWishlistAction ?? 'Criar'),
            )
          ],
        );
      },
    );
  }

  Future<void> _confirmCreateWishlist(BuildContext dialogCtx) async {
    if (_newWishlistNameController.text.trim().isEmpty) return;
    Navigator.of(dialogCtx).pop();
    await _createWishlist();
  }
}
