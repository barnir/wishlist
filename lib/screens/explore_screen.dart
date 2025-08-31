import 'dart:async';
import 'package:flutter/material.dart';
import '../theme_extensions.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:wishlist_app/services/firebase_database_service.dart'; // legacy
import 'package:wishlist_app/repositories/user_search_repository.dart';
import 'package:wishlist_app/models/user_profile.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';
import 'package:wishlist_app/utils/app_logger.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with TickerProviderStateMixin {
  final _userSearchRepo = UserSearchRepository();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  
  // Tab controller
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

  // Contacts state
  List<Map<String, dynamic>> _friendsInApp = [];
  List<Contact> _contactsToInvite = [];
  bool _isLoadingContacts = false;
  bool _hasContactsPermission = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _checkContactsPermission();
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    if (_searchQuery.isEmpty) return;

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

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData || _searchQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final page = await _userSearchRepo.searchPage(
        query: _searchQuery,
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      if (mounted) {
        setState(() {
          _users.addAll(page.items);
          _lastDoc = page.lastDoc;
          _hasMoreData = page.hasMore;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na pesquisa: $e')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitialData();
  }

  // ============== CONTACTS METHODS ==============

  Future<void> _checkContactsPermission() async {
    try {
      // Primeiro só verificamos se já temos permissão, sem solicitar
      final hasPermission = await FlutterContacts.requestPermission(readonly: true);
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
          final grantedMsg = AppLocalizations.of(context)?.contactsPermissionDescription ?? 'Permissão concedida! A descobrir contactos...';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(grantedMsg),
              backgroundColor: Theme.of(context).extension<AppSemanticColors>()!.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Permissão negada - mostrar explicação
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.contactsPermissionRequired),
              action: SnackBarAction(
                label: 'Tentar novamente',
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
            content: Text(AppLocalizations.of(context)!.errorRequestingPermission(e.toString())),
            action: SnackBarAction(
              label: 'Configurações',
              onPressed: () {
                // TODO: Abrir configurações da app se necessário
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vai às Configurações > Apps > WishlistApp > Permissões para ativar manualmente'),
                    duration: Duration(seconds: 4),
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

  logD('Start contacts load', tag: 'UI');
      
      // Verifica permissão novamente antes de prosseguir
      final stillHasPermission = await FlutterContacts.requestPermission(readonly: true);
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
      
  logD('Contacts fetched', tag: 'UI', data: {'contacts': contacts.length});
      
      // Filtra contactos que têm números de telefone
      final contactsWithPhones = contacts.where((c) => c.phones.isNotEmpty).toList();
  logD('Contacts with phones', tag: 'UI', data: {'withPhones': contactsWithPhones.length});
      
      // Por agora, todos os contactos vão para convites (implementação básica)
      // TODO: Implementar descoberta real de utilizadores na app
      final friends = <Map<String, dynamic>>[];
      final inviteContacts = contactsWithPhones;

      if (mounted) {
        setState(() {
          _friendsInApp = friends;
          _contactsToInvite = inviteContacts;
          _isLoadingContacts = false;
        });
        
        logD('Contacts state updated', tag: 'UI', data: {'friends': friends.length, 'invite': inviteContacts.length});
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
          errorMessage = 'Permissão de contactos foi revogada. Tenta novamente.';
          setState(() {
            _hasContactsPermission = false;
          });
        } else {
          errorMessage = AppLocalizations.of(context)!.errorLoadingContacts(e.toString());
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
      
      final message = 'Olá $name! Estou a usar o WishlistApp para gerir as minhas listas de desejos. Experimenta também! 🎁';
      final fullMessage = '$message\n\n${l10n.invitePlayStoreMessage}';
      
  // ignore: deprecated_member_use
      // ignore: deprecated_member_use
      await Share.share(
        fullMessage,
        subject: l10n.inviteSubject,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorSendingInvite(e.toString()))),
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
            Tab(
              icon: const Icon(Icons.search),
              text: l10n.searchTab,
            ),
            Tab(
              icon: const Icon(Icons.people),
              text: l10n.friendsTab,
            ),
            Tab(
              icon: const Icon(Icons.person_add),
              text: l10n.inviteTab,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildFriendsTab(),
          _buildInviteTab(),
        ],
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
        Expanded(
          child: _buildSearchContent(),
        ),
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
      final l10n = AppLocalizations.of(context)!;
      return WishlistLoadingIndicator(message: l10n.searching);
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
              child: Center(child: Text(AppLocalizations.of(context)!.loadingMoreResults)),
            );
          }
          return _buildUserCard(_users[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    final displayName = user.displayName ?? 'Utilizador';
    final email = user.email;
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
          Navigator.pushNamed(
            context,
            '/user_profile',
            arguments: userId,
          );
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
                          isPrivate ? Icons.lock_outlined : Icons.public_outlined,
                          size: 14,
                          color: isPrivate 
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
              isPrivate
                ? (AppLocalizations.of(context)?.privateProfileBadge ?? 'Perfil privado')
                : (AppLocalizations.of(context)?.publicProfileBadge ?? 'Perfil público'),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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

  Widget _buildFriendsTab() {
    if (!_hasContactsPermission) {
      return _buildPermissionRequest();
    }

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

    if (_friendsInApp.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.noFriendsFound),
            const SizedBox(height: 8),
            Text(
              l10n.noFriendsFoundDescription,
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
        itemCount: _friendsInApp.length,
        itemBuilder: (context, index) {
          return _buildFriendCard(_friendsInApp[index]);
        },
      ),
    );
  }

  Widget _buildInviteTab() {
    if (!_hasContactsPermission) {
      return _buildPermissionRequest();
    }

    if (_isLoadingContacts) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.loadingContacts),
          ],
        ),
      );
    }

    if (_contactsToInvite.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_add_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.allFriendsUseApp),
            const SizedBox(height: 8),
            Text(
              l10n.noContactsToInvite,
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
        itemCount: _contactsToInvite.length,
        itemBuilder: (context, index) {
          return _buildInviteCard(_contactsToInvite[index]);
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
            const Icon(
              Icons.contacts,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.discoverFriends,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.contactsPermissionDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestContactsPermission,
              icon: const Icon(Icons.contacts),
              label: Text(l10n.allowContactsAccess),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    
    final displayName = user['display_name'] as String? ?? contact['name'] as String? ?? 'Utilizador';
    final email = user['email'] as String?;
    final userId = user['id'] as String;
    final contactName = contact['name'] as String? ?? displayName;

    return Card(
      margin: UIConstants.cardMargin,
      elevation: UIConstants.elevationM,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/user_profile',
            arguments: userId,
          );
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
              
              // Badge de amigo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people,
                      size: 14,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.friendBadge,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading indicator removido (substituído por padding simples no builder)
}