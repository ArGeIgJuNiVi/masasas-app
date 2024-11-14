import 'package:flutter/material.dart';
import 'package:masasas_app/config.dart';

class Settings extends StatefulWidget {
  const Settings({super.key, required this.closeSettings});

  final Function() closeSettings;

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final TextEditingController _hostController = TextEditingController();

  void updateConfig(_) {
    Config.api = (host: _hostController.text, scheme: "http", port: 5088);
    Config.guestCredentials = (id: "guest", password: "1234");
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
