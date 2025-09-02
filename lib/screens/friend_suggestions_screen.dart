import 'package:flutter/material.dart';
import '../services/contacts_service.dart';
import '../services/favorites_service.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';

class FriendSuggestionsScreen extends StatefulWidget {
  const FriendSuggestionsScreen({super.key});

  @override
  State<FriendSuggestionsScreen> createState() => _FriendSuggestionsScreenState();
}

class _FriendSuggestionsScreenState extends State<FriendSuggestionsScreen> {
  final _contactsService = ContactsService();
  final _favoritesService = FavoritesService();
  
  bool _isLoading = false;
  bool _hasPermission = false;
  List<Map<String, dynamic>> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadSuggestions();
  }

  Future<void> _checkPermissionAndLoadSuggestions() async {
    setState(() => _isLoading = true);
    
    try {
      _hasPermission = await _contactsService.hasContactsPermission();
      
      if (_hasPermission) {
        await _loadSuggestions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _requestPermissionAndLoad() async {
    setState(() => _isLoading = true);
    
    try {
      _hasPermission = await _contactsService.requestContactsPermission();
      
      if (_hasPermission) {
        await _loadSuggestions();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão de contactos necessária para sugestões'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      final suggestions = await _contactsService.findRegisteredFriends();
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar sugestões: $e')),
        );
      }
    }
  }

  Future<void> _addToFavorites(String userId) async {
    try {
      await _favoritesService.addFavorite(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.addedToFavorites ?? 'Adicionado aos favoritos!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WishlistAppBar(
  title: AppLocalizations.of(context)?.contactSuggestionsTitle ?? 'Sugestões dos Contactos',
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return WishlistLoadingIndicator(
        message: AppLocalizations.of(context)?.loadingSuggestions ?? 'A carregar sugestões...',
      );
    }

    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    if (_suggestions.isEmpty) {
      return WishlistEmptyState(
        icon: Icons.contacts,
        title: AppLocalizations.of(context)?.noSuggestionsTitle ?? 'Nenhuma sugestão',
        subtitle: AppLocalizations.of(context)?.noSuggestionsSubtitle ?? 'Não foram encontrados utilizadores da app nos seus contactos.',
      );
    }

    return _buildSuggestionsList();
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: UIConstants.paddingL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts,
              size: UIConstants.iconSizeXXL,
              color: Theme.of(context).colorScheme.primary,
            ),
            Spacing.l,
            Text(
              AppLocalizations.of(context)?.contactsAccessTitle ?? 'Acesso aos Contactos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Spacing.m,
            Text(
              AppLocalizations.of(context)?.contactsAccessExplanation ?? 'Para encontrar amigos dos seus contactos que já usam a app, precisamos de acesso à sua lista de contactos.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            Spacing.l,
            ElevatedButton(
              onPressed: _requestPermissionAndLoad,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(AppLocalizations.of(context)?.grantContactsAccess ?? 'Permitir Acesso aos Contactos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.builder(
      padding: UIConstants.listPadding,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        return _buildSuggestionCard(_suggestions[index]);
      },
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final displayName = suggestion['display_name'] as String? ?? 'Utilizador';
    final email = suggestion['email'] as String?;
    final phoneNumber = suggestion['phone_number'] as String?;
    final userId = suggestion['id'] as String;

    return WishlistCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email != null && email.isNotEmpty)
              Text(
                email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            if (phoneNumber != null && phoneNumber.isNotEmpty)
              Text(
                phoneNumber,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'favorite') {
              await _addToFavorites(userId);
            } else if (value == 'profile') {
              Navigator.pushNamed(
                context,
                '/user_profile',
                arguments: userId,
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'favorite',
              child: Row(
                children: [
                  const Icon(Icons.star),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)?.addToFavorites ?? 'Adicionar aos favoritos'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)?.viewProfile ?? 'Ver perfil'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/user_profile',
            arguments: userId,
          );
        },
      ),
    );
  }
}