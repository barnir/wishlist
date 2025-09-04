import 'package:mywishstash/models/wishlist.dart';
import 'package:mywishstash/models/wish_item.dart';
import 'package:mywishstash/models/user_profile.dart';

/// Interface base para repositórios
abstract class Repository<T> {
  Future<T?> getById(String id);
  Future<List<T>> getAll();
  Future<String> create(T item);
  Future<void> update(String id, T item);
  Future<void> delete(String id);
}

/// Interface específica para Wishlist Repository
abstract class IWishlistRepository extends Repository<Wishlist> {
  Future<List<Wishlist>> getByUserId(String userId);
  Future<List<Wishlist>> getPublicWishlists({int? limit});
  Future<void> updateVisibility(String id, bool isPublic);
  Future<Map<String, int>> getStatistics(String userId);
  Stream<List<Wishlist>> watchUserWishlists(String userId);
}

/// Interface específica para WishItem Repository
abstract class IWishItemRepository extends Repository<WishItem> {
  Future<List<WishItem>> getByWishlistId(String wishlistId);
  Future<List<WishItem>> searchItems(String query, {String? userId});
  Future<void> updateStatus(String id, String status);
  Future<void> updateQuantity(String id, int quantity);
  Future<List<WishItem>> getRecentItems(String userId, {int limit = 10});
  Stream<List<WishItem>> watchWishlistItems(String wishlistId);
}

/// Interface específica para UserProfile Repository  
abstract class IUserProfileRepository extends Repository<UserProfile> {
  Future<UserProfile?> getByUserId(String userId);
  Future<void> updatePhoneVerified(String userId, bool verified);
  Future<void> updateRegistrationComplete(String userId, bool complete);
  Future<List<UserProfile>> searchProfiles(String query);
  Stream<UserProfile?> watchProfile(String userId);
}

/// Interface para repositórios com cache
abstract class ICacheableRepository<T> extends Repository<T> {
  Future<void> clearCache();
  Future<void> invalidateCache(String id);
  bool isInCache(String id);
}

/// Interface para repositórios com paginação
abstract class IPaginatedRepository<T> extends Repository<T> {
  Future<PaginatedResult<T>> getPaginated({
    int page = 0,
    int limit = 20,
    String? orderBy,
    bool descending = false,
    Map<String, dynamic>? filters,
  });
}

/// Resultado paginado
class PaginatedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
}

/// Interface para repositórios com sync offline
abstract class IOfflineSyncRepository<T> extends Repository<T> {
  Future<void> syncToServer();
  Future<void> syncFromServer();
  Future<List<T>> getPendingSync();
  Stream<SyncStatus> watchSyncStatus();
}

/// Status de sincronização
enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
}

/// Interface para repositórios com analytics
abstract class IAnalyticsRepository<T> extends Repository<T> {
  Future<void> trackOperation(String operation, Map<String, dynamic> metadata);
  Future<Map<String, dynamic>> getUsageStatistics();
  Future<void> recordPerformanceMetric(String metric, Duration duration);
}

/// Mixin para implementações comuns de repositório
mixin RepositoryMixin<T> {
  /// Validação de ID
  void validateId(String id) {
    if (id.isEmpty) {
      throw ArgumentError('ID cannot be empty');
    }
  }

  /// Validação de item
  void validateItem(T item) {
    if (item == null) {
      throw ArgumentError('Item cannot be null');
    }
  }

  /// Manipulação de erros padrão
  Never handleError(String operation, Object error, [StackTrace? stackTrace]) {
    throw RepositoryException(
      operation: operation,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  /// Cache key helper
  String cacheKey(String prefix, String id) => '${prefix}_$id';
}

/// Exception específica para repositórios
class RepositoryException implements Exception {
  final String operation;
  final Object originalError;
  final StackTrace? stackTrace;

  const RepositoryException({
    required this.operation,
    required this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'RepositoryException during $operation: $originalError';
  }
}

/// Factory para criar repositórios
abstract class RepositoryFactory {
  IWishlistRepository createWishlistRepository();
  IWishItemRepository createWishItemRepository(); 
  IUserProfileRepository createUserProfileRepository();
}

/// Service Locator pattern para repositórios
class RepositoryLocator {
  static final RepositoryLocator _instance = RepositoryLocator._internal();
  factory RepositoryLocator() => _instance;
  RepositoryLocator._internal();

  final Map<Type, Object> _repositories = {};
  
  void register<T>(T repository) {
    _repositories[T] = repository as Object;
  }
  
  T get<T>() {
    final repository = _repositories[T];
    if (repository == null) {
      throw StateError('Repository of type $T not registered');
    }
    return repository as T;
  }
  
  void clear() {
    _repositories.clear();
  }
  
  bool isRegistered<T>() {
    return _repositories.containsKey(T);
  }
}
