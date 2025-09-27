import 'package:mywishstash/widgets/skeleton_loader.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mywishstash/widgets/accessible_icon_button.dart';
import 'package:mywishstash/widgets/animated/animated_primitives.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import '../theme_extensions.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mywishstash/repositories/user_search_repository.dart';
import 'package:mywishstash/models/user_profile.dart';
import 'package:mywishstash/services/analytics/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';
import 'package:mywishstash/utils/app_logger.dart';
import 'package:mywishstash/repositories/favorites_repository.dart';
import 'package:mywishstash/widgets/app_snack.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_screen.dart';
import '../utils/page_transitions.dart';
import '../widgets/animated_search_field.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with TickerProviderStateMixin {
  final _userSearchRepo = UserSearchRepository();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  // Tab controller (search + contacts)
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

  // Contacts state (merged friends + invite)
  List<Map<String, dynamic>> _friendsInApp =
      []; // items with 'user' + 'contact'
  List<Contact> _contactsToInvite = [];
  bool _isLoadingContacts = false;
  bool _hasContactsPermission = false;
  final Set<String> _favoriteIds = {};
  StreamSubscription<Map<String, UserProfile>>?
  _contactStreamSub; // cancellable incremental streaming
  DateTime? _contactStreamStart;
  bool _reportedFirstFriend = false;
  bool _prefIncrementalContacts = true; // persisted user preference
  static const _kPrefIncrementalKey = 'pref_incremental_contacts_v1';
  static const _kContactsCacheKey = 'contacts_cache_payload_v1';
  static const _kContactsCacheHashKey = 'contacts_cache_hash_v1';
  static const _kContactsCacheTsKey = 'contacts_cache_ts_v1';
  static const _kContactsCacheTtlMs = 1000 * 60 * 30; // 30 minutes

  final FavoritesRepository _favoritesRepo = FavoritesRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _checkContactsPermission();
    // Load public profiles automatically when screen opens
    _loadPublicProfiles();
    _loadIncrementalPreference();
  }

  @override
  void dispose() {
    _contactStreamSub?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    // If user leaves the Contacts tab (index 1), cancel ongoing streaming to free resources
    if (_tabController.index != 1) {
      if (_contactStreamSub != null) {
        logI(
          'Cancelling contact streaming (tab switched)',
          tag: 'CONTACT_DEBUG',
        );
        _contactStreamSub?.cancel();
        _contactStreamSub = null;
      }
    } else {
      // If user switches back and contacts not loaded yet, attempt reload
      if (_friendsInApp.isEmpty &&
          _contactsToInvite.isEmpty &&
          !_isLoadingContacts &&
          _hasContactsPermission) {
        _loadContactsData();
      }
    }
  }

  Future<void> _loadIncrementalPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getBool(_kPrefIncrementalKey);
      if (v != null && v != _prefIncrementalContacts && mounted) {
        setState(() => _prefIncrementalContacts = v);
      }
    } catch (_) {}
  }

  Future<void> _toggleIncrementalPreference() async {
    final newValue = !_prefIncrementalContacts;
    setState(() => _prefIncrementalContacts = newValue);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefIncrementalKey, newValue);
    } catch (_) {}
    // Optionally refresh contacts if on contacts tab
    if (_tabController.index == 1) {
      _friendsInApp.clear();
      _contactsToInvite.clear();
      _contactStreamSub?.cancel();
      _contactStreamSub = null;
      _loadContactsData();
    }
  }

  // ============== CONTACTS CACHE HELPERS ==============
  Future<String> _computeContactsHash(List<Contact> contacts) async {
    final tokens = <String>[];
    for (final c in contacts) {
      for (final p in c.phones) {
        final norm = _normalizePhoneNumber(p.number);
        if (norm != null) tokens.add('p:$norm');
      }
      for (final e in c.emails) {
        final em = e.address.toLowerCase().trim();
        if (em.isNotEmpty) tokens.add('e:$em');
      }
    }
    tokens.sort();
    return tokens
        .join('|')
        .hashCode
        .toRadixString(16); // quick hash; sufficient for change detection
  }

  Future<bool> _tryHydrateContactsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt(_kContactsCacheTsKey);
      if (ts == null) return false;
      final isExpired =
          DateTime.now().millisecondsSinceEpoch - ts > _kContactsCacheTtlMs;
      if (isExpired) return false;
      final payload = prefs.getStringList(_kContactsCacheKey);
      if (payload == null) return false;
      final friends = <Map<String, dynamic>>[];
      final invites =
          <
            Contact
          >[]; // cannot reconstruct raw contacts easily; omit invites from cache for now
      for (final entry in payload) {
        // entry format: userId|displayName|email|phone|contactName|contactPhone
        final parts = entry.split('\u0001');
        if (parts.length < 6) continue;
        friends.add({
          'contact': {
            'name': parts[4],
            'phone': parts[5].isEmpty ? null : parts[5],
          },
          'user': {
            'id': parts[0],
            'display_name': parts[1].isEmpty ? null : parts[1],
            'email': parts[2].isEmpty ? null : parts[2],
            'phone_number': parts[3].isEmpty ? null : parts[3],
            'photo_url': null,
          },
          'contact_name': parts[4],
          'contact_phone': parts[5].isEmpty ? null : parts[5],
        });
      }
      if (friends.isEmpty) return false;
      if (mounted) {
        setState(() {
          _friendsInApp = friends;
          _contactsToInvite =
              invites; // invites will be re-derived on fresh load
          _isLoadingContacts = false;
        });
      }
      logI(
        'Hydrated ${friends.length} contacts from cache',
        tag: 'CONTACT_CACHE',
      );
      return true;
    } catch (e) {
      logW('Failed to hydrate contacts cache: $e', tag: 'CONTACT_CACHE');
      return false;
    }
  }

  Future<void> _persistContactsCache({
    required List<Map<String, dynamic>> friends,
    required String hash,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = friends.map((f) {
        final u = f['user'] as Map<String, dynamic>;
        final c = f['contact'] as Map<String, dynamic>;
        final userId = (u['id'] ?? '').toString();
        final displayName = (u['display_name'] ?? '').toString();
        final email = (u['email'] ?? '').toString();
        final phone = (u['phone_number'] ?? '').toString();
        final contactName = (c['name'] ?? '').toString();
        final contactPhone = (c['phone'] ?? '').toString();
        return [
          userId,
          displayName,
          email,
          phone,
          contactName,
          contactPhone,
        ].join('\u0001');
      }).toList();
      await prefs.setStringList(_kContactsCacheKey, payload);
      await prefs.setString(_kContactsCacheHashKey, hash);
      await prefs.setInt(
        _kContactsCacheTsKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      logI(
        'Persisted contacts cache entries=${payload.length}',
        tag: 'CONTACT_CACHE',
      );
    } catch (e) {
      logW('Failed to persist contacts cache: $e', tag: 'CONTACT_CACHE');
    }
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
    final pos = _scrollController.position;
    if (pos.userScrollDirection == ScrollDirection.idle) return;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  /// Load public profiles automatically when screen opens (no search query needed)
  Future<void> _loadPublicProfiles() async {
    logI('=== AUTO-LOADING PUBLIC PROFILES ===', tag: 'EXPLORE_DEBUG');
    setState(() {
      _isInitialLoading = true;
      _users.clear();
      _lastDoc = null;
      _hasMoreData = true;
    });

    await _loadPublicProfilesData();

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
    logI(
      'Auto-loading completed. Users loaded: ${_users.length}',
      tag: 'EXPLORE_DEBUG',
    );
  }

  Future<void> _loadInitialData() async {
    if (_searchQuery.isEmpty) {
      // If no search query, load public profiles instead
      await _loadPublicProfiles();
      return;
    }

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

  /// Load public profiles data (used when no search query)
  Future<void> _loadPublicProfilesData() async {
    if (_isLoading || !_hasMoreData) return;

    logI('Loading public profiles data...', tag: 'EXPLORE_DEBUG');
    setState(() {
      _isLoading = true;
    });

    try {
      final page = await _userSearchRepo.getPublicUsersPage(
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      logI(
        'Loaded ${page.items.length} public users, hasMore: ${page.hasMore}',
        tag: 'EXPLORE_DEBUG',
      );
      setState(() {
        _users.addAll(page.items);
        _lastDoc = page.lastDoc;
        _hasMoreData = page.hasMore;
        _isLoading = false;
      });
      if (!_hasMoreData) {
        _scrollController.removeListener(_onScroll);
      }
    } catch (e) {
      logE('Error loading public profiles', tag: 'EXPLORE_DEBUG', error: e);
      // Provide more precise feedback for common Firestore failure causes
      final errorText = _mapSearchError(e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText)));
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    // If no search query, load public profiles
    if (_searchQuery.isEmpty) {
      await _loadPublicProfilesData();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final page = await _userSearchRepo.searchPage(
        query: _searchQuery,
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      setState(() {
        _users.addAll(page.items);
        _lastDoc = page.lastDoc;
        _hasMoreData = page.hasMore;
        _isLoading = false;
      });
      if (!_hasMoreData) {
        _scrollController.removeListener(_onScroll);
      }
    } catch (e) {
      // Provide more precise feedback for common Firestore failure causes
      final errorText = _mapSearchError(e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorText)));
      }
    }
  }

  Future<void> _onRefresh() async {
    if (_searchQuery.isEmpty) {
      await _loadPublicProfiles();
    } else {
      await _loadInitialData();
    }
  }

  // ============== CONTACTS METHODS ==============

  Future<void> _checkContactsPermission() async {
    try {
      // Primeiro só verificamos se já temos permissão, sem solicitar
      final hasPermission = await FlutterContacts.requestPermission(
        readonly: true,
      );
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
          final grantedMsg =
              AppLocalizations.of(context)?.contactsPermissionDescription ??
              'Permissão concedida! A descobrir contactos...';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(grantedMsg),
              backgroundColor: Theme.of(
                context,
              ).extension<AppSemanticColors>()!.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          // Permissão negada - mostrar explicação
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.contactsPermissionRequired,
              ),
              action: SnackBarAction(
                label:
                    AppLocalizations.of(context)?.contactsPermissionTryAgain ??
                    'Tentar novamente',
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
            content: Text(
              AppLocalizations.of(
                context,
              )!.errorRequestingPermission(e.toString()),
            ),
            action: SnackBarAction(
              label:
                  AppLocalizations.of(context)?.contactsPermissionSettings ??
                  'Configurações',
              onPressed: () {
                // TODO: Abrir configurações da app se necessário
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)?.contactsPermissionManual ??
                          'Vai às Configurações > Apps > WishlistApp > Permissões para ativar manualmente',
                    ),
                    duration: const Duration(seconds: 4),
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

      // Attempt hydration from cache (fast path) if not already have data
      if (_friendsInApp.isEmpty && _contactsToInvite.isEmpty) {
        final hydrated = await _tryHydrateContactsFromCache();
        if (hydrated) {
          // Continue with async refresh in background without blocking UI
          // but do not early return; we want fresh data if hash changed.
          logI(
            'Showing cached contacts while refreshing in background',
            tag: 'CONTACT_CACHE',
          );
        }
      }

      // Verifica permissão novamente antes de prosseguir
      final stillHasPermission = await FlutterContacts.requestPermission(
        readonly: true,
      );
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

      // Filtra contactos que têm números de telefone ou emails
      final contactsWithPhones = contacts
          .where((c) => c.phones.isNotEmpty || c.emails.isNotEmpty)
          .toList();

      // Recolhe todos os números de telefone e emails dos contactos
      final phoneNumbers = <String>[];
      final emails = <String>[];

      for (final contact in contactsWithPhones) {
        for (final phone in contact.phones) {
          if (phone.number.isNotEmpty) {
            final normalized = _normalizePhoneNumber(phone.number);
            logI(
              'Contact ${contact.displayName}: raw phone ${phone.number} -> normalized: $normalized',
              tag: 'CONTACT_DEBUG',
            );
            // Add normalized phone number instead of raw number
            if (normalized != null && normalized.isNotEmpty) {
              phoneNumbers.add(normalized);
            }
          }
        }
        for (final email in contact.emails) {
          if (email.address.isNotEmpty) {
            emails.add(email.address.toLowerCase().trim());
          }
        }
      }

      // Debug: mostra todos os números/emails que vamos procurar
      logI('=== CONTACT SEARCH DEBUG START ===', tag: 'CONTACT_DEBUG');
      logI(
        'Total contacts: ${contactsWithPhones.length}',
        tag: 'CONTACT_DEBUG',
      );
      logI('Phone numbers to search: $phoneNumbers', tag: 'CONTACT_DEBUG');
      logI('Emails to search: $emails', tag: 'CONTACT_DEBUG');

      // Feature flag for incremental streaming; can toggle later or via settings / remote config.
      // Intentionally resolved via helper to avoid analyzer treating alternate branch as dead code.
      final useIncrementalContactStreaming = _incrementalContactsEnabled();
      Map<String, UserProfile> registeredUsers = {};

      // Pre-compute hash of local contacts to compare to cache
      final contactsHash = await _computeContactsHash(contactsWithPhones);
      String? previousHash;
      try {
        final prefs = await SharedPreferences.getInstance();
        previousHash = prefs.getString(_kContactsCacheHashKey);
      } catch (_) {}

      final cacheValid = previousHash == contactsHash;
      if (cacheValid) {
        logI(
          'Contacts hash unchanged; will still stream/fetch for freshness but may skip persisting.',
          tag: 'CONTACT_CACHE',
        );
      } else {
        logI(
          'Contacts hash changed (prev=$previousHash new=$contactsHash) -> will refresh and persist',
          tag: 'CONTACT_CACHE',
        );
      }

      if (useIncrementalContactStreaming) {
        logI(
          'Starting incremental contact streaming (cancellable)...',
          tag: 'CONTACT_DEBUG',
        );
        try {
          // Build quick lookup maps for contacts to avoid re-normalizing on every delta.
          final contactPhoneIndex = <String, List<Contact>>{};
          final contactEmailIndex = <String, List<Contact>>{};
          for (final c in contactsWithPhones) {
            for (final p in c.phones) {
              final norm = _normalizePhoneNumber(p.number);
              if (norm != null) {
                contactPhoneIndex.putIfAbsent(norm, () => []).add(c);
              }
            }
            for (final e in c.emails) {
              final em = e.address.toLowerCase().trim();
              if (em.isNotEmpty) {
                contactEmailIndex.putIfAbsent(em, () => []).add(c);
              }
            }
          }

          // Mutable working sets while streaming
          final friends = <Map<String, dynamic>>[];
          final inviteContacts = contactsWithPhones.toList();
          _contactStreamSub?.cancel();
          _reportedFirstFriend = false;
          _contactStreamStart = DateTime.now();
          _contactStreamSub = _userSearchRepo
              .streamUsersByContacts(phoneNumbers: phoneNumbers, emails: emails)
              .listen(
                (delta) {
                  if (!mounted) return;
                  registeredUsers.addAll(delta);
                  for (final entry in delta.entries) {
                    final key = entry.key;
                    final profile = entry.value;
                    final relatedContacts = <Contact>[];
                    if (contactPhoneIndex.containsKey(key)) {
                      relatedContacts.addAll(contactPhoneIndex[key]!);
                    }
                    if (contactEmailIndex.containsKey(key)) {
                      relatedContacts.addAll(contactEmailIndex[key]!);
                    }
                    for (final c in relatedContacts) {
                      if (inviteContacts.remove(c)) {
                        friends.add({
                          'contact': {
                            'name': c.displayName,
                            'phone': c.phones.isNotEmpty
                                ? c.phones.first.number
                                : null,
                          },
                          'user': {
                            'id': profile.id,
                            'display_name': profile.displayName,
                            'email': profile.email,
                            'phone_number': profile.phoneNumber,
                            'photo_url': profile.photoUrl,
                          },
                          'contact_name': c.displayName,
                          'contact_phone': c.phones.isNotEmpty
                              ? c.phones.first.number
                              : null,
                        });
                        if (!_reportedFirstFriend) {
                          _reportedFirstFriend = true;
                          final ttf = DateTime.now().difference(
                            _contactStreamStart!,
                          );
                          logI(
                            'TTF (time-to-first-friend) = ${ttf.inMilliseconds}ms',
                            tag: 'CONTACT_DEBUG',
                          );
                        }
                        logI(
                          'Incremental friend match: ${c.displayName}',
                          tag: 'CONTACT_DEBUG',
                        );
                      }
                    }
                  }
                  setState(() {
                    _friendsInApp = friends.toList();
                    _contactsToInvite = inviteContacts.toList();
                  });
                },
                onError: (e) async {
                  logE(
                    'Streaming error: $e (fallback to full lookup)',
                    tag: 'CONTACT_DEBUG',
                  );
                  await _contactStreamSub?.cancel();
                  _contactStreamSub = null;
                  try {
                    registeredUsers = await _userSearchRepo.findUsersByContacts(
                      phoneNumbers: phoneNumbers,
                      emails: emails,
                    );
                  } catch (e2) {
                    logE(
                      'Fallback after streaming error also failed: $e2',
                      tag: 'CONTACT_DEBUG',
                    );
                  }
                },
                onDone: () {
                  if (_contactStreamStart != null) {
                    final total = DateTime.now().difference(
                      _contactStreamStart!,
                    );
                    logI(
                      'Streaming complete totalDuration=${total.inMilliseconds}ms totalFriends=${friends.length}',
                      tag: 'CONTACT_DEBUG',
                    );
                    // Fire analytics event (best-effort; swallow errors)
                    () async {
                      try {
                        await AnalyticsService().log(
                          'contact_stream_metrics',
                          properties: {
                            'mode': 'incremental',
                            'total_ms': total.inMilliseconds,
                            'friends_count': friends.length,
                            'contacts_count': contactsWithPhones.length,
                            'had_first_friend': _reportedFirstFriend,
                          },
                        );
                      } catch (_) {}
                      if (mounted && friends.isNotEmpty && !cacheValid) {
                        await _persistContactsCache(
                          friends: friends,
                          hash: contactsHash,
                        );
                      }
                      // Prefetch first few avatar images (if photo_url available)
                      if (mounted && friends.isNotEmpty) {
                        try {
                          final toPrefetch = friends.take(3).toList();
                          for (final f in toPrefetch) {
                            final user = f['user'] as Map<String, dynamic>;
                            final url = user['photo_url'] as String?;
                            if (url != null &&
                                url.isNotEmpty &&
                                context.mounted) {
                              // Use NetworkImage; in production consider a dedicated cached image widget
                              await precacheImage(NetworkImage(url), context);
                            }
                          }
                          logI(
                            'Prefetched avatar images count=${toPrefetch.length}',
                            tag: 'CONTACT_PREFETCH',
                          );
                        } catch (e) {
                          logW(
                            'Avatar prefetch failed: $e',
                            tag: 'CONTACT_PREFETCH',
                          );
                        }
                      }
                    }();
                  }
                  // Mark loading complete if still mounted
                  if (mounted) {
                    setState(() {
                      _isLoadingContacts = false;
                    });
                  }
                },
                cancelOnError: false,
              );
          // Early return: completion handled in onDone
          return;
        } catch (e) {
          logE(
            'Incremental streaming failed, fallback to full lookup: $e',
            tag: 'CONTACT_DEBUG',
          );
          // Fallback to original full fetch path below.
          registeredUsers = await _userSearchRepo.findUsersByContacts(
            phoneNumbers: phoneNumbers,
            emails: emails,
          );
          // Emit analytics for fallback scenario
          try {
            await AnalyticsService().log(
              'contact_stream_metrics',
              properties: {
                'mode': 'incremental_fallback',
                'friends_count': registeredUsers.length,
                'contacts_count': contactsWithPhones.length,
              },
            );
          } catch (_) {}
        }
      } else {
        try {
          registeredUsers = await _userSearchRepo.findUsersByContacts(
            phoneNumbers: phoneNumbers,
            emails: emails,
          );
        } catch (e) {
          logE(
            'Error searching for registered users: $e',
            tag: 'CONTACT_DEBUG',
          );
        }
        // Analytics for batch mode
        try {
          await AnalyticsService().log(
            'contact_stream_metrics',
            properties: {
              'mode': 'batch',
              'friends_count': registeredUsers.length,
              'contacts_count': contactsWithPhones.length,
            },
          );
        } catch (_) {}
      }

      // Special debug for Aamor contact
      final aamorContacts = contactsWithPhones
          .where((c) => c.displayName.toLowerCase().contains('aamor'))
          .toList();
      if (aamorContacts.isNotEmpty) {
        final aamorContact = aamorContacts.first;
        logI('=== AAMOR DEBUG ===', tag: 'CONTACT_DEBUG');
        logI(
          'Aamor contact phones: ${aamorContact.phones.map((p) => p.number).toList()}',
          tag: 'CONTACT_DEBUG',
        );
        logI(
          'Aamor contact emails: ${aamorContact.emails.map((e) => e.address).toList()}',
          tag: 'CONTACT_DEBUG',
        );
        for (final phone in aamorContact.phones) {
          final normalized = _normalizePhoneNumber(phone.number);
          logI(
            'Aamor phone ${phone.number} -> normalized: $normalized',
            tag: 'CONTACT_DEBUG',
          );
          logI(
            'Is in registered users? ${registeredUsers.containsKey(normalized)}',
            tag: 'CONTACT_DEBUG',
          );
        }
        logI('=== END AAMOR DEBUG ===', tag: 'CONTACT_DEBUG');
      }

      // Separa contactos entre amigos registados e contactos para convidar (skip if already built by streaming)
      final alreadyBuilt = useIncrementalContactStreaming;
      final friends = alreadyBuilt ? _friendsInApp : <Map<String, dynamic>>[];
      final inviteContacts = alreadyBuilt ? _contactsToInvite : <Contact>[];

      if (!alreadyBuilt) {
        for (final contact in contactsWithPhones) {
          bool isRegistered = false;
          UserProfile? matchedUser;

          // Verifica se algum telefone do contacto corresponde a um utilizador registado
          for (final phone in contact.phones) {
            final normalizedPhone = _normalizePhoneNumber(phone.number);
            logI(
              'Checking contact phone: ${phone.number} -> normalized: $normalizedPhone',
              tag: 'CONTACT_DEBUG',
            );
            if (normalizedPhone != null &&
                registeredUsers.containsKey(normalizedPhone)) {
              isRegistered = true;
              matchedUser = registeredUsers[normalizedPhone];
              logI(
                'MATCH FOUND! Contact ${contact.displayName} matches user ${matchedUser!.displayName} with phone: $normalizedPhone',
                tag: 'CONTACT_DEBUG',
              );
              break;
            }
          }

          // Se não encontrou por telefone, tenta por email
          if (!isRegistered) {
            for (final email in contact.emails) {
              final cleanEmail = email.address.toLowerCase().trim();
              if (registeredUsers.containsKey(cleanEmail)) {
                isRegistered = true;
                matchedUser = registeredUsers[cleanEmail];
                break;
              }
            }
          }

          if (isRegistered && matchedUser != null) {
            // Contacto está registado na app - adiciona aos amigos
            friends.add({
              'contact': {
                'name': contact.displayName,
                'phone': contact.phones.isNotEmpty
                    ? contact.phones.first.number
                    : null,
              },
              'user': {
                'id': matchedUser.id,
                'display_name': matchedUser.displayName,
                'email': matchedUser.email,
                'phone_number': matchedUser.phoneNumber,
                'photo_url': matchedUser.photoUrl,
              },
              'contact_name': contact.displayName,
              'contact_phone': contact.phones.isNotEmpty
                  ? contact.phones.first.number
                  : null,
            });
          } else {
            // Contacto não está registado - adiciona aos convites
            inviteContacts.add(contact);
          }
        }
      }

      logI('=== FINAL RESULTS ===', tag: 'CONTACT_DEBUG');
      logI('Friends in app: ${friends.length}', tag: 'CONTACT_DEBUG');
      logI(
        'Contacts to invite: ${inviteContacts.length}',
        tag: 'CONTACT_DEBUG',
      );
      logI('=== CONTACT SEARCH DEBUG END ===', tag: 'CONTACT_DEBUG');

      if (mounted) {
        setState(() {
          _friendsInApp = friends;
          _contactsToInvite = inviteContacts;
          _isLoadingContacts = false;
        });
      }
      if (friends.isNotEmpty &&
          !useIncrementalContactStreaming &&
          !cacheValid) {
        await _persistContactsCache(friends: friends, hash: contactsHash);
      }
      // Avatar prefetch for batch mode
      if (friends.isNotEmpty && !useIncrementalContactStreaming && mounted) {
        try {
          final toPrefetch = friends.take(3).toList();
          for (final f in toPrefetch) {
            final user = f['user'] as Map<String, dynamic>;
            final url = user['photo_url'] as String?;
            if (url != null && url.isNotEmpty && context.mounted) {
              await precacheImage(NetworkImage(url), context);
            }
          }
          logI(
            'Prefetched avatar images (batch mode) count=${toPrefetch.length}',
            tag: 'CONTACT_PREFETCH',
          );
        } catch (e) {
          logW(
            'Avatar prefetch failed (batch mode): $e',
            tag: 'CONTACT_PREFETCH',
          );
        }
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
          errorMessage =
              AppLocalizations.of(context)?.contactsPermissionRevoked ??
              'Permissão de contactos foi revogada. Tenta novamente.';
          setState(() {
            _hasContactsPermission = false;
          });
        } else {
          errorMessage = AppLocalizations.of(
            context,
          )!.errorLoadingContacts(e.toString());
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

      final message =
          'Olá $name! Estou a usar o WishlistApp para gerir as minhas listas de desejos. Experimenta também! 🎁';
      final fullMessage = '$message\n\n${l10n.invitePlayStoreMessage}';

      // ignore: deprecated_member_use
      // ignore: deprecated_member_use
      await Share.share(fullMessage, subject: l10n.inviteSubject);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorSendingInvite(e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Existing build logic continues below; we insert a modified AppBar with toggle action.
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.explore ?? 'Explore'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'toggle_incremental') {
                _toggleIncrementalPreference();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'toggle_incremental',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _prefIncrementalContacts
                            ? (AppLocalizations.of(
                                    context,
                                  )?.disableIncrementalContacts ??
                                  'Disable incremental contacts')
                            : (AppLocalizations.of(
                                    context,
                                  )?.enableIncrementalContacts ??
                                  'Enable incremental contacts'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(
                      value: _prefIncrementalContacts,
                      onChanged: (_) => _toggleIncrementalPreference(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: AppLocalizations.of(context)?.search ?? 'Search'),
            Tab(text: AppLocalizations.of(context)?.contacts ?? 'Contacts'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [_buildSearchTab(), _buildContactsSection()],
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: UIConstants.paddingM,
          child: AnimatedSearchField(
            label: AppLocalizations.of(context)!.searchUsersPlaceholder,
            controller: _searchController,
            prefixIcon: const Icon(Icons.search),
            isLoading: _isLoading && _searchQuery.isNotEmpty,
            onChanged: (value) {
              // Optional: Add haptic feedback for better UX
              if (value.isNotEmpty && _searchQuery.isEmpty) {
                // First character typed - subtle haptic feedback
              }
            },
          ),
        ),
        Expanded(child: _buildSearchContent()),
      ],
    );
  }

  Widget _buildSearchContent() {
    // Wrap state transitions in AnimatedSwitcher to avoid hard visual jumps / grey flashes
    final Widget stateChild;

    if (_isInitialLoading) {
      stateChild = const SkeletonLoader(key: ValueKey('loading'), itemCount: 8);
    } else if (_searchQuery.isEmpty && _users.isEmpty && !_isLoading) {
      // Empty initial state (no query)
      final l10n = AppLocalizations.of(context)!;
      stateChild = WishlistEmptyState(
        key: const ValueKey('empty_initial'),
        icon: Icons.search,
        title: l10n.searchUsersTitle,
        subtitle: l10n.searchUsersSubtitle,
      );
    } else if (_searchQuery.isNotEmpty && _users.isEmpty && !_isLoading) {
      // No results for current query
      final l10n = AppLocalizations.of(context)!;
      stateChild = WishlistEmptyState(
        key: const ValueKey('empty_query'),
        icon: Icons.person_search,
        title: l10n.noResults,
        subtitle: l10n.noResultsSubtitle,
      );
    } else {
      // Results list
      stateChild = RefreshIndicator(
        key: const ValueKey('results'),
        onRefresh: _onRefresh,
        child: ListView.builder(
          controller: _scrollController,
          // Keep some physics even if few results to allow pull-to-refresh
          physics: const AlwaysScrollableScrollPhysics(),
          padding: UIConstants.listPadding,
          itemCount: _users.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _users.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.loadingMoreResults,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }
            return _buildUserCard(_users[index]);
          },
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: stateChild,
    );
  }

  Widget _buildUserCard(UserProfile user) {
    final displayName = user.displayName ?? 'Utilizador';
    final userId = user.id;
    final isPrivate = user.isPrivate;
    final String? bio = user.bio;
    // Fade & slight scale-in on first build to reduce popping
    return TweenAnimationBuilder<double>(
      key: ValueKey('user-${user.id}'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.98 + (value * 0.02),
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: Card(
        margin: UIConstants.cardMargin,
        elevation: UIConstants.elevationM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
        ),
        child: InkWell(
          onTap: () {
            context.pushFadeScale(UserProfileScreen(userId: userId));
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
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'U',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (bio != null && bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          bio,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                            isPrivate
                                ? Icons.lock_outlined
                                : Icons.public_outlined,
                            size: 14,
                            color: isPrivate
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPrivate
                                ? (AppLocalizations.of(
                                        context,
                                      )?.privateProfileBadge ??
                                      'Perfil privado')
                                : (AppLocalizations.of(
                                        context,
                                      )?.publicProfileBadge ??
                                      'Perfil público'),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
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
      ),
    );
  }

  Widget _buildContactsSection() {
    Widget stateChild;
    if (!_hasContactsPermission) {
      stateChild = _buildPermissionRequest();
    } else if (_isLoadingContacts) {
      final l10n = AppLocalizations.of(context)!;
      stateChild = Center(
        key: const ValueKey('contacts-loading'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text(l10n.discoveringFriends),
          ],
        ),
      );
    } else {
      final total = _friendsInApp.length + _contactsToInvite.length;
      if (total == 0) {
        final l10n = AppLocalizations.of(context)!;
        stateChild = Center(
          key: const ValueKey('contacts-empty'),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.contacts, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(l10n.noFriendsFound),
              const SizedBox(height: 8),
              Text(
                '${l10n.noFriendsFoundDescription}\n(Quando os teus contactos entrarem vais vê-los aqui)',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      } else {
        stateChild = RefreshIndicator(
          key: const ValueKey('contacts-list'),
          onRefresh: _loadContactsData,
          child: ListView.builder(
            padding: UIConstants.listPadding,
            itemCount: total,
            itemBuilder: (context, index) {
              if (index < _friendsInApp.length) {
                return _buildFriendCard(_friendsInApp[index]);
              }
              final contact = _contactsToInvite[index - _friendsInApp.length];
              return _buildInviteCard(contact);
            },
          ),
        );
      }
    }

    return ScaleFadeSwitcher(child: stateChild);
  }

  Widget _buildPermissionRequest() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: UIConstants.paddingL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.contacts, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              l10n.discoverFriends,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.contactsPermissionDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestContactsPermission,
              icon: const Icon(Icons.contacts),
              label: Text(l10n.allowContactsAccess),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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

    final displayName =
        user['display_name'] as String? ??
        contact['name'] as String? ??
        'Utilizador';
    final email = user['email'] as String?;
    final userId = user['id'] as String;
    final contactName = contact['name'] as String? ?? displayName;

    final isFav = _favoriteIds.contains(userId);
    return FadeIn(
      child: Card(
        margin: UIConstants.cardMargin,
        elevation: UIConstants.elevationM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
        ),
        child: InkWell(
          onTap: () {
            context.pushFadeScale(UserProfileScreen(userId: userId));
          },
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
          child: Container(
            padding: UIConstants.paddingM,
            child: Row(
              children: [
                // Avatar do utilizador
                Hero(
                  tag: 'profile-avatar-$userId',
                  flightShuttleBuilder:
                      (context, animation, direction, fromCtx, toCtx) {
                        return ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: toCtx.widget,
                        );
                      },
                  child: Container(
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
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'U',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (contactName != displayName) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${AppLocalizations.of(context)!.contactLabel}: $contactName',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (email != null && email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions (favorite toggle)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AccessibleIconButton(
                      icon: isFav ? Icons.star : Icons.star_border,
                      color: isFav
                          ? Colors.amber
                          : Theme.of(context).colorScheme.primary,
                      semanticLabel: isFav
                          ? AppLocalizations.of(context)?.removeFromFavorites ??
                                'Remover dos favoritos'
                          : AppLocalizations.of(context)?.addToFavorites ??
                                'Adicionar aos favoritos',
                      tooltip: isFav
                          ? AppLocalizations.of(context)?.removeFromFavorites ??
                                'Remover dos favoritos'
                          : AppLocalizations.of(context)?.addToFavorites ??
                                'Adicionar aos favoritos',
                      onPressed: () => _toggleFavorite(userId, isFav),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCard(Contact contact) {
    final displayName = contact.displayName;
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';

    return FadeIn(
      child: Card(
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
              Hero(
                tag: 'profile-avatar-contact-${contact.id.hashCode}',
                flightShuttleBuilder:
                    (context, animation, direction, fromCtx, toCtx) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: toCtx.widget,
                      );
                    },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(UIConstants.radiusM),
                    color: Colors.grey[300],
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : 'C',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading indicator removido (substituído por padding simples no builder)

  String _mapSearchError(Object e) {
    final raw = e.toString();
    // Common Firestore messages
    if (raw.contains('PERMISSION_DENIED') ||
        raw.contains('Missing or insufficient permissions')) {
      return 'Sem permissões para ler utilizadores públicos (verifica regras do Firestore).';
    }
    if (raw.contains('FAILED_PRECONDITION') && raw.contains('index')) {
      return 'Índice Firestore em falta para pesquisa. Cria o índice sugerido no console.';
    }
    if (raw.contains('unavailable') || raw.contains('UNAVAILABLE')) {
      return 'Serviço temporariamente indisponível. Tenta novamente.';
    }
    if (raw.contains('network') || raw.contains('Network')) {
      return 'Problema de rede ao pesquisar. Garante ligação à internet.';
    }
    return 'Erro na pesquisa: $raw';
  }

  Future<void> _toggleFavorite(String userId, bool currentlyFav) async {
    try {
      if (currentlyFav) {
        await _favoritesRepo.remove(
          FirebaseAuth.instance.currentUser!.uid,
          userId,
        );
        setState(() {
          _favoriteIds.remove(userId);
        });
        if (mounted) {
          AppSnack.show(
            context,
            AppLocalizations.of(context)?.removedFromFavorites ??
                'Removido dos favoritos',
            type: SnackType.success,
          );
        }
      } else {
        await _favoritesRepo.add(
          FirebaseAuth.instance.currentUser!.uid,
          userId,
        );
        setState(() {
          _favoriteIds.add(userId);
        });
        if (mounted) {
          AppSnack.show(
            context,
            AppLocalizations.of(context)?.addedToFavorites ??
                'Adicionado aos favoritos!',
            type: SnackType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao actualizar favorito: $e')),
        );
      }
    }
  }

  /// Normalize phone number for database matching
  /// Uses same logic as ContactsService and UserSearchRepository to ensure consistency
  String? _normalizePhoneNumber(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) return null;

    // Remove all non-numeric characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // If starts with 00, replace with +
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }

    // Portuguese phone normalization
    if (!cleaned.startsWith('+')) {
      // Portuguese mobile: 9 digits starting with 9
      if (cleaned.length == 9 && cleaned.startsWith('9')) {
        cleaned = '+351$cleaned';
      }
      // Portuguese with national code: 351XXXXXXXXX
      else if (cleaned.length == 12 && cleaned.startsWith('351')) {
        cleaned = '+$cleaned';
      }
      // Portuguese landline/mobile: starting with 2, 3 or 9
      else if (cleaned.length == 9 && RegExp(r'^[239]').hasMatch(cleaned)) {
        cleaned = '+351$cleaned';
      }
      // Old Portuguese landline: 8 digits starting with 2-3
      else if (cleaned.length == 8 && RegExp(r'^[2-3]').hasMatch(cleaned)) {
        cleaned = '+351$cleaned';
      }
    }

    return cleaned.isEmpty ? null : cleaned;
  }

  bool _incrementalContactsEnabled() {
    return _prefIncrementalContacts;
  }
}
