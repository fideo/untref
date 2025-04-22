import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const UntrefApp());
}

class UntrefApp extends StatelessWidget {
  const UntrefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UNTREF Natación',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomeScreen(),
    );
  }
}