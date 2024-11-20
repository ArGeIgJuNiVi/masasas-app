import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:masasas_app/masasas_api/api_json.dart';
import 'package:masasas_app/masasas_api/api.dart';
import 'package:masasas_app/nfc.dart';
import 'package:nfc_manager/nfc_manager.dart';

class Admin extends StatefulWidget {
  const Admin({
    super.key,
    required this.invalidateUserCredentials,
    required this.nfcAvailable,
    required this.showError,
    required this.adminID,
    required this.adminDailyAccessCode,
    required this.showConfirmation,
  });

  final Function([String]) invalidateUserCredentials;
  final Function(String, double) showError;
  final Function(String, double) showConfirmation;
  final bool nfcAvailable;

  final String adminID;
  final String adminDailyAccessCode;

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  final _createUserID = TextEditingController();
  final _createUsername = TextEditingController();
  final _createUserPassword = TextEditingController();
  final _createUserPasswordRepeat = TextEditingController();
  final _createUserAlias = TextEditingController();
  bool _createUserAdministrator = false;
  bool _createUserAllowedPersonalization = true;
  bool _createUserAllowedSelfDeletion = true;

  final _createTableID = TextEditingController();
  final _createTableMacAddress = TextEditingController();
  var _createTableConnectionMode = "bluetooth";
  final _createTableManufacturer = TextEditingController();
  final _createTableMinHeight = TextEditingController();
  final _createTableMaxHeight = TextEditingController();
  final _createTableName = TextEditingController();
  final _createTableCurrentHeight = TextEditingController();
  final _createTableIcon = TextEditingController(text: "table");

  final _deleteUserID = TextEditingController();

  final _deleteTableID = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordRepeat = true;

  final _externalApiKey = TextEditingController();
  final _externalApiUrl = TextEditingController();
  var _externalApiType = "dummy";
  final _externalApiRequestFrequencySeconds = TextEditingController();

