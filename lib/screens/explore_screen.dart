import 'dart:async';
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
  final _scrollController = ScrollController();
  
  // Search state
  String _searchQuery = '';
  Timer? _debounceTimer;
  
  // Paginação
  static const int _pageSize = 15;
  List<Map<String, dynamic>> _users = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _isInitialLoading = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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
          _currentPage = 0;
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
      _currentPage = 0;
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
      final newUsers = await _supabaseDatabaseService.searchUsersPaginated(
        _searchQuery,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (mounted) {
        setState(() {
          if (newUsers.length < _pageSize) {
            _hasMoreData = false;
          }
          _users.addAll(newUsers);
          _currentPage++;
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
              label: 'Pesquisar utilizadores...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_searchQuery.isEmpty) {
      return const WishlistEmptyState(
        icon: Icons.search,
        title: 'Pesquisar utilizadores',
        subtitle: 'Digite um nome ou email para encontrar utilizadores e as suas wishlists públicas.',
      );
    }

    if (_isInitialLoading) {
      return const WishlistLoadingIndicator(message: 'A pesquisar...');
    }

    if (_users.isEmpty && !_isLoading) {
      return const WishlistEmptyState(
        icon: Icons.person_search,
        title: 'Nenhum resultado',
        subtitle: 'Não foram encontrados utilizadores com esse termo.',
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
            return _buildLoadingIndicator();
          }
          return _buildUserCard(_users[index]);
        },
      ),
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

  Widget _buildLoadingIndicator() {
    return Container(
      padding: UIConstants.paddingM,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Spacing.horizontalM,
          Text(
            'A carregar mais resultados...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}