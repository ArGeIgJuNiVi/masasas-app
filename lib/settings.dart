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

  static var apiScheme = "http";
  static var apiHost = "localhost";
  static var apiPort = 5088;

  static var guestEnabled = true;
  static var guestID = "guest";
  static var guestPassword = "1234";

  static var appKeepScreenOn = false;
  static var appPresetPersonalization = true;
  static var appDefaultUnit = "m";
  static var appDefaultTable = "";

  static var trackingEnabled = true;
  static var trackingGuest = false;
  static var trackingMaxMinutes = 480;
  static var trackingMaxSessions = 480;
  static var trackingSittingReminder = true;
  static var trackingSittingTooLongMinutes = 120;
  static var trackingSittingHeight = HeightValue("m", 1.0);

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
            apiScheme,
          ),
          sharedPreferences.setString(
            "apiHost",
            apiHost,
          ),
          sharedPreferences.setInt(
            "apiPort",
            apiPort,
          ),
          sharedPreferences.setBool(
            "guestEnabled",
            guestEnabled,
          ),
          sharedPreferences.setString(
            "guestID",
            guestID,
          ),
          sharedPreferences.setString(
            "guestPassword",
            guestPassword,
          ),
          sharedPreferences.setBool(
            "appKeepScreenOn",
            appKeepScreenOn,
          ),
          sharedPreferences.setBool(
            "appPresetPersonalization",
            appPresetPersonalization,
          ),
          sharedPreferences.setString(
            "appDefaultUnit",
            appDefaultUnit,
          ),
          sharedPreferences.setString(
            "appDefaultTable",
            appDefaultTable,
          ),
          sharedPreferences.setBool(
            "trackingEnabled",
            trackingEnabled,
          ),
          sharedPreferences.setBool(
            "trackingGuest",
            trackingGuest,
          ),
          sharedPreferences.setInt(
            "trackingMaxMinutes",
            trackingMaxMinutes,
          ),
          sharedPreferences.setInt(
            "trackingMaxSessions",
            trackingMaxSessions,
          ),
          sharedPreferences.setBool(
            "trackingSittingReminder",
            trackingSittingReminder,
          ),
          sharedPreferences.setInt(
            "trackingSittingTooLongMinutes",
            trackingSittingTooLongMinutes,
          ),
          sharedPreferences.setString(
            "trackingSittingHeightUnit",
            trackingSittingHeight.unit,
          ),
          sharedPreferences.setDouble(
            "trackingSittingHeightValue",
            trackingSittingHeight.unitValue.toDouble(),
          ),
        ],
      );
      _waiting = false;
    }
  }

  static load() {
    if (_initialized && !_waiting) {
      apiScheme = sharedPreferences.getString("apiScheme") ?? apiScheme;
      apiHost = sharedPreferences.getString("apiHost") ?? apiHost;
      apiPort = sharedPreferences.getInt("apiPort") ?? apiPort;

      guestEnabled = sharedPreferences.getBool("guestEnabled") ?? guestEnabled;
      guestID = sharedPreferences.getString("guestID") ?? guestID;
      guestPassword =
          sharedPreferences.getString("guestPassword") ?? guestPassword;

      appKeepScreenOn =
          sharedPreferences.getBool("appKeepScreenOn") ?? appKeepScreenOn;
      appPresetPersonalization =
          sharedPreferences.getBool("appPresetPersonalization") ??
              appPresetPersonalization;
      appDefaultUnit =
          sharedPreferences.getString("appDefaultUnit") ?? appDefaultUnit;
      appDefaultTable =
          sharedPreferences.getString("appDefaultTable") ?? appDefaultTable;

      trackingEnabled =
          sharedPreferences.getBool("trackingEnabled") ?? trackingEnabled;
      trackingGuest =
          sharedPreferences.getBool("trackingGuest") ?? trackingGuest;
      trackingMaxMinutes =
          sharedPreferences.getInt("trackingMaxMinutes") ?? trackingMaxMinutes;
      trackingMaxSessions = sharedPreferences.getInt("trackingMaxSessions") ??
          trackingMaxSessions;
      trackingSittingReminder =
          sharedPreferences.getBool("trackingSittingReminder") ??
              trackingSittingReminder;
      trackingSittingTooLongMinutes =
          sharedPreferences.getInt("trackingSittingTooLongMinutes") ??
              trackingSittingTooLongMinutes;
      trackingSittingHeight = HeightValue.adjusted(
          sharedPreferences.getString("trackingSittingHeightUnit") ??
              trackingSittingHeight.unit,
          sharedPreferences.getDouble("trackingSittingHeightValue") ??
              trackingSittingHeight.value);
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
      TextEditingController(text: Settings.apiHost);
  final TextEditingController _apiScheme =
      TextEditingController(text: Settings.apiScheme);
  final TextEditingController _apiPort =
      TextEditingController(text: Settings.apiPort.toString());

  bool _obscurePassword = true;
  bool _guestEnabled = Settings.guestEnabled;
  final TextEditingController _guestID =
      TextEditingController(text: Settings.guestID);
  final TextEditingController _guestPassword =
      TextEditingController(text: Settings.guestPassword);

  bool _appKeepScreenOn = Settings.appKeepScreenOn;
  bool _appPresetPersonalization = Settings.appPresetPersonalization;
  String _appDefaultUnit = Settings.appDefaultUnit;
  final TextEditingController _appDefaultTable =
      TextEditingController(text: Settings.appDefaultTable);

  bool _trackingEnabled = Settings.trackingEnabled;
  bool _trackingGuest = Settings.trackingGuest;
  final TextEditingController _trackingMaxMinutes =
      TextEditingController(text: Settings.trackingMaxMinutes.toString());
  final TextEditingController _trackingMaxSessions =
      TextEditingController(text: Settings.trackingMaxSessions.toString());
  final TextEditingController _trackingSittingHeightValue =
      TextEditingController(
          text: Settings.trackingSittingHeight.toStringWithoutUnit());
  String _trackingSittingHeightUnit = Settings.trackingSittingHeight.unit;
  bool _trackingSittingReminder = Settings.trackingSittingReminder;
  final TextEditingController _trackingSittingTooLongMinutes =
      TextEditingController(
          text: Settings.trackingSittingTooLongMinutes.toString());

  void updateConfig([_]) async {
    Settings.apiHost = _apiHost.text.isNotEmpty ? _apiHost.text : "localhost";
    Settings.apiScheme = _apiScheme.text.isNotEmpty ? _apiScheme.text : "http";
    Settings.apiPort =
        int.parse(_apiPort.text.isNotEmpty ? _apiPort.text : "5088");

    Settings.guestEnabled = _guestEnabled;
    Settings.guestID = _guestID.text;
    Settings.guestPassword = _guestPassword.text;

    WakelockPlus.toggle(enable: _appKeepScreenOn);

    Settings.appKeepScreenOn = _appKeepScreenOn;
    Settings.appPresetPersonalization = _appPresetPersonalization;
    Settings.appDefaultUnit = _appDefaultUnit;
    Settings.appDefaultTable = _appDefaultTable.text;

    Settings.trackingEnabled = _trackingEnabled;
    Settings.trackingGuest = _trackingGuest;
    Settings.trackingMaxMinutes = int.parse(
      _trackingMaxMinutes.text.isNotEmpty ? _trackingMaxMinutes.text : "120",
    );
    Settings.trackingMaxSessions = int.parse(
      _trackingMaxSessions.text.isNotEmpty ? _trackingMaxSessions.text : "120",
    );
    Settings.trackingSittingReminder = _trackingSittingReminder;
    Settings.trackingSittingTooLongMinutes = int.parse(
      _trackingSittingTooLongMinutes.text.isNotEmpty
          ? _trackingSittingTooLongMinutes.text
          : "480",
    );
    Settings.trackingSittingHeight = HeightValue.adjusted(
        _trackingSittingHeightUnit,
        num.parse(
          _trackingSittingHeightValue.text.isNotEmpty
              ? _trackingSittingHeightValue.text
              : "0.8",
        ));

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
                            Checkbox(
                              value: _appPresetPersonalization,
                              onChanged: (_) {
                                _appPresetPersonalization =
                                    !_appPresetPersonalization;
                                updateConfig();
                              },
                            ),
                            const Text("Preset personalization"),
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
                                      val ?? Settings.appDefaultUnit;
                                  updateConfig();
                                },
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Default table',
                            border: OutlineInputBorder(),
                          ),
                          controller: _appDefaultTable,
                          onChanged: updateConfig,
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
                          child: Row(
                            children: [
                              Checkbox(
                                value: _trackingGuest,
                                onChanged: (_) {
                                  _trackingGuest = !_trackingGuest;
                                  updateConfig();
                                },
                              ),
                              const Text("Track guest"),
                            ],
                          ),
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
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            controller: _trackingMaxSessions,
                            onChanged: updateConfig,
                            decoration: const InputDecoration(
                              labelText: "Max sessions count",
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
                                        Settings.trackingSittingHeight.value =
                                            0;
                                      }
                                      _trackingSittingHeightUnit =
                                          val ?? Settings.appDefaultUnit;
                                      _trackingSittingHeightValue.text =
                                          HeightValue(
                                        _trackingSittingHeightUnit,
                                        Settings.trackingSittingHeight.value,
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
        Positioned(
          top: 0,
          right: 0,
          child: OutlinedButton.icon(
            label: const Text("Settings"),
            onPressed: widget.closeSettings,
            icon: const Icon(
              Icons.settings,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }
}