  @override
  void initState() {
    if (widget.nfcAvailable) {
      NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        var user = getUserFromNfcCard(tag);
        if (kDebugMode) print(user);

        _createUserID.text = user.id;
        _deleteUserID.text = user.id;
        _createUserPassword.text = user.password;
        _createUserPasswordRepeat.text = user.password;
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    if (widget.nfcAvailable) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  void createUser() async {
    if (_createUserPassword.text != _createUserPasswordRepeat.text) {
      widget.showError("Passwords do not match", 16);
      return;
    }

    String userJson = await newUserJson(
      _createUserPassword.text,
      _createUsername.text,
      _createUserAlias.text,
      _createUserAdministrator,
      _createUserAllowedPersonalization,
      _createUserAllowedSelfDeletion,
    );

    MasasasResponse createdUserJson = await MasasasApi.adminCreateUser(
        widget.adminID,
        widget.adminDailyAccessCode,
        _createUserID.text,
        userJson);

    switch (createdUserJson.result) {
      case MasasasResult.ok:
        widget.showConfirmation("Created user successfully", 16);
        if (kDebugMode) print(createdUserJson.body);
        return;
      default:
        if (createdUserJson.body == "Invalid admin id or daily access code") {
          widget.invalidateUserCredentials(createdUserJson.body);
        } else {
          widget.showError(createdUserJson.body, 16);
        }
        return;
    }
  }

  void createTable() async {
    String tableJson;
    try {
      tableJson = newTableJson(
        _createTableMacAddress.text,
        _createTableConnectionMode,
        _createTableManufacturer.text,
        num.parse(_createTableMinHeight.text),
        num.parse(_createTableMaxHeight.text),
        _createTableName.text,
        num.parse(_createTableCurrentHeight.text),
        _createTableIcon.text,
      );
    } catch (e) {
      if (kDebugMode) print(e);
      widget.showError("Table data not valid", 16);
      return;
    }

    MasasasResponse createdTableJson = await MasasasApi.adminCreateTable(
        widget.adminID,
        widget.adminDailyAccessCode,
        _createTableID.text,
        tableJson);

    switch (createdTableJson.result) {
      case MasasasResult.ok:
        widget.showConfirmation("Created table successfully", 16);
        if (kDebugMode) print(createdTableJson.body);
        return;
      default:
        if (createdTableJson.body == "Invalid admin id or daily access code") {
          widget.invalidateUserCredentials(createdTableJson.body);
        } else {
          widget.showError(createdTableJson.body, 16);
        }
        return;
    }
  }

  void deleteUser() async {
    MasasasResponse deletedUserJson = await MasasasApi.adminDeleteUser(
        widget.adminID, widget.adminDailyAccessCode, _deleteUserID.text);

    switch (deletedUserJson.result) {
      case MasasasResult.ok:
        widget.showConfirmation("Deleted user successfully", 16);
        if (kDebugMode) print(deletedUserJson.body);
        return;
      default:
        if (deletedUserJson.body == "Invalid admin id or daily access code") {
          widget.invalidateUserCredentials(deletedUserJson.body);
        } else {
          widget.showError(deletedUserJson.body, 16);
        }
        return;
    }
  }

  void deleteTable() async {
    MasasasResponse deletedTableJson = await MasasasApi.adminDeleteTable(
        widget.adminID, widget.adminDailyAccessCode, _deleteTableID.text);

    switch (deletedTableJson.result) {
      case MasasasResult.ok:
        widget.showConfirmation("Deleted table successfully", 16);
        if (kDebugMode) print(deletedTableJson.body);
        return;
      default:
        if (deletedTableJson.body == "Invalid admin id or daily access code") {
          widget.invalidateUserCredentials(deletedTableJson.body);
        } else {
          widget.showError(deletedTableJson.body, 16);
        }
        return;
    }
  }

  void updateExternalApiConfig() async {
    MasasasResponse setApiKey = _externalApiKey.text.isNotEmpty
        ? await MasasasApi.adminSetExternalApiKey(
            widget.adminID, widget.adminDailyAccessCode, _externalApiKey.text)
        : MasasasResponse("", MasasasResult.ok);
    MasasasResponse setApiUrl = _externalApiUrl.text.isNotEmpty
        ? await MasasasApi.adminSetExternalApiUrl(widget.adminID,
            widget.adminDailyAccessCode, Uri.parse(_externalApiUrl.text))
        : MasasasResponse("", MasasasResult.ok);
    MasasasResponse setApiType = await MasasasApi.adminSetExternalApiType(
        widget.adminID, widget.adminDailyAccessCode, _externalApiType);
    MasasasResponse setApiRequestFrequencySeconds =
        _externalApiRequestFrequencySeconds.text.isNotEmpty
            ? await MasasasApi.adminSetExternalApiRequestFrequencySeconds(
                widget.adminID,
                widget.adminDailyAccessCode,
                num.parse(_externalApiRequestFrequencySeconds.text))
            : MasasasResponse("", MasasasResult.ok);

    switch ((
      setApiKey.result,
      setApiUrl.result,
      setApiType.result,
      setApiRequestFrequencySeconds.result
    )) {
      case (
          MasasasResult.ok,
          MasasasResult.ok,
          MasasasResult.ok,
          MasasasResult.ok
        ):
        widget.showConfirmation(
            "Successfully updated external api settings", 16);
        return;
      case (MasasasResult.badRequest || MasasasResult.connectionError, _, _, _):
        if (setApiKey.body == "Invalid admin id or daily access code") {
          widget.invalidateUserCredentials(setApiKey.body);
        } else {
          widget.showError(setApiKey.body, 16);
        }
        return;
      case (_, MasasasResult.badRequest || MasasasResult.connectionError, _, _):
        if (setApiUrl.body == "Invalid admin id or daily access code") {
          widget.invalidateUserCredentials(setApiUrl.body);
        } else {
          widget.showError(setApiUrl.body, 16);
        }
        return;
      case (_, _, MasasasResult.badRequest || MasasasResult.connectionError, _):
        if (setApiType.body == "Invalid admin id or daily access code") {
          widget.invalidateUserCredentials(setApiType.body);
        } else {
          widget.showError(setApiType.body, 16);
        }
        return;
      case (_, _, _, MasasasResult.badRequest || MasasasResult.connectionError):
        if (setApiRequestFrequencySeconds.body ==
            "Invalid admin id or daily access code") {
          widget.invalidateUserCredentials(setApiRequestFrequencySeconds.body);
        } else {
          widget.showError(setApiRequestFrequencySeconds.body, 16);
        }
        return;
    }
  }

  void importExternalApiTables() async {
    MasasasResponse deletedTableJson =
        await MasasasApi.adminImportExternalApiTables(
            widget.adminID, widget.adminDailyAccessCode);

    switch (deletedTableJson.result) {
      case MasasasResult.ok:
        widget.showConfirmation("Imported tables successfully", 16);
        if (kDebugMode) print(deletedTableJson.body);
        return;
      default:
        if (deletedTableJson.body == "Invalid admin id or daily access code") {
          widget.invalidateUserCredentials(deletedTableJson.body);
        } else {
          widget.showError(deletedTableJson.body, 16);
        }
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    double columnWidth = MediaQuery.of(context).size.width - 96;
    if (MediaQuery.of(context).orientation == Orientation.landscape) {
      columnWidth /= 2;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Wrap(
            runSpacing: 32,
            alignment: WrapAlignment.spaceAround,
            children: [
              const Center(
                child: Text(
                  "Admin menu",
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
                        const Text("Create user"),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'User id',
                            border: OutlineInputBorder(),
                          ),
                          controller: _createUserID,
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
                          controller: _createUserPassword,
                        ),
                        TextField(
                          obscureText: _obscurePasswordRepeat,
                          decoration: InputDecoration(
                            labelText: 'Repeat password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: "Toggle visibility",
                              icon: Icon(
                                _obscurePasswordRepeat
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePasswordRepeat =
                                      !_obscurePasswordRepeat;
                                });
                              },
                            ),
                          ),
                          controller: _createUserPasswordRepeat,
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Alias',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                          controller: _createUserAlias,
                        ),
                        Visibility(
                          visible: _createUserAlias.text.isEmpty,
                          child: Column(
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _createUsername,
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _createUserAdministrator,
                                    onChanged: (val) => setState(() =>
                                        _createUserAdministrator =
                                            val ?? _createUserAdministrator),
                                  ),
                                  const Text("Administrator"),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _createUserAllowedPersonalization,
                                    onChanged: (val) => setState(() =>
                                        _createUserAllowedPersonalization = val ??
                                            _createUserAllowedPersonalization),
                                  ),
                                  const Text("Allowed personalization"),
                                ],
                              ),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _createUserAllowedSelfDeletion,
                                    onChanged: (val) => setState(() =>
                                        _createUserAllowedSelfDeletion = val ??
                                            _createUserAllowedSelfDeletion),
                                  ),
                                  const Text("Allowed self deletion"),
                                ],
                              )
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: createUser,
                          icon: const Icon(Icons.person),
                          label: const Text("Create user"),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Wrap(
                      runSpacing: 12,
                      children: [
                        const Text("Delete user"),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'User id',
                            border: OutlineInputBorder(),
                          ),
                          controller: _deleteUserID,
                        ),
                        OutlinedButton.icon(
                          onPressed: deleteUser,
                          icon: const Icon(Icons.person),
                          label: const Text("Delete user"),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Wrap(
                      runSpacing: 12,
                      children: [
                        const Text("Set external api settings"),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Key',
                            border: OutlineInputBorder(),
                          ),
                          controller: _externalApiKey,
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Url',
                            border: OutlineInputBorder(),
                          ),
                          controller: _externalApiUrl,
                        ),
                        Row(
                          children: [
                            const Text("Api type:"),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: DropdownButton(
                                value: _externalApiType,
                                items: const [
                                  DropdownMenuItem(
                                      value: "dummy", child: Text("dummy")),
                                  DropdownMenuItem(
                                      value: "Kr64", child: Text("Kr64")),
                                ],
                                onChanged: (String? val) => setState(
                                  () => _externalApiType =
                                      val ?? _externalApiType,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _externalApiRequestFrequencySeconds,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'))
                          ],
                          decoration: const InputDecoration(
                            labelText: "Request frequency (seconds)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: updateExternalApiConfig,
                              icon: const Icon(Icons.api),
                              label: const Text("Set external api settings"),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: importExternalApiTables,
                          icon: const Icon(Icons.table_restaurant),
                          label: const Text("Import api tables"),
                        )
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
                        const Text("Create table"),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Table id',
                            border: OutlineInputBorder(),
                          ),
                          controller: _createTableID,
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Mac address',
                            border: OutlineInputBorder(),
                          ),
                          controller: _createTableMacAddress,
                        ),
                        Row(
                          children: [
                            const Text("Connection mode:"),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: DropdownButton(
                                value: _createTableConnectionMode,
                                items: const [
                                  DropdownMenuItem(
                                      value: "bluetooth",
                                      child: Text("bluetooth")),
                                  DropdownMenuItem(
                                      value: "api", child: Text("api")),
                                ],
                                onChanged: (String? val) => setState(
                                  () => _createTableConnectionMode =
                                      val ?? _createTableConnectionMode,
                                ),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Manufacturer',
                            border: OutlineInputBorder(),
                          ),
                          controller: _createTableManufacturer,
                        ),
                        TextField(
                          onChanged: (value) => setState(
                              () => _createTableCurrentHeight.text = value),
                          controller: _createTableMinHeight,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'))
                          ],
                          decoration: const InputDecoration(
                            labelText: "Minimum table height",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextField(
                          controller: _createTableMaxHeight,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'))
                          ],
                          decoration: const InputDecoration(
                            labelText: "Maximum table height",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                          controller: _createTableName,
                        ),
                        TextField(
                          controller: _createTableCurrentHeight,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'))
                          ],
                          decoration: const InputDecoration(
                            labelText: "Current table height",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Icon name',
                            border: OutlineInputBorder(),
                          ),
                          controller: _createTableIcon,
                        ),
                        OutlinedButton.icon(
                          onPressed: createTable,
                          icon: const Icon(Icons.person),
                          label: const Text("Create table"),
                        )
                      ],
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    Wrap(
                      runSpacing: 12,
                      children: [
                        const Text("Delete table"),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Table id',
                            border: OutlineInputBorder(),
                          ),
                          controller: _deleteTableID,
                        ),
                        OutlinedButton.icon(
                          onPressed: deleteTable,
                          icon: const Icon(Icons.person),
                          label: const Text("Delete table"),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
