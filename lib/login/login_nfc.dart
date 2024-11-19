import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:masasas_app/nfc.dart';
import 'package:nfc_manager/nfc_manager.dart';

class LoginNFC extends StatefulWidget {
  const LoginNFC(
      {super.key, required this.setUserCredentials, required this.showError});

  final Function(String, String) setUserCredentials;
  final Function(String) showError;

  @override
  State<LoginNFC> createState() => _LoginNFCState();
}

class _LoginNFCState extends State<LoginNFC>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Timer nfcDelay;

  @override
  void initState() {
    super.initState();

    //wait a little before initializing nfc to prevent interference when coming from the admin menu
    nfcDelay = Timer(Durations.medium1, () {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          var user = getUserFromNfcCard(tag);
          if (kDebugMode) print(user);
          if (user.error != null) {
            widget.showError(user.error!);
            return;
          }
          widget.setUserCredentials(user.id, user.password);
        },
      );
    });

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
    NfcManager.instance.stopSession();
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
                  width: MediaQuery.of(context).size.shortestSide / 3,
                  height: MediaQuery.of(context).size.shortestSide / 3,
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
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
