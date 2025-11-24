import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'splash_screen.dart'; // ← زدنا splash screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Everyday App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),

      // ← الآن splash screen هي اللي تظهر أولاً
      home: const SplashScreen(),

      routes: {
        '/welcome': (context) => const WelcomeScreen(), // ← زدناها
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
