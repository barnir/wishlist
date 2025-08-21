import 'package:flutter/material.dart';
import '../services/contacts_service.dart';
import '../services/friendship_service.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';

class FriendSuggestionsScreen extends StatefulWidget {
  const FriendSuggestionsScreen({super.key});

  @override
  State<FriendSuggestionsScreen> createState() => _FriendSuggestionsScreenState();
}

class _FriendSuggestionsScreenState extends State<FriendSuggestionsScreen> {
  final _contactsService = ContactsService();
  final _friendshipService = FriendshipService();
  
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
      final granted = await _contactsService.requestContactsPermission();
      
      if (granted) {
        setState(() => _hasPermission = true);
        await _loadSuggestions();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão para aceder aos contactos foi negada.'),
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
      final suggestions = await _contactsService.getFriendSuggestions();
      if (mounted) {
        setState(() => _suggestions = suggestions);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar sugestões: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WishlistAppBar(
        title: 'Sugestões de Amigos',
        actions: [
          if (_hasPermission)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : _loadSuggestions,
              tooltip: 'Atualizar sugestões',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const WishlistLoadingIndicator(
        message: 'A procurar amigos nos teus contactos...',
      );
    }

    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    if (_suggestions.isEmpty) {
      return WishlistEmptyState(
        icon: Icons.contacts_outlined,
        title: 'Nenhuma sugestão encontrada',
        subtitle: 'Não encontramos amigos registados nos teus contactos.',
        actionText: 'Atualizar',
        onAction: _loadSuggestions,
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
              Icons.contacts_outlined,
              size: UIConstants.iconSizeXXL,
              color: Theme.of(context).colorScheme.primary.withAlpha(
                (255 * UIConstants.opacityLight).round(),
              ),
            ),
            Spacing.l,
            Text(
              'Acesso aos Contactos',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            Spacing.m,
            Text(
              'Para te sugerirmos amigos, precisamos de acesso aos teus contactos. '
              'Assim podemos encontrar pessoas que conheces e que já estão registadas na app.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            Spacing.l,
            WishlistButton(
              text: 'Permitir Acesso aos Contactos',
              icon: Icons.contacts,
              onPressed: _requestPermissionAndLoad,
              isLoading: _isLoading,
              width: double.infinity,
            ),
            Spacing.s,
            WishlistButton(
              text: 'Talvez mais tarde',
              onPressed: () => Navigator.of(context).pop(),
              isPrimary: false,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: UIConstants.paddingM,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: UIConstants.iconSizeM,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Spacing.horizontalS,
                  Text(
                    'Sugestões dos Contactos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Spacing.xs,
              Text(
                'Encontrámos ${_suggestions.length} ${_suggestions.length == 1 ? 'pessoa' : 'pessoas'} dos teus contactos que ${_suggestions.length == 1 ? 'está registada' : 'estão registadas'} na app.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: UIConstants.listPadding,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              return _buildSuggestionCard(_suggestions[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final displayName = suggestion['display_name'] as String? ?? 'Sem nome';
    final contactName = suggestion['contact_name'] as String?;
    final suggestionReason = suggestion['suggestion_reason'] as String? ?? '';
    final userId = suggestion['id'] as String;
    
    return WishlistCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          radius: UIConstants.imageSizeS / 2,
          child: Icon(
            Icons.person_add,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            size: UIConstants.iconSizeM,
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
            if (contactName != null && contactName != displayName) ...[
              Text(
                'Contacto: $contactName',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
              Spacing.xs,
            ],
            Row(
              children: [
                Icon(
                  Icons.contacts,
                  size: UIConstants.iconSizeS,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Spacing.horizontalXS,
                Expanded(
                  child: Text(
                    suggestionReason,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: WishlistButton(
          text: 'Adicionar',
          onPressed: () => _sendFriendRequest(userId, displayName),
          isPrimary: true,
          width: 100,
          height: 36,
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

  Future<void> _sendFriendRequest(String friendId, String friendName) async {
    try {
      await _friendshipService.sendFriendRequest(friendId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pedido enviado a $friendName!')),
        );
        
        // Remover da lista de sugestões
        setState(() {
          _suggestions.removeWhere((suggestion) => suggestion['id'] == friendId);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar pedido: $e')),
        );
      }
    }
  }
}