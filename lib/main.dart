import 'package:flutter/material.dart';
import 'storage/hive_init.dart';
import 'screens/lists_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInit.init();
  runApp(const SmartShoppingApp());
}

class SmartShoppingApp extends StatelessWidget {
  const SmartShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Shopping Scanner',
      theme: ThemeData(useMaterial3: true),
      home: const ListsScreen(),
    );
  }
}
