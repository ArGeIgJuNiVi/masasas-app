import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

//TODO keep screen on setting
class Settings {
  static late SharedPreferences sharedPreferences;
  static bool _initialized = false;
  static bool _waiting = false;

  static var api = (scheme: "http", host: "localhost", port: 5088);

  static var guest = (enabled: true, id: "guest", password: "1234");

  static Future init() async {
    try {
      sharedPreferences = await SharedPreferences.getInstance();
      _initialized = true;
      load();
      await save();
    } catch (e) {
      if (kDebugMode) print(e);
    }
  }

  static Future save() async {
    if (_initialized && !_waiting) {
      _waiting = true;
      await Future.wait(
        [
          sharedPreferences.setString("apiScheme", api.scheme),
          sharedPreferences.setString("apiHost", api.host),
          sharedPreferences.setInt("apiPort", api.port),
          sharedPreferences.setBool("guestEnabled", guest.enabled),
          sharedPreferences.setString("guestID", guest.id),
          sharedPreferences.setString("guestPassword", guest.password),
        ],
      );
      _waiting = false;
    }
  }

  static load() {
    if (_initialized && !_waiting) {
      api = (
        scheme: sharedPreferences.getString("apiScheme") ?? api.scheme,
        host: sharedPreferences.getString("apiHost") ?? api.host,
        port: sharedPreferences.getInt("apiPort") ?? api.port,
      );
      guest = (
        enabled: sharedPreferences.getBool("guestEnabled") ?? guest.enabled,
        id: sharedPreferences.getString("guestID") ?? guest.id,
        password:
            sharedPreferences.getString("guestPassword") ?? guest.password,
      );
    }
  }
}

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key, required this.closeSettings});

  final Function() closeSettings;

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  final TextEditingController _apiHost =
      TextEditingController(text: Settings.api.host);
  final TextEditingController _apiScheme =
      TextEditingController(text: Settings.api.scheme);
  final TextEditingController _apiPort =
      TextEditingController(text: Settings.api.port.toString());

  bool _obscurePassword = true;
  bool _guestEnabled = Settings.guest.enabled;
  final TextEditingController _guestID =
      TextEditingController(text: Settings.guest.id);
  final TextEditingController _guestPassword =
      TextEditingController(text: Settings.guest.password);

  void updateConfig([_]) async {
    Settings.api = (
      host: _apiHost.text.isNotEmpty ? _apiHost.text : "localhost",
      scheme: _apiScheme.text.isNotEmpty ? _apiScheme.text : "http",
      port: int.parse(_apiPort.text.isNotEmpty ? _apiPort.text : "5088")
    );

    Settings.guest = (
      enabled: _guestEnabled,
      id: _guestID.text,
      password: _guestPassword.text,
    );

    await Settings.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double columnWidth = MediaQuery.of(context).size.width - 48;
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      columnWidth /= 2;
    }

    return Stack(
      children: [
        SingleChildScrollView(
          child: Wrap(
            alignment: WrapAlignment.spaceAround,
            children: [
              const Center(
                child: Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 32,
                  ),
                ),
              ),
              SizedBox(
                width: columnWidth,
                child: Column(
                  children: [
                    Wrap(
                      runSpacing: 12,
                      children: [
                        const Text("Api"),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Host',
                            border: OutlineInputBorder(),
                          ),
                          controller: _apiHost,
                          onChanged: updateConfig,
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Scheme',
                            border: OutlineInputBorder(),
                          ),
                          controller: _apiScheme,
                          onChanged: updateConfig,
                        ),
                        TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          controller: _apiPort,
                          onChanged: updateConfig,
                          decoration: const InputDecoration(
                            labelText: "Port",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: columnWidth,
                child: Column(
                  children: [
                    Wrap(
                      runSpacing: 12,
                      children: [
                        const Text("Guest"),
                        Row(
                          children: [
                            Checkbox(
                              value: _guestEnabled,
                              onChanged: (_) {
                                _guestEnabled = !_guestEnabled;
                                updateConfig();
                              },
                            ),
                            const Text("Enabled"),
                          ],
                        ),
                        Visibility(
                          visible: _guestEnabled,
                          child: Column(
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'ID',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _guestID,
                                onChanged: updateConfig,
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              TextField(
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                controller: _guestPassword,
                                onChanged: updateConfig,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        BackButton(
          onPressed: widget.closeSettings,
        ),
      ],
    );
  }
}
