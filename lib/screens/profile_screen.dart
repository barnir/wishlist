import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/user_service.dart';
import 'package:wishlist_app/services/haptic_service.dart';
import 'package:wishlist_app/services/language_service.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
import 'package:wishlist_app/widgets/profile_widgets.dart';
import 'package:wishlist_app/widgets/profile_edit_bottom_sheets.dart';
import 'package:wishlist_app/widgets/theme_selector_bottom_sheet.dart';
import 'package:wishlist_app/widgets/language_selector_bottom_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final _databaseService = SupabaseDatabaseService();
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
      final userData = await _userService.getUserProfile(userId);
      if (userData != null) {
        _displayName = userData['display_name'] ?? '';
        _bio = userData['bio'] ?? '';
        _isPrivate = userData['is_private'] ?? false;
        _phoneNumber = userData['phone_number'];
      }
      
      // Carregar imagem de perfil
      _profileImageUrl = user?.photoURL ?? userData?['photo_url'];
      
      // Se não tem nome na base de dados, usar do Firebase
      if (_displayName.isEmpty && user?.displayName != null) {
        _displayName = user!.displayName!;
        await _userService.updateUserProfile(userId, {
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
    try {
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
      
      // Carregar favoritos (assumindo que existe um método para isso)
      // Por agora, usar um número estático
      _favoritesCount = 0; // TODO: Implementar contagem real de favoritos
      
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas: $e');
      // Em caso de erro, usar valores padrão
      _wishlistsCount = 0;
      _itemsCount = 0;
      _sharedCount = 0;
      _favoritesCount = 0;
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
        // Reload user data to get updated photo URL
        await _loadProfileData();
      } catch (e) {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao carregar imagem: \${e.toString()}'),
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
        await _userService.updateUserProfile(userId, {
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
        await _userService.updateUserProfile(userId, {'is_private': isPrivate});
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

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing while deleting
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Apagar Conta'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  const Text(
                    'Esta ação é irreversível. Todos os seus dados serão perdidos. Para confirmar, escreva "APAGAR" na caixa abaixo.',
                  ),
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
                      decoration: const InputDecoration(
                        labelText: 'Confirmar',
                        border: OutlineInputBorder(),
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
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed:
                    (confirmationController.text == 'APAGAR' && !isDeleting)
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
                child: const Text('Apagar Permanentemente'),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta apagada com sucesso.'),
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
      // Close the dialog if it's still open on error
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao apagar conta: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
                        // Header Card com perfil
                        ProfileHeaderCard(
                          profileImageUrl: _profileImageUrl,
                          name: _displayName.isNotEmpty ? _displayName : user.displayName ?? user.email ?? l10n.noName,
                          bio: _bio,
                          isPrivate: _isPrivate,
                          isUploading: _isUploading,
                          onImageTap: _pickImage,
                          onEditProfile: _handleEditProfile,
                        ),
                        const SizedBox(height: 16),
                        
                        // Estatísticas
                        ProfileStatsCard(
                          wishlistsCount: _wishlistsCount,
                          itemsCount: _itemsCount,
                          favoritesCount: _favoritesCount,
                          sharedCount: _sharedCount,
                        ),
                        const SizedBox(height: 16),
                        
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
                                // TODO: Implementar edição de email
                              },
                            ),
                            if (_phoneNumber != null && _phoneNumber!.isNotEmpty)
                              ProfileListTile(
                                icon: Icons.phone,
                                title: l10n.phone,
                                subtitle: _phoneNumber,
                                onTap: () {
                                  HapticService.lightImpact();
                                  // TODO: Implementar edição de telefone
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
                            AnimatedBuilder(
                              animation: _languageService,
                              builder: (context, child) {
                                return ProfileListTile(
                                  icon: Icons.language,
                                  title: l10n.language,
                                  subtitle: _languageService.currentLanguageDisplayName,
                                  onTap: _handleLanguageSettings,
                                  trailing: const Icon(Icons.chevron_right),
                                );
                              },
                            ),
                            ProfileListTile(
                              icon: Icons.privacy_tip,
                              title: l10n.privacy,
                              subtitle: _isPrivate ? l10n.privateProfile : l10n.publicProfile,
                              onTap: _handlePrivacySettings,
                              trailing: const Icon(Icons.chevron_right),
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
                                // TODO: Abrir página de ajuda
                              },
                              trailing: const Icon(Icons.chevron_right),
                            ),
                            ProfileListTile(
                              icon: Icons.star_outline,
                              title: l10n.rateApp,
                              onTap: () {
                                HapticService.lightImpact();
                                // TODO: Abrir loja para avaliação
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
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
