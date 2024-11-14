import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:masasas_app/api.dart';
import 'package:masasas_app/data/error_messages.dart';
import 'package:masasas_app/models.dart';
import 'package:masasas_app/table_manager.dart';

class TableList extends StatefulWidget {
  const TableList(
      {super.key,
      required this.userID,
      required this.userDailyAccessCode,
      required this.invalidateUserCredentials,
      required this.showError});
  final String userID;
  final String userDailyAccessCode;
  final Function([String]) invalidateUserCredentials;
  final Function(String, double) showError;

  @override
  State<TableList> createState() => _TableListState();
}

class _TableListState extends State<TableList> {
  int _retryCounter = 0;
  Timer? _updateData;
  List<TableValue>? _tables;
  String? _selectedTableID;
  String? _selectedTableDailyAccessCode;
  UserPreferences? _userPreferences;

  void updateData([Timer? state]) async {
    MasasasResponse tablesJson =
        await MasasasApi.getTables(widget.userID, widget.userDailyAccessCode);
    MasasasResponse userPreferencesJson = await MasasasApi.getUserPreferences(
        widget.userID, widget.userDailyAccessCode);

    switch ((tablesJson.result, userPreferencesJson.result)) {
      case (MasasasResult.connectionError, _):
      case (_, MasasasResult.connectionError):
        _retryCounter++;
        if (_retryCounter >= 3) {
          widget
              .invalidateUserCredentials(ErrorMessages.genericConnectionError);
          // ignore: use_build_context_synchronously
        }
        return;

      case (MasasasResult.badRequest, _):
        widget.invalidateUserCredentials(tablesJson.body);
        return;

      case (_, MasasasResult.badRequest):
        widget.invalidateUserCredentials(userPreferencesJson.body);
        return;

      case (MasasasResult.ok, MasasasResult.ok):
        _retryCounter = 0;
        List tableJsonList = jsonDecode(tablesJson.body);
        _tables = tableJsonList.map((e) => TableValue.fromJson(e)).toList();
        _userPreferences =
            UserPreferences.fromJson(jsonDecode(userPreferencesJson.body));
        return setState(() {});
    }
  }

  void deselectTable([String? error]) {
    _selectedTableID = null;
    _selectedTableDailyAccessCode = null;

    setState(() {});

    if (error != null) {
      widget.showError(error, 16);
    }
  }

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

    if (_selectedTableID == null && _selectedTableDailyAccessCode == null) {
      return Stack(
        children: [
          BackButton(
            onPressed: () => widget.invalidateUserCredentials(),
          ),
          Column(
            children: [
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Hello ${_userPreferences?.name} ",
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
                      leading: deskIcon(_tables![index].data.icon),
                      title: Text(_tables![index].data.location),
                      subtitle: Text(_tables![index].id),
                      onTap: () => setState(
                        () {
                          _selectedTableID = _tables![index].id;
                          _selectedTableDailyAccessCode =
                              _tables![index].dailyAccessCode;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
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
    }

    widget.invalidateUserCredentials();
    return const Center(child: Text("There was an error, logging out"));
  }
}
