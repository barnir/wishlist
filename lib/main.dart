import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/theme.dart';
import 'utils/app_logger.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/repositories/user_profile_repository.dart';
import 'package:wishlist_app/services/theme_service.dart';
import 'package:wishlist_app/services/language_service.dart';
import 'package:wishlist_app/services/notification_service.dart';
import 'package:wishlist_app/services/image_prefetch_service.dart';
import 'package:wishlist_app/firebase_background_handler.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wishlists_screen.dart';
import 'screens/add_edit_item_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/wishlist_details_screen.dart';
import 'screens/add_edit_wishlist_screen.dart';
import 'screens/add_phone_screen.dart';
import 'screens/setup_name_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/friend_suggestions_screen.dart';
import 'screens/user_profile_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp();

  // Enable Firestore offline persistence (safe to call once; ignore if already enabled)
  try {
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  appLog('Firestore offline persistence enabled', tag: 'INIT');
  } catch (e) {
  appLog('Could not enable offline persistence: $e', tag: 'INIT');
  }

  // Set up background message handler for FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Firestore (for database)
  // Note: Firestore is automatically initialized with Firebase.initializeApp()
  appLog('Firebase Firestore initialized', tag: 'INIT');

  // Initialize theme service
  await ThemeService().initialize();

  // Initialize language service
  await LanguageService().initialize();

  // Initialize notification service
  await NotificationService().initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    // Handle sharing intent
    _intentDataStreamSubscription = FlutterSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedFile> value) {
          if (value.isNotEmpty) {
            _handleSharedMedia(value);
          }
        });

    FlutterSharingIntent.instance.getInitialSharing().then((
      List<SharedFile> value,
    ) {
      if (value.isNotEmpty) {
        if (AuthService.getCurrentUserId() != null) {
          _handleSharedMedia(value);
        }
      }
    });
  }

  void _handleSharedMedia(List<SharedFile> media) {
    if (media.isNotEmpty) {
      final sharedText = media.first.value;
      if (sharedText != null) {
        final urlRegex = RegExp(
          r'https?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+',
          caseSensitive: false,
        );
        final url = urlRegex.firstMatch(sharedText)?.group(0);

        navigatorKey.currentState?.pushNamed(
          '/add_edit_item',
          arguments: {
            'name': sharedText.replaceAll(url ?? '', '').trim(),
            'link': url,
          },
        );
      }
    }
  }


  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cache dos services para evitar recriação
    final languageService = LanguageService();
    final themeService = ThemeService();
    
    return AnimatedBuilder(
      animation: Listenable.merge([themeService, languageService]),
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Wishlist App',
          theme: lightAppTheme,
          darkTheme: darkAppTheme,
          // Use dynamic theme mode from ThemeService instead of fixed system
          themeMode: themeService.themeMode,
          
          // Configuração de localização - cache do locale
          locale: languageService.currentLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            // GlobalCupertinoLocalizations removido - Android-only app
          ],
          supportedLocales: const [
            Locale('en', ''), // Inglês
            Locale('pt', ''), // Português
          ],
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/wishlists': (_) => const WishlistsScreen(),
        '/add_new_wishlist': (_) => const AddEditWishlistScreen(),
        '/add_edit_wishlist': (context) {
          final wishlistId =
              ModalRoute.of(context)?.settings.arguments as String?;
          return AddEditWishlistScreen(wishlistId: wishlistId);
        },
        '/add_edit_item': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return AddEditItemScreen(
            wishlistId: args?['wishlistId'] as String?,
            itemId: args?['itemId'] as String?,
            name: args?['name'] as String?,
            link: args?['link'] as String?,
          );
        },
        '/wishlist_details': (context) {
          final wishlistId =
              ModalRoute.of(context)?.settings.arguments as String;
          return WishlistDetailsScreen(wishlistId: wishlistId);
        },
        '/add_phone': (_) => const AddPhoneScreen(),
        '/setup_name': (_) => const SetupNameScreen(),
        '/friend_suggestions': (_) => const FriendSuggestionsScreen(),
        '/user_profile': (context) {
          final userId = ModalRoute.of(context)?.settings.arguments as String;
          return UserProfileScreen(userId: userId);
        },
      },
          home: StreamBuilder<firebase_auth.User?>(
            stream: AuthService().authStateChanges,
            builder: (context, snapshot) {
              appLog('StreamBuilder auth state connectionState=${snapshot.connectionState} hasData=${snapshot.hasData}', tag: 'AUTH');
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                appLog('Auth state waiting - loading', tag: 'AUTH');
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (snapshot.hasData) {
                appLog('User authenticated: ${snapshot.data!.email}', tag: 'AUTH');
                // Simple direct approach - no complex FutureBuilder nesting
                return _AuthenticatedUserScreen(user: snapshot.data!);
              } else {
                appLog('No user authenticated - showing LoginScreen', tag: 'AUTH');
                return const LoginScreen();
              }
            },
          ),
        );
      },
    );
  }
}

