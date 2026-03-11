import 'package:flutter/material.dart';

import 'features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const CareerLensApp());
}

class CareerLensApp extends StatelessWidget {
  const CareerLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareerLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E4EA8)),
      ),
      home: const LoginScreen(),
    );
  }
}
