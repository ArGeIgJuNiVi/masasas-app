import 'package:flutter/material.dart';
import 'package:masasas_app/api.dart';
import 'package:masasas_app/config.dart';
import 'package:masasas_app/login/login_nfc.dart';
import 'package:masasas_app/login/login_user.dart';
import 'package:masasas_app/login/settings.dart';
import 'package:masasas_app/models.dart';
import 'package:masasas_app/table_list.dart';
import 'package:nfc_manager/nfc_manager.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _settingsOpen = false;
  String? _userID;
  String? _userDailyAccessCode;
  LoginPageMethod loginMethod = LoginPageMethod.NFC;

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

  void setUserCredentials(String userID, String password) async {
    var dailyAccessCode =
        await MasasasApi.getUserDailyAccessCode(userID, password);
    switch (dailyAccessCode.result) {
      case MasasasResult.ok:
        _userID = userID;
        _userDailyAccessCode = dailyAccessCode.body;
        return setState(() {});

      default:
        showError(dailyAccessCode.body, 88);
        return;
    }
  }

  bool _nfcAvailable = false;
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
    setState(() {});
  }

  void invalidateUserCredentials([String? error]) {
    _userID = null;
    _userDailyAccessCode = null;

    if (error != null) {
      showError(error, 88);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_settingsOpen) return Settings(closeSettings: closeSettings);

    if (_userID != null && _userDailyAccessCode != null) {
      return TableList(
        showError: showError,
        userID: _userID!,
        userDailyAccessCode: _userDailyAccessCode!,
        invalidateUserCredentials: invalidateUserCredentials,
      );
    }

    List<LoginPageMethod> otherLoginMethods = LoginPageMethod.values.toList();

    if (!_nfcAvailable) {
      if (loginMethod == LoginPageMethod.NFC) {
        loginMethod = LoginPageMethod.User;
      }
      otherLoginMethods.remove(LoginPageMethod.NFC);
    }

    otherLoginMethods.remove(loginMethod);

    return Stack(
      children: [
        switch (loginMethod) {
          LoginPageMethod.NFC => LoginNFC(
              setUserCredentials: setUserCredentials,
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
                            () => loginMethod = otherLoginMethods[index]),
                      ))),
              FloatingActionButton.extended(
                  label: const Text("Guest Login"),
                  icon: const Icon(Icons.person),
                  onPressed: () => setUserCredentials(
                        Config.guestCredentials.id,
                        Config.guestCredentials.password,
                      )),
            ],
          ),
        )
      ],
    );
  }
}
