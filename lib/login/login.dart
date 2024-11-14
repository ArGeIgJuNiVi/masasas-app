import 'package:flutter/material.dart';
import 'package:masasas_app/config.dart';
import 'package:masasas_app/login/login_nfc.dart';
import 'package:masasas_app/login/login_user.dart';
import 'package:masasas_app/models.dart';
import 'package:masasas_app/table_list.dart';
import 'package:masasas_app/utils.dart';
import 'package:nfc_manager/nfc_manager.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  String? _userID;
  String? _userDailyAccessCode;
  String? _error;
  LoginPageMethod loginMethod = LoginPageMethod.nfc;

  void setUserCredentials(String userID, String encryptedPassword) async {
    _userID = userID;
    _userDailyAccessCode = dailyAccessCode(encryptedPassword);

    try {
      var response = (await httpClient.get(apiURI([
        "user",
        userID,
        dailyAccessCode(encryptedPassword),
        "get_preferences",
      ])));
      if (response.statusCode == 200) {
        setState(() {});
      } else {
        invalidateUserCredentials("Invalid user credentials");
      }
    } catch (e) {
      invalidateUserCredentials("Server error detected");
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
  }

  void invalidateUserCredentials([String? error]) {
    _userID = null;
    _userDailyAccessCode = null;
    _error = error;

    setState(() {});

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_error!),
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userID != null && _userDailyAccessCode != null) {
      return TableList(
        userID: _userID!,
        userDailyAccessCode: _userDailyAccessCode!,
        invalidateUserCredentials: invalidateUserCredentials,
      );
    }

    List<LoginPageMethod> otherLoginMethods = LoginPageMethod.values.toList();

    if (!_nfcAvailable) {
      if (loginMethod == LoginPageMethod.nfc) {
        loginMethod = LoginPageMethod.user;
      }
      otherLoginMethods.remove(LoginPageMethod.nfc);
    }

    otherLoginMethods.remove(loginMethod);

    return Stack(
      children: [
        switch (loginMethod) {
          LoginPageMethod.nfc => LoginNFC(
              setUserCredentials: setUserCredentials,
            ),
          LoginPageMethod.user => LoginPassword(
              setUserCredentials: setUserCredentials,
            ),
        },
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
                        Config.guestCredentials.encryptedPassword,
                      )),
            ],
          ),
        )
      ],
    );
  }
}
