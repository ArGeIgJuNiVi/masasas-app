import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masasas_app/login/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Masasas',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.lightGreen,
        brightness: Brightness.dark,
      ),
      home: const Scaffold(
          body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 16,
        ),
        child: Login(),
      )),
    );
  }
}
