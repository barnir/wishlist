import 'package:mywishstash/widgets/skeleton_loader.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mywishstash/widgets/accessible_icon_button.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import '../theme_extensions.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mywishstash/repositories/user_search_repository.dart';
import 'package:mywishstash/models/user_profile.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';
import 'package:mywishstash/utils/app_logger.dart';
import 'package:mywishstash/repositories/favorites_repository.dart';
import 'package:mywishstash/widgets/app_snack.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final _userSearchRepo = UserSearchRepository();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // Tab controller (search + contacts)
  late TabController _tabController;

  // Search state
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Paginação
  static const int _pageSize = 15;
  final List<UserProfile> _users = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _isInitialLoading = false;

  // Contacts state (merged friends + invite)
  List<Map<String, dynamic>> _friendsInApp =
      []; // items with 'user' + 'contact'
  List<Contact> _contactsToInvite = [];
  bool _isLoadingContacts = false;
  bool _hasContactsPermission = false;
  final Set<String> _favoriteIds = {};

  final FavoritesRepository _favoritesRepo = FavoritesRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _checkContactsPermission();
    // Load public profiles automatically when screen opens
    _loadPublicProfiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      if (query != _searchQuery) {
        setState(() {
          _searchQuery = query;
          _users.clear();
          _lastDoc = null;
          _hasMoreData = true;
        });

        if (query.isNotEmpty) {
          _loadInitialData();
        }
      }
    });
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.userScrollDirection == ScrollDirection.idle) return;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  /// Load public profiles automatically when screen opens (no search query needed)
  Future<void> _loadPublicProfiles() async {
    setState(() {
      _isInitialLoading = true;
      _users.clear();
      _lastDoc = null;
      _hasMoreData = true;
    });

    await _loadPublicProfilesData();

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    if (_searchQuery.isEmpty) {
      // If no search query, load public profiles instead
      await _loadPublicProfiles();
      return;
    }

    setState(() {
      _isInitialLoading = true;
      _users.clear();
      _lastDoc = null;
      _hasMoreData = true;
    });

    await _loadMoreData();

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  /// Load public profiles data (used when no search query)
  Future<void> _loadPublicProfilesData() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final page = await _userSearchRepo.getPublicUsersPage(
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      setState(() {
        _users.addAll(page.items);
        _lastDoc = page.lastDoc;
        _hasMoreData = page.hasMore;
        _isLoading = false;
      });
      if (!_hasMoreData) {
        _scrollController.removeListener(_onScroll);
      }
    } catch (e) {
      // Provide more precise feedback for common Firestore failure causes
      final errorText = _mapSearchError(e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText)));
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    // If no search query, load public profiles
    if (_searchQuery.isEmpty) {
      await _loadPublicProfilesData();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final page = await _userSearchRepo.searchPage(
        query: _searchQuery,
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      setState(() {
        _users.addAll(page.items);
        _lastDoc = page.lastDoc;
        _hasMoreData = page.hasMore;
        _isLoading = false;
      });
      if (!_hasMoreData) {
        _scrollController.removeListener(_onScroll);
      }
    } catch (e) {
      // Provide more precise feedback for common Firestore failure causes
      final errorText = _mapSearchError(e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText)));
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_searchQuery.isEmpty) {
      await _loadPublicProfiles();
    } else {
      await _loadInitialData();
    }
  }

  // ============== CONTACTS METHODS ==============

  Future<void> _checkContactsPermission() async {
    try {
      // Primeiro só verificamos se já temos permissão, sem solicitar
      final hasPermission = await FlutterContacts.requestPermission(
        readonly: true,
      );
      if (mounted) {
        setState(() {
          _hasContactsPermission = hasPermission;
        });
        // Se já temos permissão, carregamos os dados automaticamente
        if (hasPermission) {
          _loadContactsData();
        }
      }
    } catch (e) {
      logE('Contacts permission check error', tag: 'UI', error: e);
      if (mounted) {
        setState(() {
          _hasContactsPermission = false;
        });
      }
    }
  }

  Future<void> _requestContactsPermission() async {
    try {
      setState(() {
        _isLoadingContacts = true;
      });

      // Solicita explicitamente a permissão ao utilizador
      final granted = await FlutterContacts.requestPermission();

      if (mounted) {
        setState(() {
          _hasContactsPermission = granted;
          _isLoadingContacts = false;
        });

        if (granted) {
          // Permissão concedida - carregar dados
          _loadContactsData();
          final grantedMsg =
              AppLocalizations.of(context)?.contactsPermissionDescription ??
              'Permissão concedida! A descobrir contactos...';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(grantedMsg),
              backgroundColor: Theme.of(
                context,
              ).extension<AppSemanticColors>()!.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Permissão negada - mostrar explicação
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.contactsPermissionRequired,
              ),
              action: SnackBarAction(
                label:
                    AppLocalizations.of(context)?.contactsPermissionTryAgain ??
                    'Tentar novamente',
                onPressed: _requestContactsPermission,
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingContacts = false;
          _hasContactsPermission = false;
        });

        // Erro na solicitação - pode indicar permissão negada permanentemente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!.errorRequestingPermission(e.toString()),
            ),
            action: SnackBarAction(
              label:
                  AppLocalizations.of(context)?.contactsPermissionSettings ??
                  'Configurações',
              onPressed: () {
                // TODO: Abrir configurações da app se necessário
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)?.contactsPermissionManual ??
                          'Vai às Configurações > Apps > WishlistApp > Permissões para ativar manualmente',
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  Future<void> _loadContactsData() async {
    // Verificação dupla de segurança
    if (!_hasContactsPermission) {
      logW('Load contacts without permission attempt', tag: 'UI');
      return;
    }

    try {
      setState(() {
        _isLoadingContacts = true;
      });

      // Verifica permissão novamente antes de prosseguir
      final stillHasPermission = await FlutterContacts.requestPermission(
        readonly: true,
      );
      if (!stillHasPermission) {
        if (mounted) {
          setState(() {
            _hasContactsPermission = false;
            _isLoadingContacts = false;
          });
        }
        return;
      }

      // Carrega contactos com propriedades completas
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false, // Não precisamos de fotos para descoberta
      );

      // Filtra contactos que têm números de telefone ou emails
      final contactsWithPhones = contacts
          .where((c) => c.phones.isNotEmpty || c.emails.isNotEmpty)
          .toList();

      // Recolhe todos os números de telefone e emails dos contactos
      final phoneNumbers = <String>[];
      final emails = <String>[];

      for (final contact in contactsWithPhones) {
        for (final phone in contact.phones) {
          if (phone.number.isNotEmpty) {
            phoneNumbers.add(phone.number);
          }
        }
        for (final email in contact.emails) {
          if (email.address.isNotEmpty) {
            emails.add(email.address);
          }
        }
      }

      // Procura utilizadores registados que correspondam aos contactos
      final registeredUsers = await _userSearchRepo.findUsersByContacts(
        phoneNumbers: phoneNumbers,
        emails: emails,
      );

      // Separa contactos entre amigos registados e contactos para convidar
      final friends = <Map<String, dynamic>>[];
      final inviteContacts = <Contact>[];

      for (final contact in contactsWithPhones) {
        bool isRegistered = false;
        UserProfile? matchedUser;

        // Verifica se algum telefone ou email do contacto corresponde a um utilizador registado
        for (final phone in contact.phones) {
          final normalizedPhone = _normalizePhoneNumber(phone.number);
          logI(
            'Checking contact phone: ${phone.number} -> normalized: $normalizedPhone',
            tag: 'CONTACT_DEBUG',
          );
          logI(
            'Available registered phones: ${registeredUsers.keys.toList()}',
            tag: 'CONTACT_DEBUG',
          );

          if (normalizedPhone != null &&
              registeredUsers.containsKey(normalizedPhone)) {
            isRegistered = true;
            matchedUser = registeredUsers[normalizedPhone];
            logI(
              'MATCH FOUND! Contact ${contact.displayName} matches user ${matchedUser!.displayName} with phone: $normalizedPhone',
              tag: 'CONTACT_DEBUG',
            );
            break;
          }

          if (isRegistered) break;
        }

        if (!isRegistered) {
          for (final email in contact.emails) {
            final cleanEmail = email.address.toLowerCase().trim();
            if (registeredUsers.containsKey(cleanEmail)) {
              isRegistered = true;
              matchedUser = registeredUsers[cleanEmail];
              break;
            }
          }
        }

        if (isRegistered && matchedUser != null) {
          // Contacto está registado na app - adiciona aos amigos
          friends.add({
            'contact': {
              'name': contact.displayName,
              'phone': contact.phones.isNotEmpty
                  ? contact.phones.first.number
                  : null,
            },
            'user': {
              'id': matchedUser.id,
              'display_name': matchedUser.displayName,
              'email': matchedUser.email,
              'phone_number': matchedUser.phoneNumber,
              'photo_url': matchedUser.photoUrl,
            },
            'contact_name': contact.displayName,
            'contact_phone': contact.phones.isNotEmpty
                ? contact.phones.first.number
                : null,
          });
        } else {
          // Contacto não está registado - adiciona aos convites
          inviteContacts.add(contact);
        }
      }

      if (mounted) {
        setState(() {
          _friendsInApp = friends;
          _contactsToInvite = inviteContacts;
          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      logE('Error loading contacts', tag: 'UI', error: e);
      if (mounted) {
        setState(() {
          _isLoadingContacts = false;
        });

        // Trata diferentes tipos de erro
        String errorMessage;
        if (e.toString().contains('permission')) {
          errorMessage =
              AppLocalizations.of(context)?.contactsPermissionRevoked ??
              'Permissão de contactos foi revogada. Tenta novamente.';
          setState(() {
            _hasContactsPermission = false;
          });
        } else {
          errorMessage = AppLocalizations.of(
            context,
          )!.errorLoadingContacts(e.toString());
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            action: SnackBarAction(
              label: 'Tentar novamente',
              onPressed: () {
                if (_hasContactsPermission) {
                  _loadContactsData();
                } else {
                  _requestContactsPermission();
                }
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _inviteContact(Contact contact) async {
    try {
      final name = contact.displayName;
      final l10n = AppLocalizations.of(context)!;

      final message =
          'Olá $name! Estou a usar o WishlistApp para gerir as minhas listas de desejos. Experimenta também! 🎁';
      final fullMessage = '$message\n\n${l10n.invitePlayStoreMessage}';

      // ignore: deprecated_member_use
      // ignore: deprecated_member_use
      await Share.share(fullMessage, subject: l10n.inviteSubject);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorSendingInvite(e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exploreTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: const Icon(Icons.search), text: l10n.searchTab),
            Tab(icon: const Icon(Icons.people), text: l10n.friendsTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSearchTab(), _buildContactsTab()],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: UIConstants.paddingM,
          child: WishlistTextField(
            label: AppLocalizations.of(context)!.searchUsersPlaceholder,
            controller: _searchController,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        Expanded(child: _buildSearchContent()),
      ],
    );
  }

  Widget _buildSearchContent() {
    if (_searchQuery.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return WishlistEmptyState(
        icon: Icons.search,
        title: l10n.searchUsersTitle,
        subtitle: l10n.searchUsersSubtitle,
      );
    }

    if (_isInitialLoading) {
      return const SkeletonLoader(itemCount: 8);
    }

    if (_users.isEmpty && !_isLoading) {
      final l10n = AppLocalizations.of(context)!;
      return WishlistEmptyState(
        icon: Icons.person_search,
        title: l10n.noResults,
        subtitle: l10n.noResultsSubtitle,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: UIConstants.listPadding,
        itemCount: _users.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(AppLocalizations.of(context)!.loadingMoreResults),
              ),
            );
          }
          return _buildUserCard(_users[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    final displayName = user.displayName ?? 'Utilizador';
    final userId = user.id;
    final isPrivate = user.isPrivate;
    final String? bio = user.bio;

    return Card(
      margin: UIConstants.cardMargin,
      elevation: UIConstants.elevationM,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/user_profile', arguments: userId);
        },
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
        child: Container(
          padding: UIConstants.paddingM,
          child: Row(
            children: [
              // Avatar do utilizador maior
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(UIConstants.radiusM),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withAlpha(204),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Spacing.horizontalM,

              // Informação do utilizador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome do utilizador
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Status de privacidade
                    Row(
                      children: [
                        Icon(
                          isPrivate
                              ? Icons.lock_outlined
                              : Icons.public_outlined,
                          size: 14,
                          color: isPrivate
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isPrivate
                              ? (AppLocalizations.of(
                                      context,
                                    )?.privateProfileBadge ??
                                    'Perfil privado')
                              : (AppLocalizations.of(
                                      context,
                                    )?.publicProfileBadge ??
                                    'Perfil público'),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isPrivate
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Seta de navegação
              Icon(
                Icons.arrow_forward,
                size: UIConstants.iconSizeS,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsTab() {
    if (!_hasContactsPermission) return _buildPermissionRequest();

    if (_isLoadingContacts) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.discoveringFriends),
          ],
        ),
      );
    }

    final total = _friendsInApp.length + _contactsToInvite.length;
    if (total == 0) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.contacts, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.noFriendsFound),
            const SizedBox(height: 8),
            Text(
              '${l10n.noFriendsFoundDescription}\n(Quando os teus contactos entrarem vais vê-los aqui)',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadContactsData,
      child: ListView.builder(
        padding: UIConstants.listPadding,
        itemCount: total,
        itemBuilder: (context, index) {
          if (index < _friendsInApp.length) {
            return _buildFriendCard(_friendsInApp[index]);
          }
          final contact = _contactsToInvite[index - _friendsInApp.length];
          return _buildInviteCard(contact);
        },
      ),
    );
  }

  Widget _buildPermissionRequest() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: UIConstants.paddingL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.contacts, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              l10n.discoverFriends,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.contactsPermissionDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestContactsPermission,
              icon: const Icon(Icons.contacts),
              label: Text(l10n.allowContactsAccess),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friendData) {
    final user = friendData['user'] as Map<String, dynamic>;
    final contact = friendData['contact'] as Map<String, dynamic>;

    final displayName =
        user['display_name'] as String? ??
        contact['name'] as String? ??
        'Utilizador';
    final email = user['email'] as String?;
    final userId = user['id'] as String;
    final contactName = contact['name'] as String? ?? displayName;

    final isFav = _favoriteIds.contains(userId);
    return Card(
      margin: UIConstants.cardMargin,
      elevation: UIConstants.elevationM,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/user_profile', arguments: userId);
        },
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
        child: Container(
          padding: UIConstants.paddingM,
          child: Row(
            children: [
              // Avatar do utilizador
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(UIConstants.radiusM),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withAlpha(204),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Informação do utilizador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (contactName != displayName) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${AppLocalizations.of(context)!.contactLabel}: $contactName',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Actions (favorite toggle)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AccessibleIconButton(
                    icon: isFav ? Icons.star : Icons.star_border,
                    color: isFav
                        ? Colors.amber
                        : Theme.of(context).colorScheme.primary,
                    semanticLabel: isFav
                        ? AppLocalizations.of(context)?.removeFromFavorites ??
                              'Remover dos favoritos'
                        : AppLocalizations.of(context)?.addToFavorites ??
                              'Adicionar aos favoritos',
                    tooltip: isFav
                        ? AppLocalizations.of(context)?.removeFromFavorites ??
                              'Remover dos favoritos'
                        : AppLocalizations.of(context)?.addToFavorites ??
                              'Adicionar aos favoritos',
                    onPressed: () => _toggleFavorite(userId, isFav),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard(Contact contact) {
    final displayName = contact.displayName;
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';

    return Card(
      margin: UIConstants.cardMargin,
      elevation: UIConstants.elevationM,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
      ),
      child: Container(
        padding: UIConstants.paddingM,
        child: Row(
          children: [
            // Avatar do contacto
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UIConstants.radiusM),
                color: Colors.grey[300],
              ),
              child: Center(
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Informação do contacto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Botão de convite
            OutlinedButton.icon(
              onPressed: () => _inviteContact(contact),
              icon: const Icon(Icons.share, size: 16),
              label: Text(AppLocalizations.of(context)!.inviteButton),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading indicator removido (substituído por padding simples no builder)

  String _mapSearchError(Object e) {
    final raw = e.toString();
    // Common Firestore messages
    if (raw.contains('PERMISSION_DENIED') ||
        raw.contains('Missing or insufficient permissions')) {
      return 'Sem permissões para ler utilizadores públicos (verifica regras do Firestore).';
    }
    if (raw.contains('FAILED_PRECONDITION') && raw.contains('index')) {
      return 'Índice Firestore em falta para pesquisa. Cria o índice sugerido no console.';
    }
    if (raw.contains('unavailable') || raw.contains('UNAVAILABLE')) {
      return 'Serviço temporariamente indisponível. Tenta novamente.';
    }
    if (raw.contains('network') || raw.contains('Network')) {
      return 'Problema de rede ao pesquisar. Garante ligação à internet.';
    }
    return 'Erro na pesquisa: $raw';
  }

  Future<void> _toggleFavorite(String userId, bool currentlyFav) async {
    try {
      if (currentlyFav) {
        await _favoritesRepo.remove(
          FirebaseAuth.instance.currentUser!.uid,
          userId,
        );
        setState(() {
          _favoriteIds.remove(userId);
        });
        if (mounted) {
          AppSnack.show(
            context,
            AppLocalizations.of(context)?.removedFromFavorites ??
                'Removido dos favoritos',
            type: SnackType.success,
          );
        }
      } else {
        await _favoritesRepo.add(
          FirebaseAuth.instance.currentUser!.uid,
          userId,
        );
        setState(() {
          _favoriteIds.add(userId);
        });
        if (mounted) {
          AppSnack.show(
            context,
            AppLocalizations.of(context)?.addedToFavorites ??
                'Adicionado aos favoritos!',
            type: SnackType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao actualizar favorito: $e')),
        );
      }
    }
  }

  /// Normalize phone number for database matching
  /// Uses same logic as ContactsService and UserSearchRepository to ensure consistency
  String? _normalizePhoneNumber(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) return null;

    // Remove all non-numeric characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // If starts with 00, replace with +
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }

    // Portuguese phone normalization
    if (!cleaned.startsWith('+')) {
      // Portuguese mobile: 9 digits starting with 9
      if (cleaned.length == 9 && cleaned.startsWith('9')) {
        cleaned = '+351$cleaned';
      }
      // Portuguese with national code: 351XXXXXXXXX
      else if (cleaned.length == 12 && cleaned.startsWith('351')) {
        cleaned = '+$cleaned';
      }
      // Portuguese landline/mobile: starting with 2, 3 or 9
      else if (cleaned.length == 9 && RegExp(r'^[239]').hasMatch(cleaned)) {
        cleaned = '+351$cleaned';
      }
      // Old Portuguese landline: 8 digits starting with 2-3
      else if (cleaned.length == 8 && RegExp(r'^[2-3]').hasMatch(cleaned)) {
        cleaned = '+351$cleaned';
      }
    }

    return cleaned.isEmpty ? null : cleaned;
  }
}
