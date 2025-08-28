import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wishlist_app/config.dart';
import 'package:wishlist_app/theme.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/user_service.dart';
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

  // Initialize Supabase (for database only)
  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );

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
  List<SharedFile>? _pendingSharedData;

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
        } else {
          setState(() {
            _pendingSharedData = value;
          });
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

  /// Cleanup incomplete accounts - force logout and delete orphaned profile
  Future<void> _cleanupIncompleteAccount(firebase_auth.User user) async {
    try {
      debugPrint('=== Cleaning up incomplete account ===');
      debugPrint('User ID: ${user.uid}');
      debugPrint('Email: ${user.email}');
      
      // Try to delete orphaned profile from Supabase (may fail if doesn't exist)
      try {
        await UserService().deleteUserProfile(user.uid);
        debugPrint('Orphaned profile deleted from Supabase');
      } catch (e) {
        debugPrint('Profile not found in Supabase (expected): $e');
      }
      
      // Sign out from Firebase (this will also sign out from Google)
      await AuthService().signOut();
      
      debugPrint('Incomplete account cleaned up successfully');
    } catch (e) {
      debugPrint('Error cleaning up incomplete account: $e');
      // Force logout anyway
      await AuthService().signOut();
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
            GlobalCupertinoLocalizations.delegate,
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                // User is logged in, check for phone number
                return FutureBuilder<Map<String, dynamic>?>(
                  future: UserService().getUserProfile(snapshot.data!.uid),
                  builder: (context, profileSnapshot) {
                    if (profileSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final profile = profileSnapshot.data;
                    
                    // Phone number is ALWAYS required, regardless of login method
                    if (profile == null ||
                        profile['phone_number'] == null ||
                        profile['phone_number'].toString().isEmpty) {
                      
                      // Check if user just logged in (no profile exists yet)
                      if (profile == null) {
                        debugPrint('No profile found - checking if user has both providers already');
                        
                        // Check if Firebase user already has both Google and Phone providers
                        final user = snapshot.data!;
                        final providerIds = user.providerData.map((p) => p.providerId).toList();
                        final hasGoogle = providerIds.contains('google.com');
                        final hasPhone = providerIds.contains('phone');
                        final hasEmailPassword = providerIds.contains('password');
                        
                        if ((hasGoogle || hasEmailPassword) && hasPhone && user.phoneNumber != null) {
                          debugPrint('User has both auth providers and phone number - syncing to Supabase');
                          return FutureBuilder<void>(
                            future: AuthService().syncExistingUserProfile(),
                            builder: (context, syncSnapshot) {
                              if (syncSnapshot.connectionState == ConnectionState.waiting) {
                                return const Scaffold(
                                  body: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('Syncing profile...'),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              if (syncSnapshot.hasError) {
                                debugPrint('Error syncing profile: ${syncSnapshot.error}');
                                // If sync fails, clean up and return to login
                                return FutureBuilder<void>(
                                  future: _cleanupIncompleteAccount(user),
                                  builder: (context, cleanupSnapshot) {
                                    return const LoginScreen();
                                  },
                                );
                              }
                              
                              // Sync completed, refresh the profile check
                              return FutureBuilder<Map<String, dynamic>?>(
                                future: UserService().getUserProfile(user.uid),
                                builder: (context, profileSnapshot) {
                                  if (profileSnapshot.connectionState == ConnectionState.waiting) {
                                    return const Scaffold(body: Center(child: CircularProgressIndicator()));
                                  }
                                  
                                  final syncedProfile = profileSnapshot.data;
                                  if (syncedProfile != null && 
                                      syncedProfile['display_name'] != null &&
                                      syncedProfile['display_name'].toString().isNotEmpty) {
                                    return const HomeScreen();
                                  } else if (syncedProfile != null) {
                                    return const SetupNameScreen();
                                  } else {
                                    return const LoginScreen();
                                  }
                                },
                              );
                            },
                          );
                        } else {
                          debugPrint('No profile found - redirecting to phone screen');
                          return const AddPhoneScreen();
                        }
                      }
                      
                      // Profile exists but no phone - account is incomplete, cleanup needed
                      debugPrint('Profile exists but missing phone - cleaning up');
                      return FutureBuilder<void>(
                        future: _cleanupIncompleteAccount(snapshot.data!),
                        builder: (context, cleanupSnapshot) {
                          if (cleanupSnapshot.connectionState == ConnectionState.waiting) {
                            return const Scaffold(
                              body: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Cleaning up incomplete account...'),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const LoginScreen();
                        },
                      );
                    } else if (profile['display_name'] == null ||
                               profile['display_name'].toString().isEmpty) {
                      // Phone number exists but display name is missing, navigate to SetupNameScreen
                      return const SetupNameScreen();
                    } else {
                      // Both phone number and display name exist, proceed to home
                      if (_pendingSharedData != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _handleSharedMedia(_pendingSharedData!);
                          _pendingSharedData = null;
                        });
                      }
                      return const HomeScreen();
                    }
                  },
                );
              } else {
                return const LoginScreen();
              }
            },
          ),
        );
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
