import 'dart:math';

import 'package:flutter/material.dart';

class LoginPassword extends StatefulWidget {
  const LoginPassword({super.key, required this.setUserCredentials});

  final Function(String, String) setUserCredentials;

  @override
  State<LoginPassword> createState() => _LoginPasswordState();
}

class _LoginPasswordState extends State<LoginPassword> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: MediaQuery.of(context).size.height > 660,
            child: Icon(
              Icons.table_restaurant,
              size: min(MediaQuery.of(context).size.height / 8,
                  MediaQuery.of(context).size.width / 3),
            ),
          ),
          Visibility(
            visible: MediaQuery.of(context).size.height > 480,
            child: const Text(
              "Masasas",
              style: TextStyle(fontSize: 28),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onSubmitted: (_) {
              widget.setUserCredentials(
                  _usernameController.text, _passwordController.text);
            },
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FloatingActionButton.extended(
              onPressed: () {
                widget.setUserCredentials(
                    _usernameController.text, _passwordController.text);
              },
              icon: const Icon(Icons.login),
              label: const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }
}
