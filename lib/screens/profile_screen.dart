import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/firebase_database_service.dart';
import 'package:wishlist_app/services/favorites_service.dart';
import 'package:wishlist_app/services/haptic_service.dart';
import 'package:wishlist_app/services/language_service.dart';
import 'package:wishlist_app/widgets/profile_widgets.dart';
import 'package:wishlist_app/widgets/profile_edit_bottom_sheets.dart';
import 'package:wishlist_app/widgets/theme_selector_bottom_sheet.dart';
import 'package:wishlist_app/widgets/language_selector_bottom_sheet.dart';
import 'package:wishlist_app/widgets/memoized_widgets.dart';
import 'package:wishlist_app/widgets/ui_components.dart';
import 'package:wishlist_app/screens/help_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _databaseService = FirebaseDatabaseService();
  final _favoritesService = FavoritesService();
  final _languageService = LanguageService();

  String _displayName = '';
  String _bio = '';
  bool _isPrivate = false;
  bool _isUploading = false;
  String? _profileImageUrl;
  String? _phoneNumber;

  // Estatísticas
  int _wishlistsCount = 0;
  int _itemsCount = 0;
  int _favoritesCount = 0;
  int _sharedCount = 0;
  
  // Cache das estatísticas
  DateTime? _statsLastUpdated;
  static const Duration _statsCacheDuration = Duration(minutes: 5);

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = _authService.currentUser!.uid;
      final user = _authService.currentUser;
      
      // Carregar dados do utilizador
      final userData = await _databaseService.getUserProfile(userId);
      if (userData != null) {
        _displayName = userData['display_name'] ?? '';
        _bio = userData['bio'] ?? '';
        _isPrivate = userData['is_private'] ?? false;
        _phoneNumber = userData['phone_number'];
      }
      
      // Carregar imagem de perfil - priorizar Firestore que tem a URL mais recente
      final firestorePhotoUrl = userData?['photo_url'];
      final firebasePhotoUrl = user?.photoURL;
      
      // Se tem URL no Firestore, usar essa (mais recente)
      if (firestorePhotoUrl != null && firestorePhotoUrl.toString().isNotEmpty) {
        _profileImageUrl = firestorePhotoUrl.toString();
      } else if (firebasePhotoUrl != null && firebasePhotoUrl.isNotEmpty) {
        _profileImageUrl = firebasePhotoUrl;
      } else {
        _profileImageUrl = null;
      }
      
      debugPrint('Profile image URL loaded: $_profileImageUrl');
      
      // Se não tem nome na base de dados, usar do Firebase
      if (_displayName.isEmpty && user?.displayName != null) {
        _displayName = user!.displayName!;
        await _databaseService.updateUserProfile(userId, {
          'display_name': _displayName,
        });
      }
      
      // Carregar estatísticas
      await _loadUserStats(userId);
      
    } catch (e) {
      debugPrint('Erro ao carregar dados do perfil: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserStats(String userId) async {
    // Verificar cache antes de carregar
    final now = DateTime.now();
    if (_statsLastUpdated != null && 
        now.difference(_statsLastUpdated!) < _statsCacheDuration) {
      debugPrint('Usando stats em cache - última atualização: $_statsLastUpdated');
      return;
    }
    
    try {
      debugPrint('Carregando stats frescas do servidor...');
      
      // Carregar wishlists do utilizador - usando stream primeiro valor
      final wishlistsStream = _databaseService.getWishlists(userId);
      final wishlistsSnapshot = await wishlistsStream.first;
      _wishlistsCount = wishlistsSnapshot.length;
      
      // Contar items total
      int totalItems = 0;
      int sharedWishlists = 0;
      
      for (final wishlistData in wishlistsSnapshot) {
        // Contar items em cada wishlist
        final itemsStream = _databaseService.getWishItems(wishlistData['id'] as String);
        final itemsSnapshot = await itemsStream.first;
        totalItems += itemsSnapshot.length;
        
        // Verificar se é pública
        if (wishlistData['is_public'] == true) {
          sharedWishlists++;
        }
      }
      
      _itemsCount = totalItems;
      _sharedCount = sharedWishlists;
      
      // Carregar contagem real de favoritos
      try {
        _favoritesCount = await _favoritesService.getFavoritesCount();
      } catch (e) {
        debugPrint('Error loading favorites count: $e');
        _favoritesCount = 0; // Fallback to 0 on error
      }
      
      // Atualizar timestamp do cache
      _statsLastUpdated = now;
      
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas: $e');
      // Em caso de erro, usar valores padrão
      _wishlistsCount = 0;
      _itemsCount = 0;
      _sharedCount = 0;
      _favoritesCount = 0;
    }
  }

  /// Método público para forçar atualização das estatísticas
  /// Chamado quando navegar para o perfil
  Future<void> refreshStats() async {
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      // Limpar cache para forçar atualização
      _statsLastUpdated = null;
      await _loadUserStats(userId);
      if (mounted) {
        setState(() {}); // Atualizar UI
      }
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
      final tempFile = File(pickedFile.path);
      setState(() {
        _isUploading = true;
      });

      try {
        await _authService.updateProfilePicture(tempFile);
        // Force reload user data to get updated photo URL
        await _loadProfileData();
        
        // Force clear cached image if exists
        if (_profileImageUrl != null) {
          await CachedNetworkImage.evictFromCache(_profileImageUrl!);
        }
      } catch (e) {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao carregar imagem: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<void> _handleEditProfile() async {
    HapticService.lightImpact();
    await EditProfileBottomSheet.show(
      context,
      initialName: _displayName,
      initialBio: _bio,
      onSave: (name, bio) async {
        final userId = _authService.currentUser!.uid;
        await _authService.updateUser(displayName: name);
        await _databaseService.updateUserProfile(userId, {
          'display_name': name,
          'bio': bio,
        });
        setState(() {
          _displayName = name;
          _bio = bio;
        });
      },
    );
  }

  Future<void> _handlePrivacySettings() async {
    HapticService.lightImpact();
    await PrivacySettingsBottomSheet.show(
      context,
      initialIsPrivate: _isPrivate,
      onSave: (isPrivate) async {
        final userId = _authService.currentUser!.uid;
        await _databaseService.updateUserProfile(userId, {'is_private': isPrivate});
        setState(() => _isPrivate = isPrivate);
      },
    );
  }

  Future<void> _handleThemeSettings() async {
    HapticService.lightImpact();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeSelectorBottomSheet(),
    );
  }

  Future<void> _handleLanguageSettings() async {
    HapticService.lightImpact();
    await LanguageSelectorBottomSheet.show(context);
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmationController = TextEditingController();
    bool isDeleting = false; // To manage loading state within the dialog

    // Unfocus any active text fields before showing the dialog
    FocusScope.of(context).unfocus();

    final l10n = AppLocalizations.of(context)!;
  // Fallback enquanto getter não gerado: usar DELETE para en / APAGAR para pt
  final requiredWord = l10n.localeName.startsWith('pt') ? 'APAGAR' : 'DELETE';

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing while deleting
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.deleteAccountConfirmation),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(l10n.deleteAccountWarning.replaceAll('"DELETE"', '"$requiredWord"')),
                  const SizedBox(height: 16),
                  if (isDeleting)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    TextField(
                      controller: confirmationController,
                      decoration: InputDecoration(
                        labelText: l10n.confirm,
                        border: const OutlineInputBorder(),
                        hintText: requiredWord,
                      ),
                      onChanged: (_) => setDialogState(
                        () {},
                      ), // Rebuild to check button state
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed:
                    (confirmationController.text.trim().toUpperCase() == requiredWord && !isDeleting)
                    ? () async {
                        setDialogState(() => isDeleting = true);
                        await _deleteAccount();
                        // The dialog will be closed by navigation changes in _deleteAccount if successful,
                        // or manually on error.
                      }
                    : null,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.disabled)) {
                      return Colors.red.withValues(alpha: 0.5);
                    }
                    return Colors.red;
                  }),
                ),
                child: Text(l10n.deletePermanently),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (!mounted) return;

    try {
      debugPrint('=== Deleting Firebase User Account ===');
      
      await _authService.deleteAccount();

      if (!mounted) return;

      // Close the dialog first before showing success message and navigating
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.accountDeletedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (!mounted) return;
      
      // Only show user-friendly errors, not technical Firebase auth errors
      if (e.toString().contains('[firebase_auth/user-not-found]')) {
        // This is expected when Cloud Function already deleted the user - SUCCESS!
        
        // Close the dialog first
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to login as the account was successfully deleted
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        // Show actual errors to user
        
        // Close the dialog first
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorDeletingAccount('')), // placeholder sem detalhe técnico
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Da tela de perfil, sair da aplicação
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: WishlistAppBar(
          title: l10n.profile,
          showBackButton: false,
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? Center(child: Text(l10n.userNotFound))
              : RefreshIndicator(
                  onRefresh: _loadProfileData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Header Card com perfil - RepaintBoundary
                        RepaintBoundary(
                          child: ProfileHeaderCard(
                            profileImageUrl: _profileImageUrl,
                            name: _displayName.isNotEmpty ? _displayName : user.displayName ?? user.email ?? l10n.noName,
                            bio: _bio,
                            isPrivate: _isPrivate,
                            isUploading: _isUploading,
                            onImageTap: _pickImage,
                            onEditProfile: _handleEditProfile,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Estatísticas - Memoizado
                        MemoizedStatsCard(
                          wishlistsCount: _wishlistsCount,
                          itemsCount: _itemsCount,
                          favoritesCount: _favoritesCount,
                          sharedCount: _sharedCount,
                        ),
                        const ConstSectionDivider(),
                        
                        // Seção Conta
                        ProfileSectionCard(
                          title: l10n.account,
                          icon: Icons.account_circle,
                          children: [
                            ProfileListTile(
                              icon: Icons.email,
                              title: l10n.email,
                              subtitle: user.email ?? l10n.noEmailLinked,
                              onTap: () {
                                HapticService.lightImpact();
                                // FUTURE: Implement email editing when needed
                              },
                            ),
                            if (_phoneNumber != null && _phoneNumber!.isNotEmpty)
                              ProfileListTile(
                                icon: Icons.phone,
                                title: l10n.phone,
                                subtitle: _phoneNumber,
                                onTap: () {
                                  HapticService.lightImpact();
                                  // FUTURE: Implement phone editing when needed
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Seção Preferências
                        ProfileSectionCard(
                          title: l10n.preferences,
                          icon: Icons.settings,
                          children: [
                            ProfileListTile(
                              icon: Icons.palette,
                              title: l10n.theme,
                              subtitle: l10n.customizeAppearance,
                              onTap: _handleThemeSettings,
                              trailing: const Icon(Icons.chevron_right),
                            ),
                            MemoizedLanguageTile(
                              onTap: _handleLanguageSettings,
                              languageService: _languageService,
                            ),
                            MemoizedPrivacyTile(
                              isPrivate: _isPrivate,
                              onTap: _handlePrivacySettings,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Seção Sobre
                        ProfileSectionCard(
                          title: l10n.about,
                          icon: Icons.info_outline,
                          children: [
                            ProfileListTile(
                              icon: Icons.help_outline,
                              title: l10n.helpSupport,
                              onTap: () {
                                HapticService.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HelpScreen(),
                                  ),
                                );
                              },
                              trailing: const Icon(Icons.chevron_right),
                            ),
                            ProfileListTile(
                              icon: Icons.star_outline,
                              title: l10n.rateApp,
                              onTap: () {
                                HapticService.lightImpact();
                                _openAppStore();
                              },
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Seção Ações
                        ProfileSectionCard(
                          title: l10n.actions,
                          icon: Icons.exit_to_app,
                          children: [
                            ProfileListTile(
                              icon: Icons.logout,
                              title: l10n.signOut,
                              onTap: () {
                                HapticService.mediumImpact();
                                _signOut();
                              },
                              iconColor: Colors.orange,
                            ),
                            ProfileListTile(
                              icon: Icons.delete_forever,
                              title: l10n.deleteAccount,
                              subtitle: l10n.deleteAccountDesc,
                              onTap: () {
                                HapticService.heavyImpact();
                                _confirmDeleteAccount();
                              },
                              iconColor: Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  /// Open store for app rating
  Future<void> _openAppStore() async {
    try {
      // For now, open a generic search since app is not published yet
      // TODO: Replace with actual Play Store URL when published: 'https://play.google.com/store/apps/details?id=com.example.wishlist_app'
      const fallbackUrl = 'https://play.google.com/store/search?q=wishlist+app';
      
      final Uri url = Uri.parse(fallbackUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível abrir a loja de aplicações'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening app store: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao abrir a loja de aplicações'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
