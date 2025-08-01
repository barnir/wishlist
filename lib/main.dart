import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/wish_item.dart';
import 'screens/wishlist_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(WishItemAdapter());
  await Hive.openBox<WishItem>('wishlist');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WishlistScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
