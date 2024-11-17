import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  //global settings methods
  //static var sharedPreferences;
  static bool initialized = false;

  static var api = (scheme: "http", host: "localhost", port: 5088);

  static var guestCredentials = (id: "guest", password: "1234");

  static init() async {
    //sharedPreferences = null;
    initialized = true;
  }

  static save() async {}

  static load() async {} //TODO

  //associated settings widget
  const Settings({super.key, required this.closeSettings});

  final Function() closeSettings;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController _hostController = TextEditingController();

  void updateConfig(_) {
    Settings.api = (host: _hostController.text, scheme: "http", port: 5088);
    Settings.guestCredentials = (id: "guest", password: "1234");
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            TextField(
              controller: _hostController,
              onChanged: updateConfig,
            ),
          ],
        ),
        BackButton(
          onPressed: widget.closeSettings,
        ), //TODO
      ],
    );
  }
}
