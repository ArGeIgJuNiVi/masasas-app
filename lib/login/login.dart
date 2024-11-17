// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:masasas_app/masasas_api/api.dart';
import 'package:masasas_app/login/login_nfc.dart';
import 'package:masasas_app/login/login_user.dart';
import 'package:masasas_app/settings.dart';
import 'package:masasas_app/homepage.dart';
import 'package:nfc_manager/nfc_manager.dart';

enum LoginPageMethod {
  NFC,
  User,
}

Widget loginPageIcon(LoginPageMethod method) => switch (method) {
      LoginPageMethod.NFC => Transform.rotate(
          angle: pi / 2,
          child: const Icon(
            Icons.wifi_rounded,
          ),
        ),
      LoginPageMethod.User => const Icon(Icons.login),
    };

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _settingsOpen = false;
  String? _userID;
  String? _userDailyAccessCode;
  LoginPageMethod _loginMethod = LoginPageMethod.NFC;
  bool _nfcAvailable = false;

  void closeSettings() => setState(() => _settingsOpen = false);

  showError(String error, double distanceFromBottom) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          dismissDirection: DismissDirection.up,
          behavior: SnackBarBehavior.floating,
          margin:
              EdgeInsets.only(bottom: distanceFromBottom, left: 16, right: 16),
          content: Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    }
  }

  void showConfirmation(String confirmation, double distanceFromBottom) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          dismissDirection: DismissDirection.up,
          behavior: SnackBarBehavior.floating,
          margin:
              EdgeInsets.only(bottom: distanceFromBottom, left: 16, right: 16),
          content: Text(
            confirmation,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }
  }

  void setUserCredentials(String userID, String password) async {
    MasasasResponse userCredentials =
        await MasasasApi.getUser(userID, password);
    switch (userCredentials.result) {
      case MasasasResult.ok:
        try {
          var json = jsonDecode(userCredentials.body);
          _userID = json["UserID"];
          _userDailyAccessCode = json["DailyAccessCode"];
        } catch (e) {
          if (kDebugMode) print(e);
          showError("Received invalid user data", 88);
        }
        return setState(() {});

      default:
        showError(userCredentials.body, 88);
        return;
    }
  }

  @override
  void initState() {
    checkNFC();
    super.initState();
  }

  void checkNFC() async {
    try {
      _nfcAvailable = await NfcManager.instance.isAvailable();
    } catch (_) {
      _nfcAvailable = false;
    }
    if (_nfcAvailable) _loginMethod = LoginPageMethod.NFC;
    setState(() {});
  }

  Future invalidateUserCredentials([String? error]) async {
    if (_nfcAvailable) {
      await NfcManager.instance.stopSession();
    }
    _userID = null;
    _userDailyAccessCode = null;

    if (error != null) {
      showError(error, 88);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_settingsOpen) return SettingsWidget(closeSettings: closeSettings);

    if (_userID != null && _userDailyAccessCode != null) {
      return Homepage(
        showError: showError,
        showConfirmation: showConfirmation,
        userID: _userID!,
        userDailyAccessCode: _userDailyAccessCode!,
        invalidateUserCredentials: invalidateUserCredentials,
        nfcAvailable: _nfcAvailable,
      );
    }

    List<LoginPageMethod> otherLoginMethods = LoginPageMethod.values.toList();

    if (!_nfcAvailable) {
      if (_loginMethod == LoginPageMethod.NFC) {
        _loginMethod = LoginPageMethod.User;
      }
      otherLoginMethods.remove(LoginPageMethod.NFC);
    }

    otherLoginMethods.remove(_loginMethod);

    return Stack(
      children: [
        switch (_loginMethod) {
          LoginPageMethod.NFC => LoginNFC(
              setUserCredentials: setUserCredentials,
              showError: invalidateUserCredentials,
            ),
          LoginPageMethod.User => LoginPassword(
              setUserCredentials: setUserCredentials,
            ),
        },
        IconButton(
          onPressed: () => setState(() => _settingsOpen = true),
          icon: const Icon(Icons.settings),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...(List.generate(
                  otherLoginMethods.length,
                  (index) => FloatingActionButton.extended(
                        label: Text("${otherLoginMethods[index].name} Login"),
                        icon: loginPageIcon(otherLoginMethods[index]),
                        onPressed: () => setState(
                            () => _loginMethod = otherLoginMethods[index]),
                      ))),
              Visibility(
                visible: Settings.guest.enabled,
                child: FloatingActionButton.extended(
                    label: const Text("Guest Login"),
                    icon: const Icon(Icons.person),
                    onPressed: () => setUserCredentials(
                          Settings.guest.id,
                          Settings.guest.password,
                        )),
              ),
            ],
          ),
        )
      ],
    );
  }
}
