import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_database_service.dart';
import '../services/friendship_service.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';
import '../models/friendship.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _supabaseDatabaseService = SupabaseDatabaseService();
  final _friendshipService = FriendshipService();

  Map<String, dynamic>? _userProfile;
  FriendshipStatus? _friendshipStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadFriendshipStatus();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _supabaseDatabaseService.getUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar perfil: $e')),
        );
      }
    }
  }

  Future<void> _loadFriendshipStatus() async {
    try {
      final status = await _friendshipService.getFriendshipStatus(widget.userId);
      if (mounted) {
        setState(() => _friendshipStatus = status);
      }
    } catch (e) {
      // Falhar silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: WishlistAppBar(title: 'Perfil'),
        body: const WishlistLoadingIndicator(message: 'A carregar perfil...'),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: WishlistAppBar(title: 'Perfil'),
        body: const WishlistEmptyState(
          icon: Icons.person_off,
          title: 'Perfil não encontrado',
          subtitle: 'Este utilizador pode ter sido removido.',
        ),
      );
    }

    final displayName = _userProfile!['display_name'] as String? ?? 'Utilizador';
    final email = _userProfile!['email'] as String?;

    return Scaffold(
      appBar: WishlistAppBar(
        title: displayName,
        actions: [
          _buildFriendshipActionButton(),
        ],
      ),
      body: Column(
        children: [
          _buildProfileHeader(),
          _buildTabSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final displayName = _userProfile!['display_name'] as String? ?? 'Utilizador';
    final email = _userProfile!['email'] as String?;

    return Container(
      width: double.infinity,
      padding: UIConstants.paddingL,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: UIConstants.imageSizeXL / 2,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.person,
              size: UIConstants.iconSizeXXL / 2,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          Spacing.m,
          Text(
            displayName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          if (email != null && email.isNotEmpty) ...[
            Spacing.xs,
            Text(
              email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          Spacing.m,
          _buildFriendshipStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildFriendshipStatusBadge() {
    if (_friendshipStatus == null) {
      return const SizedBox.shrink();
    }

    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (_friendshipStatus!) {
      case FriendshipStatus.accepted:
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle;
        badgeText = 'Amigo';
        break;
      case FriendshipStatus.pending:
        badgeColor = Colors.orange;
        badgeIcon = Icons.schedule;
        badgeText = 'Pedido pendente';
        break;
      case FriendshipStatus.rejected:
        badgeColor = Colors.red;
        badgeIcon = Icons.cancel;
        badgeText = 'Rejeitado';
        break;
      case FriendshipStatus.blocked:
        badgeColor = Colors.red;
        badgeIcon = Icons.block;
        badgeText = 'Bloqueado';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(51),
        borderRadius: BorderRadius.circular(UIConstants.radiusL),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: UIConstants.iconSizeS, color: badgeColor),
          Spacing.horizontalXS,
          Text(
            badgeText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendshipActionButton() {
    if (_friendshipStatus == null) {
      return IconButton(
        icon: Icon(
          Icons.person_add,
          color: Theme.of(context).colorScheme.primary,
        ),
        onPressed: _sendFriendRequest,
        tooltip: 'Adicionar amigo',
      );
    }

    switch (_friendshipStatus!) {
      case FriendshipStatus.accepted:
        return PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'remove') {
              await _showRemoveFriendDialog();
            } else if (value == 'block') {
              await _blockUser();
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
        );
      case FriendshipStatus.pending:
        return Icon(
          Icons.schedule,
          color: Colors.orange,
        );
      case FriendshipStatus.rejected:
      case FriendshipStatus.blocked:
        return Icon(
          Icons.block,
          color: Colors.red,
        );
    }
  }

  Widget _buildTabSection() {
    return Expanded(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'Wishlists Públicas', icon: Icon(Icons.list_alt)),
                  Tab(text: 'Sobre', icon: Icon(Icons.info_outline)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPublicWishlistsTab(),
                  _buildAboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicWishlistsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabaseDatabaseService.getPublicWishlistsForUser(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WishlistLoadingIndicator(message: 'A carregar wishlists...');
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const WishlistEmptyState(
            icon: Icons.list_alt_outlined,
            title: 'Nenhuma wishlist pública',
            subtitle: 'Este utilizador ainda não tem wishlists públicas.',
          );
        }

        final wishlists = snapshot.data!;
        return ListView.builder(
          padding: UIConstants.listPadding,
          itemCount: wishlists.length,
          itemBuilder: (context, index) {
            return _buildWishlistCard(wishlists[index]);
          },
        );
      },
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> wishlist) {
    final name = wishlist['name'] as String? ?? 'Sem nome';
    final imageUrl = wishlist['image_url'] as String?;

    return WishlistCard(
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
        subtitle: Row(
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
  }

  Widget _buildAboutTab() {
    final displayName = _userProfile!['display_name'] as String? ?? 'Utilizador';
    
    return Padding(
      padding: UIConstants.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WishlistCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: UIConstants.iconSizeM,
                    ),
                    Spacing.horizontalS,
                    Text(
                      'Informações do Perfil',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Spacing.m,
                _buildInfoRow('Nome', displayName),
                if (_userProfile!['email'] != null)
                  _buildInfoRow('Email', _userProfile!['email'] as String),
                _buildInfoRow('Membro desde', 'Recentemente'), // TODO: Calcular data real
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: UIConstants.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendFriendRequest() async {
    try {
      await _friendshipService.sendFriendRequest(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido de amizade enviado!')),
        );
        _loadFriendshipStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  Future<void> _showRemoveFriendDialog() async {
    final friendship = await _friendshipService.getFriendship(widget.userId);
    if (friendship == null) return;

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remover amigo'),
          content: Text('Tens a certeza que queres remover ${_userProfile!['display_name']} dos teus amigos?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _friendshipService.removeFriend(friendship.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Amigo removido.')),
                    );
                    _loadFriendshipStatus();
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

  Future<void> _blockUser() async {
    final friendship = await _friendshipService.getFriendship(widget.userId);
    if (friendship == null) return;

    try {
      await _friendshipService.blockUser(friendship.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilizador bloqueado.')),
        );
        _loadFriendshipStatus();
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