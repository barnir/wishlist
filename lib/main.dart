import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wishlist_app/config.dart';
import 'package:wishlist_app/theme.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/user_service.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wishlists_screen.dart';
import 'screens/add_edit_item_screen.dart';
import 'screens/telefone_login_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/wishlist_details_screen.dart';
import 'screens/add_edit_wishlist_screen.dart';
import 'screens/add_phone_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/friend_suggestions_screen.dart';
import 'screens/user_profile_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: Config.supabaseUrl,
    anonKey: Config.supabaseAnonKey,
  );

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
        if (Supabase.instance.client.auth.currentUser != null) {
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

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Wishlist App',
      theme: lightAppTheme,
      darkTheme: darkAppTheme,
      themeMode: ThemeMode.system, // Adapta-se ao tema do sistema
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
        '/telefoneLogin': (_) => const TelefoneLoginScreen(),
        '/add_phone': (_) => const AddPhoneScreen(),
        '/friend_suggestions': (_) => const FriendSuggestionsScreen(),
        '/user_profile': (context) {
          final userId = ModalRoute.of(context)?.settings.arguments as String;
          return UserProfileScreen(userId: userId);
        },
      },
      home: StreamBuilder<User?>(
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
              future: UserService().getUserProfile(snapshot.data!.id),
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
                  // Phone number is missing, navigate to AddPhoneScreen
                  return const AddPhoneScreen();
                } else {
                  // Phone number exists, proceed to home
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
              icon: Icon(Icons.people),
              label: 'Amigos',
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
