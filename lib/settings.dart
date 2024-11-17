import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masasas_app/height.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

abstract class Settings {
  static late SharedPreferences sharedPreferences;
  static bool _initialized = false;
  static bool _waiting = false;

  static var api = (
    scheme: "http",
    host: "localhost",
    port: 5088,
  );

  static var guest = (
    enabled: true,
    id: "guest",
    password: "1234",
  );

  static var app = (
    keepScreenOn: false,
    defaultUnit: "m",
  );

  static var tracking = (
    enabled: true,
    maxMinutes: 480,
    sittingReminder: true,
    sittingTooLongMinutes: 120,
    sittingHeight: HeightValue("m", 0.8),
  );

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
          sharedPreferences.setString(
            "apiScheme",
            api.scheme,
          ),
          sharedPreferences.setString(
            "apiHost",
            api.host,
          ),
          sharedPreferences.setInt(
            "apiPort",
            api.port,
          ),
          sharedPreferences.setBool(
            "guestEnabled",
            guest.enabled,
          ),
          sharedPreferences.setString(
            "guestID",
            guest.id,
          ),
          sharedPreferences.setString(
            "guestPassword",
            guest.password,
          ),
          sharedPreferences.setBool(
            "appKeepScreenOn",
            app.keepScreenOn,
          ),
          sharedPreferences.setBool(
            "trackingEnabled",
            tracking.enabled,
          ),
          sharedPreferences.setInt(
            "trackingMaxMinutes",
            tracking.maxMinutes,
          ),
          sharedPreferences.setBool(
            "trackingSittingReminder",
            tracking.sittingReminder,
          ),
          sharedPreferences.setInt(
            "trackingSittingTooLongMinutes",
            tracking.sittingTooLongMinutes,
          ),
          sharedPreferences.setString(
            "trackingSittingHeightUnit",
            tracking.sittingHeight.unit,
          ),
          sharedPreferences.setDouble(
            "trackingSittingHeightValue",
            tracking.sittingHeight.unitValue.toDouble(),
          ),
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
      app = (
        keepScreenOn:
            sharedPreferences.getBool("appKeepScreenOn") ?? app.keepScreenOn,
        defaultUnit:
            sharedPreferences.getString("appDefaultUnit") ?? app.defaultUnit,
      );
      tracking = (
        enabled: sharedPreferences.getBool("trackingSittingEnabled") ??
            tracking.enabled,
        maxMinutes: sharedPreferences.getInt("trackingMaxMinutes") ??
            tracking.maxMinutes,
        sittingReminder: sharedPreferences.getBool("trackingSittingReminder") ??
            tracking.sittingReminder,
        sittingTooLongMinutes:
            sharedPreferences.getInt("trackingSittingTooLongMinutes") ??
                tracking.sittingTooLongMinutes,
        sittingHeight: HeightValue.adjusted(
            sharedPreferences.getString("trackingSittingHeightUnit") ??
                tracking.sittingHeight.unit,
            sharedPreferences.getDouble("trackingSittingHeightValue") ??
                tracking.sittingHeight.value),
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

  bool _appKeepScreenOn = Settings.app.keepScreenOn;
  String _appDefaultUnit = Settings.app.defaultUnit;

  bool _trackingEnabled = Settings.tracking.enabled;
  final TextEditingController _trackingMaxMinutes =
      TextEditingController(text: Settings.tracking.maxMinutes.toString());
  final TextEditingController _trackingSittingHeightValue =
      TextEditingController(
          text: Settings.tracking.sittingHeight.toStringWithoutUnit());
  String _trackingSittingHeightUnit = Settings.tracking.sittingHeight.unit;
  bool _trackingSittingReminder = Settings.tracking.sittingReminder;
  final TextEditingController _trackingSittingTooLongMinutes =
      TextEditingController(
          text: Settings.tracking.sittingTooLongMinutes.toString());

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

    WakelockPlus.toggle(enable: _appKeepScreenOn);

    Settings.app = (
      keepScreenOn: _appKeepScreenOn,
      defaultUnit: _appDefaultUnit,
    );

    Settings.tracking = (
      enabled: _trackingEnabled,
      maxMinutes: int.parse(
        _trackingMaxMinutes.text.isNotEmpty ? _trackingMaxMinutes.text : "120",
      ),
      sittingReminder: _trackingSittingReminder,
      sittingTooLongMinutes: int.parse(
        _trackingSittingTooLongMinutes.text.isNotEmpty
            ? _trackingSittingTooLongMinutes.text
            : "480",
      ),
      sittingHeight: HeightValue.adjusted(
          _trackingSittingHeightUnit,
          num.parse(
            _trackingSittingHeightValue.text.isNotEmpty
                ? _trackingSittingHeightValue.text
                : "0.8",
          )),
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
            runSpacing: 32,
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
                    const SizedBox(height: 32),
                    Wrap(
                      runSpacing: 12,
                      children: [
                        const Text("App"),
                        Row(
                          children: [
                            Checkbox(
                              value: _appKeepScreenOn,
                              onChanged: (_) {
                                _appKeepScreenOn = !_appKeepScreenOn;
                                updateConfig();
                              },
                            ),
                            const Text("Keep screen on"),
                          ],
                        ),
                        Row(
                          children: [
                            const Text("Default unit:"),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: DropdownButton(
                                value: _appDefaultUnit,
                                items: const [
                                  DropdownMenuItem(
                                      value: "m", child: Text("m")),
                                  DropdownMenuItem(
                                      value: "cm", child: Text("cm")),
                                  DropdownMenuItem(
                                      value: "burgers", child: Text("inch"))
                                ],
                                onChanged: (String? val) {
                                  _appDefaultUnit =
                                      val ?? Settings.app.defaultUnit;
                                  updateConfig();
                                },
                              ),
                            ),
                          ],
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
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'ID',
                              border: OutlineInputBorder(),
                            ),
                            controller: _guestID,
                            onChanged: updateConfig,
                          ),
                        ),
                        Visibility(
                          visible: _guestEnabled,
                          child: TextField(
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                tooltip: "Toggle visibility",
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      runSpacing: 12,
                      children: [
                        const Text("Tracking"),
                        Row(
                          children: [
                            Checkbox(
                              value: _trackingEnabled,
                              onChanged: (_) {
                                _trackingEnabled = !_trackingEnabled;
                                updateConfig();
                              },
                            ),
                            const Text("Enabled"),
                          ],
                        ),
                        Visibility(
                          visible: _trackingEnabled,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            controller: _trackingMaxMinutes,
                            onChanged: updateConfig,
                            decoration: const InputDecoration(
                              labelText: "Max minutes",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _trackingEnabled,
                          child: Row(
                            children: [
                              Checkbox(
                                value: _trackingSittingReminder,
                                onChanged: (_) {
                                  _trackingSittingReminder =
                                      !_trackingSittingReminder;
                                  updateConfig();
                                },
                              ),
                              const Text("Sitting Reminder"),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: _trackingEnabled && _trackingSittingReminder,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 200,
                                child: TextField(
                                  controller: _trackingSittingHeightValue,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'))
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: "Sitting Height",
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: updateConfig,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: DropdownButton(
                                    value: _trackingSittingHeightUnit,
                                    items: const [
                                      DropdownMenuItem(
                                          value: "m", child: Text("m")),
                                      DropdownMenuItem(
                                          value: "cm", child: Text("cm")),
                                      DropdownMenuItem(
                                          value: "%", child: Text("%")),
                                      DropdownMenuItem(
                                          value: "burgers", child: Text("inch"))
                                    ],
                                    onChanged: (String? val) {
                                      if (_trackingSittingHeightUnit == "%" ||
                                          val == "%") {
                                        Settings.tracking.sittingHeight.value =
                                            0;
                                      }
                                      _trackingSittingHeightUnit = val ?? "m";
                                      _trackingSittingHeightValue.text =
                                          HeightValue(
                                        _trackingSittingHeightUnit,
                                        Settings.tracking.sittingHeight.value,
                                      ).toStringWithoutUnit();
                                      updateConfig();
                                    }),
                              )
                            ],
                          ),
                        ),
                        Visibility(
                          visible: _trackingEnabled && _trackingSittingReminder,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            controller: _trackingSittingTooLongMinutes,
                            onChanged: updateConfig,
                            decoration: const InputDecoration(
                              labelText: "Sitting too long minutes",
                              border: OutlineInputBorder(),
                            ),
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
