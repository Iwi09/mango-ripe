import 'package:flutter/material.dart';

import 'login_screen.dart';

void main() {
  runApp(const MangoApp());
}

class MangoApp extends StatelessWidget {
  const MangoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mango Detect',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8870E)),
        scaffoldBackgroundColor: const Color(0xFFFFFBF0),
      ),
      home: const LoginScreen(),
    );
  }
}