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
  final _createTableManufacturer = TextEditingController();
  final _createTableMinHeight = TextEditingController();
  final _createTableMaxHeight = TextEditingController();
  final _createTableName = TextEditingController();
  final _createTableCurrentHeight = TextEditingController();
  final _createTableIcon = TextEditingController(text: "table");
  var _createTableConnectionMode = "bluetooth";
  final _createTableApiKey = TextEditingController();
  final _createTableApiUrl = TextEditingController();
  var _createTableApiType = "dummy";
  final _createTableBluetoothName = TextEditingController();

  final _deleteUserID = TextEditingController();

  final _deleteTableID = TextEditingController();

  bool _obscurePassword = true;
  bool _obscurePasswordRepeat = true;

  final _importApiKey = TextEditingController();
  final _importApiUrl = TextEditingController();
  var _importApiType = "dummy";

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
        _createTableConnectionMode == "api"
            ? (
                type: _createTableApiType,
                url: _createTableApiUrl.text,
                key: _createTableApiKey.text,
              )
            : null,
        _createTableConnectionMode == "bluetooth"
            ? (name: _createTableBluetoothName.text,)
            : null,
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
    MasasasResponse setApiRequestFrequencySeconds =
        _externalApiRequestFrequencySeconds.text.isNotEmpty
            ? await MasasasApi.adminSetExternalApiRequestFrequencySeconds(
                widget.adminID,
                widget.adminDailyAccessCode,
                num.parse(_externalApiRequestFrequencySeconds.text))
            : MasasasResponse("", MasasasResult.ok);

    switch ((setApiRequestFrequencySeconds.result)) {
      case (MasasasResult.ok):
        widget.showConfirmation(
            "Successfully updated external api settings", 16);
        return;
      default:
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
    MasasasResponse importedTableJson =
        await MasasasApi.adminImportTablesExternalApi(
      widget.adminID,
      widget.adminDailyAccessCode,
      tableApiDataJson(_importApiType, _importApiUrl.text, _importApiKey.text),
    );

    switch (importedTableJson.result) {
      case MasasasResult.ok:
        widget.showConfirmation("Imported tables successfully", 16);
        if (kDebugMode) print(importedTableJson.body);
        return;
      default:
        if (importedTableJson.body == "Invalid admin id or daily access code") {
          widget.invalidateUserCredentials(importedTableJson.body);
        } else {
          widget.showError(importedTableJson.body, 16);
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
                    FocusTraversalGroup(
                      child: Wrap(
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
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    FocusTraversalGroup(
                      child: Wrap(
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    FocusTraversalGroup(
                      child: Wrap(
                        runSpacing: 12,
                        children: [
                          const Text("Import Tables from external api"),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Url',
                              border: OutlineInputBorder(),
                            ),
                            controller: _importApiUrl,
                          ),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: 'Key',
                              border: OutlineInputBorder(),
                            ),
                            controller: _importApiKey,
                          ),
                          Row(
                            children: [
                              const Text("Api type:"),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: DropdownButton(
                                  value: _importApiType,
                                  items: const [
                                    DropdownMenuItem(
                                        value: "dummy", child: Text("dummy")),
                                    DropdownMenuItem(
                                        value: "Kr64", child: Text("Kr64")),
                                  ],
                                  onChanged: (String? val) => setState(
                                    () =>
                                        _importApiType = val ?? _importApiType,
                                  ),
                                ),
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
                    )
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
                        Visibility(
                          visible: _createTableConnectionMode == "api",
                          child: Wrap(
                            runSpacing: 12,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Api Url',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _createTableApiUrl,
                              ),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Api Key',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _createTableApiKey,
                              ),
                              Row(
                                children: [
                                  const Text("Api type:"),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: DropdownButton(
                                      value: _createTableApiType,
                                      items: const [
                                        DropdownMenuItem(
                                            value: "dummy",
                                            child: Text("dummy")),
                                        DropdownMenuItem(
                                            value: "Kr64", child: Text("Kr64")),
                                      ],
                                      onChanged: (String? val) => setState(
                                        () => _createTableApiType =
                                            val ?? _createTableApiType,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Visibility(
                          visible: _createTableConnectionMode == "bluetooth",
                          child: Wrap(
                            runSpacing: 12,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                ),
                                controller: _createTableBluetoothName,
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: createTable,
                          icon: const Icon(Icons.person),
                          label: const Text("Create table"),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    FocusTraversalGroup(
                      child: Wrap(
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
                    ),
                    const SizedBox(
                      height: 32,
                    ),
                    FocusTraversalGroup(
                      child: Wrap(
                        runSpacing: 12,
                        children: [
                          const Text("Set external api settings"),
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
                          OutlinedButton.icon(
                            onPressed: updateExternalApiConfig,
                            icon: const Icon(Icons.api),
                            label: const Text("Update"),
                          ),
                        ],
                      ),
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
