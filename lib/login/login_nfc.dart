import 'dart:math';

import 'package:flutter/material.dart';

class LoginNFC extends StatefulWidget {
  const LoginNFC({super.key, required this.setUserCredentials});

  final Function(String, String) setUserCredentials;

  @override
  State<LoginNFC> createState() => _LoginNFCState();
}

class _LoginNFCState extends State<LoginNFC>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color accent = Theme.of(context).colorScheme.primaryContainer;
    Color onAccent = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    border: Border.all(color: onAccent, width: 4),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: pi / 2,
                      child:
                          Icon(Icons.wifi_rounded, size: 80, color: onAccent),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 60),
          const Text(
            "Login using your work card",
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