// Simple authenticated user screen handler
class _AuthenticatedUserScreen extends StatefulWidget {
  final firebase_auth.User user;
  
  const _AuthenticatedUserScreen({required this.user});

  @override
  State<_AuthenticatedUserScreen> createState() => _AuthenticatedUserScreenState();
}

class _AuthenticatedUserScreenState extends State<_AuthenticatedUserScreen> {
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  static bool _prefetchDone = false; // garante execução única

  final _userProfileRepo = UserProfileRepository();

  Future<Map<String, dynamic>?> _getProfileWithRetry() async {
  appLog('_getProfileWithRetry attempt: ${_retryCount + 1}/$_maxRetries', tag: 'ROUTING');
    
    try {
      // First, try to get user profile from Firestore
      final userProfile = await _userProfileRepo.fetchById(widget.user.uid);
      if (userProfile != null) {
        final map = userProfile.toMap();
        appLog('Profile found on attempt ${_retryCount + 1}: ${map.keys.join(', ')}', tag: 'ROUTING');
        return map;
      }
      
      // If no profile found and we have retries left, wait and retry
      if (_retryCount < _maxRetries - 1) {
        _retryCount++;
  appLog('Profile not found, retry in ${_retryDelay.inMilliseconds}ms (attempt ${_retryCount + 1}/$_maxRetries)', tag: 'ROUTING');
        await Future.delayed(_retryDelay);
        return await _getProfileWithRetry();
      }
      
      // After all retries failed, check if this is an orphaned account
  appLog('Profile not found after $_maxRetries attempts - checking orphaned account', tag: 'ROUTING');
      final authService = AuthService();
      final isOrphaned = await authService.isOrphanedAccount();
      
      // If orphaned (and not in registration flow), clean it up
      if (isOrphaned) {
  appLog('Cleaning up orphaned Firebase Auth account...', tag: 'ROUTING');
        try {
          await authService.cleanupOrphanedAccount();
        } catch (e) {
          appLog('Failed cleanup orphaned account: $e', tag: 'ROUTING');
        }
      } else {
  appLog('Account not orphaned - registration in progress (return null)', tag: 'ROUTING');
        
        // If this is an email registration in progress (no profile yet), create a temporary profile now
        if (widget.user.email != null && 
            widget.user.metadata.creationTime != null && 
            DateTime.now().difference(widget.user.metadata.creationTime!).inMinutes < 10) {
          appLog('Creating temporary profile (email registration in progress)', tag: 'ROUTING');
          try {
            await _userProfileRepo.ensureTemporaryProfile(
              widget.user.uid,
              email: widget.user.email,
              displayName: widget.user.displayName ?? widget.user.email!.split('@')[0],
            );
            appLog('Temporary profile created', tag: 'ROUTING');
          } catch (e) {
            appLog('Error creating temporary profile: $e', tag: 'ROUTING');
          }
        }
      }
      
      return null;
    } catch (e) {
  appLog('Error getting profile attempt ${_retryCount + 1}: $e', tag: 'ROUTING');
      
      // If error occurred and we have retries left, wait and retry
      if (_retryCount < _maxRetries - 1) {
        _retryCount++;
  appLog('Retry after error in ${_retryDelay.inMilliseconds}ms (attempt ${_retryCount + 1}/$_maxRetries)', tag: 'ROUTING');
        await Future.delayed(_retryDelay);
        return await _getProfileWithRetry();
      }
      
      rethrow;
    }
  }
  
