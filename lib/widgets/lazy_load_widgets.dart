import 'package:flutter/material.dart';
import 'package:mywishstash/utils/performance_utils.dart';

/// Widget para implementar lazy loading em listas grandes com performance otimizada
class LazyLoadListView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int limit) loadPage;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final int pageSize;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget Function(BuildContext, int)? separatorBuilder;

  const LazyLoadListView({
    super.key,
    required this.loadPage,
    required this.itemBuilder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.pageSize = 20,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.separatorBuilder,
  });

  @override
  State<LazyLoadListView<T>> createState() => _LazyLoadListViewState<T>();
}

class _LazyLoadListViewState<T> extends State<LazyLoadListView<T>> 
    with PerformanceOptimizedState {
  late ScrollController _scrollController;
  List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasReachedEnd = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialPage();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadInitialPage() async {
    if (_isLoading) return;
    
    safeSetState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.loadPage(0, widget.pageSize);
      if (!mounted) return;

      safeSetState(() {
        _items = newItems;
        _currentPage = 0;
        _hasReachedEnd = newItems.length < widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      safeSetState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || _hasReachedEnd) return;

    safeSetState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.loadPage(_currentPage + 1, widget.pageSize);
      if (!mounted) return;

      safeSetState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasReachedEnd = newItems.length < widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      safeSetState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasReachedEnd = false;
    _items.clear();
    await _loadInitialPage();
  }

  @override
  Widget build(BuildContext context) {
    // Show error state
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ?? 
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialPage,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
    }

    // Show empty state
    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ?? 
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 48),
              SizedBox(height: 16),
              Text('No items found'),
            ],
          ),
        );
    }

    // Show loading for initial load
    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget ?? 
        const Center(child: CircularProgressIndicator());
    }

    // Build the list
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: _items.length + (_isLoading || !_hasReachedEnd ? 1 : 0),
        separatorBuilder: widget.separatorBuilder ?? 
          (context, index) => const SizedBox.shrink(),
        itemBuilder: (context, index) {
          // Show item
          if (index < _items.length) {
            return widget.itemBuilder(context, _items[index], index);
          }
          
          // Show loading indicator at the end
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

/// Grid version of lazy loading
class LazyLoadGridView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page, int limit) loadPage;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final int pageSize;
  final int crossAxisCount;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const LazyLoadGridView({
    super.key,
    required this.loadPage,
    required this.itemBuilder,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.pageSize = 20,
    this.crossAxisCount = 2,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.childAspectRatio = 1.0,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<LazyLoadGridView<T>> createState() => _LazyLoadGridViewState<T>();
}

class _LazyLoadGridViewState<T> extends State<LazyLoadGridView<T>> 
    with PerformanceOptimizedState {
  late ScrollController _scrollController;
  List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasReachedEnd = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialPage();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadInitialPage() async {
    if (_isLoading) return;
    
    safeSetState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.loadPage(0, widget.pageSize);
      if (!mounted) return;

      safeSetState(() {
        _items = newItems;
        _currentPage = 0;
        _hasReachedEnd = newItems.length < widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      safeSetState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || _hasReachedEnd) return;

    safeSetState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.loadPage(_currentPage + 1, widget.pageSize);
      if (!mounted) return;

      safeSetState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasReachedEnd = newItems.length < widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      safeSetState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> refresh() async {
    _currentPage = 0;
    _hasReachedEnd = false;
    _items.clear();
    await _loadInitialPage();
  }

  @override
  Widget build(BuildContext context) {
    // Handle error and empty states like ListView version
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ?? 
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Error: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadInitialPage,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget ?? 
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.grid_view_outlined, size: 48),
              SizedBox(height: 16),
              Text('No items found'),
            ],
          ),
        );
    }

    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget ?? 
        const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: GridView.builder(
        controller: _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          mainAxisSpacing: widget.mainAxisSpacing ?? 8,
          crossAxisSpacing: widget.crossAxisSpacing ?? 8,
          childAspectRatio: widget.childAspectRatio,
        ),
        itemCount: _items.length + (_isLoading || !_hasReachedEnd ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _items.length) {
            return widget.itemBuilder(context, _items[index], index);
          }
          
          // Loading indicator at the end
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
