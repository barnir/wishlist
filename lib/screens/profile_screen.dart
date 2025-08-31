import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';
import '../theme_extensions.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:wishlist_app/services/auth_service.dart';
// Estatísticas migradas para StatsRepository (serviço legado removido desta tela)
import 'package:wishlist_app/repositories/stats_repository.dart';
import 'package:wishlist_app/repositories/user_profile_repository.dart';
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
import '../widgets/app_snack.dart';
import 'package:wishlist_app/utils/app_logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _statsRepository = StatsRepository();
  final _userProfileRepo = UserProfileRepository();
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
      final userProfile = await _userProfileRepo.fetchById(userId);
      if (userProfile != null) {
        _displayName = userProfile.displayName ?? '';
  _bio = userProfile.bio ?? '';
        _isPrivate = userProfile.isPrivate;
        _phoneNumber = userProfile.phoneNumber;
      }
      
      // Carregar imagem de perfil - priorizar Firestore que tem a URL mais recente
  final firestorePhotoUrl = userProfile?.photoUrl;
      final firebasePhotoUrl = user?.photoURL;
      
      // Se tem URL no Firestore, usar essa (mais recente)
      if (firestorePhotoUrl != null && firestorePhotoUrl.toString().isNotEmpty) {
        _profileImageUrl = firestorePhotoUrl.toString();
      } else if (firebasePhotoUrl != null && firebasePhotoUrl.isNotEmpty) {
        _profileImageUrl = firebasePhotoUrl;
      } else {
        _profileImageUrl = null;
      }
      
  logD('Profile image loaded', tag: 'UI', data: {'hasImage': _profileImageUrl != null});
      
      // Se não tem nome na base de dados, usar do Firebase
      if (_displayName.isEmpty && user?.displayName != null) {
        _displayName = user!.displayName!;
  await _userProfileRepo.update(userId, {'display_name': _displayName});
      }
      
      // Carregar estatísticas
      await _loadUserStats(userId);
      
    } catch (e) {
      logE('Load profile error', tag: 'UI', error: e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserStats(String userId) async {
    final now = DateTime.now();
    if (_statsLastUpdated != null && now.difference(_statsLastUpdated!) < _statsCacheDuration) {
      logD('Stats cache hit', tag: 'UI', data: {'lastUpdated': _statsLastUpdated.toString()});
      return;
    }
    try {
      logD('Loading fresh stats (repository)', tag: 'UI');
      final stats = await _statsRepository.loadUserStats(userId);
      _wishlistsCount = stats.wishlists;
      _itemsCount = stats.items;
      _sharedCount = stats.shared;
      try {
        _favoritesCount = await _favoritesService.getFavoritesCount();
      } catch (e) {
        logE('Favorites count error', tag: 'UI', error: e);
        _favoritesCount = 0;
      }
      _statsLastUpdated = now;
    } catch (e) {
      logE('Stats load error', tag: 'UI', error: e);
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
        final newUrl = await _authService.updateProfilePicture(tempFile);
        if (newUrl != null) {
          // Evict old image from cache first so next build fetches new one
          if (_profileImageUrl != null) {
            await CachedNetworkImage.evictFromCache(_profileImageUrl!);
          }
          setState(() {
            _profileImageUrl = newUrl;
          });
        }
      } catch (e) {
        // Handle error
        if (mounted) {
          AppSnack.show(context, 'Erro ao carregar imagem: ${e.toString()}', type: SnackType.error);
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
        await _userProfileRepo.update(userId, {
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
  await _userProfileRepo.update(userId, {'is_private': isPrivate});
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
  bool needsReauth = false; // Flag when recent login required

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
                  if (needsReauth)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        l10n.errorDeletingAccount('reauth'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
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
              if (needsReauth && !isDeleting)
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    AppSnack.show(context, l10n.errorDeletingAccount('reauth'), type: SnackType.error);
                  },
                  child: Text(l10n.reauthenticate),
                ),
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: (confirmationController.text.trim().toUpperCase() == requiredWord && !isDeleting)
                    ? () async {
                        setDialogState(() => isDeleting = true);
                        final success = await _deleteAccount();
                        // If failed, revert loading so user can retry; success path closes dialog internally
                        if (!success && context.mounted) {
                          setDialogState(() {
                            isDeleting = false;
                            // Detect reauth requirement by last error marker stored in state var? Using snack text param
                            needsReauth = true; // conservative: show reauth path after any failure
                          });
                        }
                      }
                    : null,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.disabled)) {
                      return context.semanticColors.danger.withValues(alpha: 0.5);
                    }
                    return context.semanticColors.danger;
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

  Future<bool> _deleteAccount() async {
    if (!mounted) return false;
    try {
      logI('Deleting user account', tag: 'UI');

      // Timeout to avoid indefinite spinner
      await _authService.deleteAccount().timeout(const Duration(seconds: 25));

      if (!mounted) return true;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      final l10n = AppLocalizations.of(context)!;
      AppSnack.show(context, l10n.accountDeletedSuccessfully, type: SnackType.success);
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return true;
    } on TimeoutException catch (e) {
      logE('Delete account timeout', tag: 'UI', error: e);
      if (!mounted) return false;
      final l10n = AppLocalizations.of(context)!;
      AppSnack.show(context, l10n.errorDeletingAccount('timeout'), type: SnackType.error);
      return false;
    } catch (e) {
      if (!mounted) return false;
      logE('Delete account error', tag: 'UI', error: e);
      final l10n = AppLocalizations.of(context)!;
      final errorStr = e.toString();

      // Treat user-not-found as success (already deleted)
      if (errorStr.contains('[firebase_auth/user-not-found]')) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        AppSnack.show(context, l10n.accountDeletedSuccessfully, type: SnackType.success);
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return true;
      }

      // Requires recent login -> inform user
      if (errorStr.contains('requires-recent-login')) {
        AppSnack.show(context, l10n.errorDeletingAccount('reauth'), type: SnackType.error);
        return false; // dialog keeps open, flag triggers reauth UI
      }

      AppSnack.show(context, l10n.errorDeletingAccount(errorStr), type: SnackType.error);
      return false;
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
                              iconColor: context.semanticColors.warning,
                            ),
                            ProfileListTile(
                              icon: Icons.delete_forever,
                              title: l10n.deleteAccount,
                              subtitle: l10n.deleteAccountDesc,
                              onTap: () {
                                HapticService.heavyImpact();
                                _confirmDeleteAccount();
                              },
                              iconColor: context.semanticColors.danger,
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
  // Generic search until published (update when store URL available)
  const fallbackUrl = 'https://play.google.com/store/search?q=wishlist+app';
      
      final Uri url = Uri.parse(fallbackUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          AppSnack.show(context, 'Não foi possível abrir a loja de aplicações', type: SnackType.error);
        }
      }
    } catch (e) {
  logE('Open app store error', tag: 'UI', error: e);
      if (mounted) {
        AppSnack.show(context, 'Erro ao abrir a loja de aplicações', type: SnackType.error);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