  @override
  Widget build(BuildContext context) {
  appLog('AuthenticatedUserScreen build user=${widget.user.email}', tag: 'ROUTING');
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getProfileWithRetry(),
      builder: (context, snapshot) {
  appLog('Profile FB connectionState=${snapshot.connectionState} hasError=${snapshot.hasError} hasData=${snapshot.hasData}', tag: 'ROUTING');
        
        // Check if the user has a profile but registration is not complete
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData &&
            snapshot.data!['registration_complete'] == false) {
          
          final profile = snapshot.data!;
          final hasValidPhone = profile['phone_number'] != null && 
                               profile['phone_number'].toString().isNotEmpty &&
                               profile['phone_verified'] == true;
          
          if (hasValidPhone) {
            // User already has verified phone - fix registration_complete flag
            appLog('Verified phone but registration incomplete -> auto-fix', tag: 'ROUTING');
            UserProfileRepository().update(widget.user.uid, {
              'registration_complete': true,
            }).then((_) {
              appLog('Registration completion flag fixed', tag: 'ROUTING');
            }).catchError((error) {
              appLog('Error fixing registration flag: $error', tag: 'ROUTING');
            });
            
            // Continue to main app instead of phone verification
            return FutureBuilder<Map<String, dynamic>?>(
              future: Future.value(profile..['registration_complete'] = true),
              builder: (context, fixedSnapshot) {
                if (fixedSnapshot.hasData) {
                  appLog('Routing fixed profile -> WishlistsScreen', tag: 'ROUTING');
                  return const WishlistsScreen();
                }
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              },
            );
          } else {
            appLog('Profile incomplete -> phone verification', tag: 'ROUTING');
            // Allow a small delay for the UI to render before navigation
            Future.microtask(() {
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/add_phone');
              }
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        }
        
        // If profile is completely missing but user exists, redirect to phone verification
        if (snapshot.connectionState == ConnectionState.done && !snapshot.hasData) {
          appLog('Routing: no profile found -> AddPhoneScreen', tag: 'ROUTING');
          Future.microtask(() {
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/add_phone');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          appLog('Profile loading...', tag: 'ROUTING');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          appLog('Profile error=${snapshot.error} -> AddPhoneScreen', tag: 'ROUTING');
          return const AddPhoneScreen();
        }
        
        final profile = snapshot.data;
  appLog('Profile data exists=${profile != null}', tag: 'ROUTING');
        
        // Enhanced routing logic with detailed debugging
  appLog('Routing analysis profileExists=${profile != null}', tag: 'ROUTING');
        if (profile != null) {
          appLog('Profile keys=${profile.keys.toList()}', tag: 'ROUTING');
        }

        if (profile == null) {
          appLog('Routing: no profile -> AddPhoneScreen', tag: 'ROUTING');
          return const AddPhoneScreen();
        }
        
        final phoneNumber = profile['phone_number'];
        if (phoneNumber == null || phoneNumber.toString().isEmpty) {
          appLog('Routing: missing phone number', tag: 'ROUTING');
          return const AddPhoneScreen();
        }
        
        final displayName = profile['display_name'];
        if (displayName == null || displayName.toString().isEmpty) {
          appLog('Routing: missing display name', tag: 'ROUTING');
          return const SetupNameScreen();
        }
        
  appLog('Routing: complete profile -> HomeScreen', tag: 'ROUTING');
        if (!_prefetchDone) {
          _prefetchDone = true;
          // Prefetch assíncrono não bloqueante
          Future.microtask(() async {
            try {
              appLog('Image prefetch start', tag: 'PREFETCH');
              await ImagePrefetchService().warmUp();
              appLog('Image prefetch done', tag: 'PREFETCH');
            } catch (e) {
              appLog('Image prefetch error: $e', tag: 'PREFETCH');
            }
          });
        }
        return const HomeScreen();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late final GlobalKey<ProfileScreenState> _profileScreenKey;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _profileScreenKey = GlobalKey<ProfileScreenState>();
    _screens = [
      const WishlistsScreen(),
      const ExploreScreen(),
      const FriendsScreen(),
      ProfileScreen(key: _profileScreenKey),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Se navegar para o perfil (índice 3), atualizar as estatísticas
    if (index == 3 && _profileScreenKey.currentState != null) {
      _profileScreenKey.currentState!.refreshStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _screens),
    bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.list_alt),
      label: AppLocalizations.of(context)?.wishlists ?? 'Wishlists',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.public),
      label: AppLocalizations.of(context)?.explore ?? 'Explore',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.star),
      label: AppLocalizations.of(context)?.favorites ?? 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
      label: AppLocalizations.of(context)?.profile ?? 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
