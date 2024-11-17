import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:masasas_app/admin.dart';
import 'package:masasas_app/masasas_api/api.dart';
import 'package:masasas_app/data/table_icons.dart';
import 'package:masasas_app/table_manager.dart';

class Homepage extends StatefulWidget {
  const Homepage(
      {super.key,
      required this.userID,
      required this.userDailyAccessCode,
      required this.invalidateUserCredentials,
      required this.showError,
      required this.nfcAvailable,
      required this.showConfirmation});
  final String userID;
  final String userDailyAccessCode;
  final Function([String]) invalidateUserCredentials;
  final Function(String, double) showError;
  final Function(String, double) showConfirmation;

  final bool nfcAvailable;

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _retryCounter = 0;
  Timer? _updateData;
  List? _tables;
  String? _selectedTableID;
  String? _selectedTableDailyAccessCode;
  Map? _userPreferences;
  bool _admin = false;
  bool _selfDelete = false;
  bool _adminMenuOpen = false;

  void updateData([Timer? state]) async {
    MasasasResponse tablesJson =
        await MasasasApi.getTables(widget.userID, widget.userDailyAccessCode);
    MasasasResponse userPreferencesJson = await MasasasApi.getUserPreferences(
        widget.userID, widget.userDailyAccessCode);
    MasasasResponse adminString =
        await MasasasApi.adminGet(widget.userID, widget.userDailyAccessCode);
    MasasasResponse deleteString = await MasasasApi.getUserSelfDeletionState(
        widget.userID, widget.userDailyAccessCode);

    switch ((
      tablesJson.result,
      userPreferencesJson.result,
      adminString.result,
      deleteString.result,
    )) {
      case (MasasasResult.connectionError, _, _, _):
        _retryCounter++;
        if (_retryCounter >= 3) {
          widget.invalidateUserCredentials(tablesJson.body);
        }
        return;
      case (_, MasasasResult.connectionError, _, _):
        _retryCounter++;
        if (_retryCounter >= 3) {
          widget.invalidateUserCredentials(userPreferencesJson.body);
        }
        return;
      case (_, _, MasasasResult.connectionError, _):
        _retryCounter++;
        if (_retryCounter >= 3) {
          widget.invalidateUserCredentials(adminString.body);
        }
        return;
      case (_, _, _, MasasasResult.connectionError):
        _retryCounter++;
        if (_retryCounter >= 3) {
          widget.invalidateUserCredentials(deleteString.body);
        }
        return;

      case (MasasasResult.badRequest, _, _, _):
        widget.invalidateUserCredentials(tablesJson.body);
        return;

      case (_, MasasasResult.badRequest, _, _):
        widget.invalidateUserCredentials(userPreferencesJson.body);
        return;
      case (_, _, MasasasResult.badRequest, _):
        widget.invalidateUserCredentials(adminString.body);
        return;

      case (_, _, _, MasasasResult.badRequest):
        widget.invalidateUserCredentials(deleteString.body);
        return;

      default:
        _retryCounter = 0;
        _tables = jsonDecode(tablesJson.body);
        _userPreferences = jsonDecode(userPreferencesJson.body);
        _admin = bool.parse(adminString.body, caseSensitive: false);
        _selfDelete = bool.parse(deleteString.body, caseSensitive: false) &&
            !_admin; //no self deletion for admins
        return setState(() {});
    }
  }

  void deselectTable([String? error]) {
    _selectedTableID = null;
    _selectedTableDailyAccessCode = null;

    updateData();
    _updateData = Timer.periodic(const Duration(seconds: 5), updateData);

    setState(() {});

    if (error != null) {
      widget.showError(error, 16);
    }
  }

  void deleteUser() async {
    MasasasResponse deletionString = await MasasasApi.deleteUserSelf(
        widget.userID, widget.userDailyAccessCode);

    switch (deletionString.result) {
      case MasasasResult.ok:
        if (kDebugMode) print(deletionString.body);
        widget.showConfirmation("User deleted successfully", 88);
        widget.invalidateUserCredentials();
        return;
      default:
        widget.showError(deletionString.body, 16);
    }
  }

  void closeAdminMenu() => setState(() => _adminMenuOpen = false);

  @override
  void initState() {
    updateData();
    _updateData = Timer.periodic(const Duration(seconds: 5), updateData);
    super.initState();
  }

  @override
  void dispose() {
    _updateData?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tables == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedTableID != null && _selectedTableDailyAccessCode != null) {
      return TableManager(
        invalidateUserCredentials: widget.invalidateUserCredentials,
        deselectTable: deselectTable,
        selectedTableID: _selectedTableID!,
        selectedTableDailyAccessCode: _selectedTableDailyAccessCode!,
        userID: widget.userID,
        userDailyAccessCode: widget.userDailyAccessCode,
      );
    } else {
      return Stack(
        children: [
          Column(
            children: [
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Hello ${_userPreferences!["Name"]} ",
                        style: const TextStyle(fontSize: 32),
                      ),
                      const Icon(
                        Icons.waving_hand_rounded,
                        color: Colors.amberAccent,
                      ),
                    ],
                  ),
                  const Text(
                    "Please select a table",
                  ),
                ],
              ),
              const Text(
                "···",
                style: TextStyle(fontSize: 32),
              ),
              Expanded(
                child: Material(
                  child: ListView.builder(
                    itemCount: _tables!.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: deskIcon[_tables![index]["Data"]["Icon"]],
                      title: Text(_tables![index]["Data"]["Location"]),
                      subtitle: Text(_tables![index]["ID"]),
                      onTap: () => setState(
                        () {
                          _updateData!.cancel();
                          _selectedTableID = _tables![index]["ID"];
                          _selectedTableDailyAccessCode =
                              _tables![index]["DailyAccessCode"];
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: Visibility(
              visible: _adminMenuOpen,
              child: Admin(
                invalidateUserCredentials: widget.invalidateUserCredentials,
                showError: widget.showError,
                showConfirmation: widget.showConfirmation,
                nfcAvailable: widget.nfcAvailable,
                adminID: widget.userID,
                adminDailyAccessCode: widget.userDailyAccessCode,
              ),
            ),
          ),
          BackButton(
            onPressed: () => widget.invalidateUserCredentials(),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Visibility(
              visible: _admin,
              child: IconButton(
                  tooltip: "Admin",
                  icon: const Icon(Icons.admin_panel_settings),
                  color: _adminMenuOpen ? Colors.red : null,
                  onPressed: () =>
                      setState(() => _adminMenuOpen = !_adminMenuOpen)),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Visibility(
              visible: _selfDelete,
              child: IconButton(
                tooltip: "Delete account",
                icon: const Icon(Icons.delete),
                color: Colors.red,
                onPressed: () => showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => Dialog(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Delete account?",
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text("No")),
                              TextButton(
                                  onPressed: () {
                                    deleteUser();
                                    Navigator.pop(context);
                                  },
                                  child: const Text("Yes"))
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
