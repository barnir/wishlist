import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wishlist_app/theme.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/firebase_database_service.dart';
import 'package:wishlist_app/services/theme_service.dart';
import 'package:wishlist_app/services/language_service.dart';
import 'package:wishlist_app/services/notification_service.dart';
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
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp();

  // Set up background message handler for FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Firestore (for database)
  // Note: Firestore is automatically initialized with Firebase.initializeApp()
  debugPrint('🔥 Firebase Firestore initialized');

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
          themeMode: ThemeMode.system,
          
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
              debugPrint('=== StreamBuilder called, connectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}');
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                debugPrint('Auth state waiting - showing loading');
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              if (snapshot.hasData) {
                debugPrint('User authenticated: ${snapshot.data!.email}');
                // Simple direct approach - no complex FutureBuilder nesting
                return _AuthenticatedUserScreen(user: snapshot.data!);
              } else {
                debugPrint('No user authenticated - showing LoginScreen');
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

  Future<Map<String, dynamic>?> _getProfileWithRetry() async {
    debugPrint('_getProfileWithRetry attempt: ${_retryCount + 1}/$_maxRetries');
    
    try {
      final profile = await FirebaseDatabaseService().getUserProfile(widget.user.uid);
      
      if (profile != null) {
        debugPrint('Profile found on attempt ${_retryCount + 1}: ${profile.keys.join(', ')}');
        return profile;
      }
      
      // If no profile found and we have retries left, wait and retry
      if (_retryCount < _maxRetries - 1) {
        _retryCount++;
        debugPrint('Profile not found, retrying in ${_retryDelay.inMilliseconds}ms... (attempt ${_retryCount + 1}/$_maxRetries)');
        await Future.delayed(_retryDelay);
        return await _getProfileWithRetry();
      }
      
      // After all retries failed, check if this is an orphaned account
      debugPrint('Profile not found after $_maxRetries attempts - checking for orphaned account');
      final authService = AuthService();
      final isOrphaned = await authService.isOrphanedAccount();
      
      if (isOrphaned) {
        debugPrint('🧹 Cleaning up orphaned Firebase Auth account...');
        try {
          await authService.cleanupOrphanedAccount();
        } catch (e) {
          debugPrint('Failed to cleanup orphaned account: $e');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting profile on attempt ${_retryCount + 1}: $e');
      
      // If error occurred and we have retries left, wait and retry
      if (_retryCount < _maxRetries - 1) {
        _retryCount++;
        debugPrint('Retrying after error in ${_retryDelay.inMilliseconds}ms... (attempt ${_retryCount + 1}/$_maxRetries)');
        await Future.delayed(_retryDelay);
        return await _getProfileWithRetry();
      }
      
      rethrow;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    debugPrint('_AuthenticatedUserScreen build called for user: ${widget.user.email}');
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getProfileWithRetry(),
      builder: (context, snapshot) {
        debugPrint('Profile FutureBuilder: connectionState=${snapshot.connectionState}, hasError=${snapshot.hasError}, hasData=${snapshot.hasData}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('Profile loading...');
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
          debugPrint('Profile error: ${snapshot.error}');
          debugPrint('Redirecting to AddPhoneScreen due to profile error');
          return const AddPhoneScreen();
        }
        
        final profile = snapshot.data;
        debugPrint('Profile data: ${profile != null ? 'exists' : 'null'}');
        
        // Enhanced routing logic with detailed debugging
        debugPrint('🔍 ROUTING DECISION POINT - Profile Analysis:');
        debugPrint('   - Profile exists: ${profile != null}');
        if (profile != null) {
          debugPrint('   - Profile keys: ${profile.keys.toList()}');
          debugPrint('   - Phone number: "${profile['phone_number']}" (${profile['phone_number']?.runtimeType})');
          debugPrint('   - Display name: "${profile['display_name']}" (${profile['display_name']?.runtimeType})');
          debugPrint('   - Email: "${profile['email']}" (${profile['email']?.runtimeType})');
        }

        if (profile == null) {
          debugPrint('❌ ROUTING: No profile found → AddPhoneScreen');
          return const AddPhoneScreen();
        }
        
        final phoneNumber = profile['phone_number'];
        if (phoneNumber == null || phoneNumber.toString().isEmpty) {
          debugPrint('❌ ROUTING: Missing phone number → AddPhoneScreen');
          debugPrint('   - Phone value: $phoneNumber');
          debugPrint('   - Is null: ${phoneNumber == null}');
          debugPrint('   - Is empty string: ${phoneNumber.toString().isEmpty}');
          return const AddPhoneScreen();
        }
        
        final displayName = profile['display_name'];
        if (displayName == null || displayName.toString().isEmpty) {
          debugPrint('❌ ROUTING: Missing display name → SetupNameScreen');
          debugPrint('   - Display name value: $displayName');
          debugPrint('   - Is null: ${displayName == null}');
          debugPrint('   - Is empty string: ${displayName.toString().isEmpty}');
          return const SetupNameScreen();
        }
        
        debugPrint('✅ ROUTING: Complete profile found → HomeScreen');
        debugPrint('   - Phone: "$phoneNumber"');
        debugPrint('   - Name: "$displayName"');
        debugPrint('   - Email: "${profile['email']}"');
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

  final List<Widget> _screens = const [
    WishlistsScreen(),
    ExploreScreen(),
    FriendsScreen(),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Wishlists',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.public),
              label: 'Explorar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star),
              label: 'Favoritos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person), 
              label: 'Perfil'
            ),
          ],
        ),
      ),
    );
  }
}
