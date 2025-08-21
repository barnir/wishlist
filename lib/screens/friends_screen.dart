import 'package:flutter/material.dart';
import '../services/friendship_service.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with TickerProviderStateMixin {
  final _friendshipService = FriendshipService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WishlistAppBar(
        title: 'Amigos',
        showBackButton: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_add),
            tooltip: 'Encontrar amigos',
            onSelected: (value) {
              if (value == 'explore') {
                Navigator.pushNamed(context, '/explore');
              } else if (value == 'suggestions') {
                Navigator.pushNamed(context, '/friend_suggestions');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'suggestions',
                child: Row(
                  children: [
                    Icon(Icons.contacts),
                    SizedBox(width: 8),
                    Text('Dos meus contactos'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'explore',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Procurar pessoas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(
                  text: 'Amigos',
                  icon: Icon(Icons.people),
                ),
                Tab(
                  text: 'Pedidos',
                  icon: Icon(Icons.inbox),
                ),
                Tab(
                  text: 'Enviados',
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFriendsTab(),
                _buildPendingRequestsTab(),
                _buildSentRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendshipService.getFriends(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WishlistLoadingIndicator(message: 'A carregar amigos...');
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return WishlistEmptyState(
            icon: Icons.people_outline,
            title: 'Ainda não tens amigos',
            subtitle: 'Procura pessoas na secção Explorar!',
            actionText: 'Encontrar amigos',
            onAction: () => Navigator.pushNamed(context, '/explore'),
          );
        }

        final friends = snapshot.data!;
        return ListView.builder(
          padding: UIConstants.listPadding,
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friendship = friends[index];
            return _buildFriendCard(friendship);
          },
        );
      },
    );
  }

  Widget _buildPendingRequestsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendshipService.getPendingFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WishlistLoadingIndicator(message: 'A carregar pedidos...');
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const WishlistEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nenhum pedido pendente',
            subtitle: 'Quando alguém te enviar um pedido de amizade, aparecerá aqui.',
          );
        }

        final requests = snapshot.data!;
        return ListView.builder(
          padding: UIConstants.listPadding,
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildPendingRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildSentRequestsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendshipService.getSentFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WishlistLoadingIndicator(message: 'A carregar pedidos enviados...');
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erro: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const WishlistEmptyState(
            icon: Icons.send_outlined,
            title: 'Nenhum pedido enviado',
            subtitle: 'Os teus pedidos de amizade enviados aparecerão aqui.',
          );
        }

        final sentRequests = snapshot.data!;
        return ListView.builder(
          padding: UIConstants.listPadding,
          itemCount: sentRequests.length,
          itemBuilder: (context, index) {
            final request = sentRequests[index];
            return _buildSentRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friendship) {
    // TODO: Buscar dados do utilizador amigo
    final friendName = 'Amigo'; // Placeholder
    
    return WishlistCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          radius: UIConstants.imageSizeS / 2,
          child: Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          friendName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.check_circle,
              size: UIConstants.iconSizeS,
              color: Colors.green,
            ),
            Spacing.horizontalXS,
            Text(
              'Amigo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'remove') {
              await _showRemoveFriendDialog(friendship['id']);
            } else if (value == 'block') {
              await _blockUser(friendship['id']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.person_remove),
                  SizedBox(width: 8),
                  Text('Remover amigo'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Bloquear', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          // TODO: Extrair userId do friendship data
          // Navigator.pushNamed(context, '/user_profile', arguments: friendUserId);
        },
      ),
    );
  }

  Widget _buildPendingRequestCard(Map<String, dynamic> request) {
    // TODO: Buscar dados do utilizador que enviou o pedido
    final senderName = 'Utilizador'; // Placeholder
    
    return WishlistCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          radius: UIConstants.imageSizeS / 2,
          child: Icon(
            Icons.person_add,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(
          senderName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Quer ser teu amigo',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.check,
                color: Colors.green,
                size: UIConstants.iconSizeM,
              ),
              onPressed: () => _acceptFriendRequest(request['id']),
              tooltip: 'Aceitar',
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.red,
                size: UIConstants.iconSizeM,
              ),
              onPressed: () => _rejectFriendRequest(request['id']),
              tooltip: 'Rejeitar',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestCard(Map<String, dynamic> request) {
    // TODO: Buscar dados do utilizador para quem foi enviado o pedido
    final recipientName = 'Utilizador'; // Placeholder
    
    return WishlistCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
          radius: UIConstants.imageSizeS / 2,
          child: Icon(
            Icons.schedule,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        ),
        title: Text(
          recipientName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.schedule,
              size: UIConstants.iconSizeS,
              color: Colors.orange,
            ),
            Spacing.horizontalXS,
            Text(
              'Pedido pendente',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.cancel_outlined,
            color: Colors.red,
            size: UIConstants.iconSizeM,
          ),
          onPressed: () => _cancelFriendRequest(request['id']),
          tooltip: 'Cancelar pedido',
        ),
      ),
    );
  }

  Future<void> _acceptFriendRequest(String friendshipId) async {
    try {
      await _friendshipService.acceptFriendRequest(friendshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido de amizade aceite!')),
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

  Future<void> _rejectFriendRequest(String friendshipId) async {
    try {
      await _friendshipService.rejectFriendRequest(friendshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido de amizade rejeitado.')),
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

  Future<void> _cancelFriendRequest(String friendshipId) async {
    try {
      await _friendshipService.removeFriend(friendshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido de amizade cancelado.')),
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

  Future<void> _blockUser(String friendshipId) async {
    try {
      await _friendshipService.blockUser(friendshipId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilizador bloqueado.')),
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

  Future<void> _showRemoveFriendDialog(String friendshipId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover amigo'),
        content: const Text('Tens a certeza que queres remover este amigo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _friendshipService.removeFriend(friendshipId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Amigo removido.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}