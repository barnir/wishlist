import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wishlists_screen.dart';
import 'screens/wishlist_details_screen.dart';
import 'screens/add_edit_wishlist_screen.dart';
import 'screens/add_edit_item_screen.dart';
import 'screens/telefone_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Defina suas rotas nominais aqui para facilitar navegação no futuro!
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wishlist App',
      theme: ThemeData(primarySwatch: Colors.blue),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/wishlists': (_) => const WishlistsScreen(),
        '/wishlist_details': (_) => const WishlistDetailsScreen(),
        '/add_edit_wishlist': (_) => const AddEditWishlistScreen(),
        '/add_edit_item': (_) => const AddEditItemScreen(),
        '/telefoneLogin': (_) => const TelefoneLoginScreen(),
      },
      // Redireciona com base no estado de autenticação:
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              // Usuário logado
              return const WishlistsScreen();
            } else {
              // Usuário não logado
              return const LoginScreen();
            }
          }
          // Loading
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
