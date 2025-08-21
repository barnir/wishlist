import 'package:flutter/material.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';
import '../services/friendship_service.dart';
import '../models/friendship.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _supabaseDatabaseService = SupabaseDatabaseService();
  final _friendshipService = FriendshipService();
  final _searchController = TextEditingController();
  String _termoPesquisa = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _termoPesquisa = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WishlistAppBar(
        title: 'Explorar',
        showBackButton: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: UIConstants.paddingM,
            child: WishlistTextField(
              label: 'Pesquisar perfis ou wishlists...',
              prefixIcon: const Icon(Icons.search),
              controller: _searchController,
            ),
          ),
          Expanded(
            child: ListView(
              // Changed to ListView to contain multiple sections
              children: [
                Padding(
                  padding: UIConstants.paddingM,
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: UIConstants.iconSizeM,
                      ),
                      Spacing.horizontalS,
                      Text(
                        'Perfis',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabaseDatabaseService.getPublicUsersLegacy(
                    searchTerm: _termoPesquisa,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return WishlistEmptyState(
                        icon: Icons.people_outline,
                        title: 'Nenhum perfil encontrado',
                        subtitle: _termoPesquisa.isEmpty
                            ? 'Comece a pesquisar para encontrar amigos!'
                            : 'Tente pesquisar com outros termos.',
                      );
                    }

                    final profiles = snapshot.data!;

                    return ListView.builder(
                      shrinkWrap: true, // Important for nested ListViews
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable scrolling for nested ListView
                      itemCount: profiles.length,
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        return _buildUserProfileCard(profile);
                      },
                    );
                  },
                ),
                Padding(
                  padding: UIConstants.paddingVerticalM,
                  child: Divider(
                    thickness: 1,
                    color: Theme.of(context).colorScheme.outline.withAlpha(76),
                  ),
                ),

                Padding(
                  padding: UIConstants.paddingM,
                  child: Row(
                    children: [
                      Icon(
                        Icons.card_giftcard_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: UIConstants.iconSizeM,
                      ),
                      Spacing.horizontalS,
                      Text(
                        'Wishlists Públicas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabaseDatabaseService.getPublicWishlistsLegacy(
                    searchTerm: _termoPesquisa,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return WishlistEmptyState(
                        icon: Icons.card_giftcard_outlined,
                        title: 'Nenhuma wishlist encontrada',
                        subtitle: _termoPesquisa.isEmpty
                            ? 'Não há wishlists públicas disponíveis.'
                            : 'Tente pesquisar com outros termos.',
                      );
                    }

                    final wishlists = snapshot.data!;

                    return ListView.builder(
                      shrinkWrap: true, // Important for nested ListViews
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable scrolling for nested ListView
                      itemCount: wishlists.length,
                      itemBuilder: (context, index) {
                        final wishlist = wishlists[index];
                        final name = wishlist['name'] as String? ?? 'Sem nome';
                        // ownerName is not directly available in the wishlists table in Supabase without a join.
                        // For now, we'll just display a placeholder or fetch it separately if needed.
                        final ownerName = 'Desconhecido'; // Placeholder
                        final imageUrl = wishlist.containsKey('image_url')
                            ? wishlist['image_url']
                            : null;

                        return WishlistCard(
                          margin: UIConstants.cardMargin,
                          child: ListTile(
                            leading: SizedBox(
                              width: UIConstants.imageSizeM,
                              height: UIConstants.imageSizeM,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(UIConstants.radiusS),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(UIConstants.radiusS),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: UIConstants.strokeWidthMedium,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(UIConstants.radiusS),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.card_giftcard,
                                              size: UIConstants.iconSizeL,
                                              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(UIConstants.radiusS),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.card_giftcard,
                                            size: UIConstants.iconSizeL,
                                            color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Proprietário: $ownerName',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.public,
                                      size: UIConstants.iconSizeS,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    Spacing.horizontalXS,
                                    Text(
                                      'Pública',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              size: UIConstants.iconSizeS,
                              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                            ),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/wishlist_details',
                                arguments: wishlist['id'],
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(Map<String, dynamic> profile) {
    final displayName = profile['display_name'] as String? ?? 'Sem nome';
    final userId = profile['id'] as String;

    return FutureBuilder<FriendshipStatus?>(
      future: _friendshipService.getFriendshipStatus(userId),
      builder: (context, friendshipSnapshot) {
        final friendshipStatus = friendshipSnapshot.data;
        
        return WishlistCard(
          margin: UIConstants.cardMargin,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              radius: UIConstants.imageSizeS / 2,
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: UIConstants.iconSizeM,
              ),
            ),
            title: Text(
              displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: _buildFriendshipStatusWidget(friendshipStatus),
            trailing: _buildFriendshipActionButton(userId, friendshipStatus),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/user_profile',
                arguments: userId,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFriendshipStatusWidget(FriendshipStatus? status) {
    if (status == null) {
      return Text(
        'Ver perfil',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case FriendshipStatus.accepted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Amigo';
        break;
      case FriendshipStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Pedido pendente';
        break;
      case FriendshipStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejeitado';
        break;
      case FriendshipStatus.blocked:
        statusColor = Colors.red;
        statusIcon = Icons.block;
        statusText = 'Bloqueado';
        break;
    }

    return Row(
      children: [
        Icon(
          statusIcon,
          size: UIConstants.iconSizeS,
          color: statusColor,
        ),
        Spacing.horizontalXS,
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFriendshipActionButton(String userId, FriendshipStatus? status) {
    if (status == null) {
      return IconButton(
        icon: Icon(
          Icons.person_add,
          color: Theme.of(context).colorScheme.primary,
          size: UIConstants.iconSizeM,
        ),
        onPressed: () => _sendFriendRequest(userId),
        tooltip: 'Adicionar amigo',
      );
    }

    switch (status) {
      case FriendshipStatus.accepted:
        return Icon(
          Icons.check_circle,
          color: Colors.green,
          size: UIConstants.iconSizeM,
        );
      case FriendshipStatus.pending:
        return Icon(
          Icons.schedule,
          color: Colors.orange,
          size: UIConstants.iconSizeM,
        );
      case FriendshipStatus.rejected:
      case FriendshipStatus.blocked:
        return Icon(
          Icons.block,
          color: Colors.red,
          size: UIConstants.iconSizeM,
        );
    }
  }

  Future<void> _sendFriendRequest(String friendId) async {
    try {
      await _friendshipService.sendFriendRequest(friendId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido de amizade enviado!')),
        );
        setState(() {}); // Atualizar a UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
}
