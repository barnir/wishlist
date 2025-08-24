import 'package:flutter/material.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _supabaseDatabaseService = SupabaseDatabaseService();
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
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          Expanded(
            child: _termoPesquisa.isEmpty
                ? const WishlistEmptyState(
                    icon: Icons.search,
                    title: 'Pesquisar utilizadores',
                    subtitle: 'Digite um nome ou email para encontrar utilizadores e as suas wishlists públicas.',
                  )
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabaseDatabaseService.searchUsers(_termoPesquisa),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WishlistLoadingIndicator(message: 'A pesquisar...');
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: UIConstants.iconSizeXL,
                  color: Theme.of(context).colorScheme.error,
                ),
                Spacing.m,
                Text(
                  'Erro na pesquisa',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Spacing.s,
                Text(
                  '${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const WishlistEmptyState(
            icon: Icons.person_search,
            title: 'Nenhum resultado',
            subtitle: 'Não foram encontrados utilizadores com esse termo.',
          );
        }

        final users = snapshot.data!;
        return ListView.builder(
          padding: UIConstants.listPadding,
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index]);
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final displayName = user['display_name'] as String? ?? 'Utilizador';
    final email = user['email'] as String?;
    final userId = user['id'] as String;

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
        subtitle: email != null && email.isNotEmpty
            ? Text(
                email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: UIConstants.iconSizeS,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
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