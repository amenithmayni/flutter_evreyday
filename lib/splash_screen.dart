import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation Controller
    _controller = AnimationController(
      duration: const Duration(seconds: 1), // duree Zoom
      vsync: this,
    );

    // Scale Animation:  
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,   
    ));

    _controller.forward();  

         
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/welcome');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), 
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  "assets/images/logo.jpeg",   
                  width: 200, 
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 40),
            child: Text(
              "Welcome",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF444444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
