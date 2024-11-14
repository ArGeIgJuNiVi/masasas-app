import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:masasas_app/models.dart';
import 'package:masasas_app/table_manager.dart';
import 'package:masasas_app/utils.dart';

class TableList extends StatefulWidget {
  const TableList(
      {super.key,
      required this.userID,
      required this.userDailyAccessCode,
      required this.invalidateUserCredentials});
  final String userID;
  final String userDailyAccessCode;
  final Function invalidateUserCredentials;

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
    // check credentials + get table list
    late Response tablesJson;
    late Response userPreferencesJson;
    try {
      tablesJson = await httpClient.get(apiURI([
        "user",
        widget.userID,
        widget.userDailyAccessCode,
        "get_tables",
      ]));
      userPreferencesJson = await httpClient.get(apiURI([
        "user",
        widget.userID,
        widget.userDailyAccessCode,
        "get_preferences",
      ]));
    } catch (_) {
      _retryCounter++;
      if (_retryCounter >= 3) {
        widget.invalidateUserCredentials(
            "Server error detected, please log back in or try again later");
      }
      return;
    }

    if (tablesJson.statusCode != 200 || userPreferencesJson.statusCode != 200) {
      widget.invalidateUserCredentials("User credentials have expired");
      return;
    }

    List tableJsonList = jsonDecode(tablesJson.body);
    _tables = tableJsonList.map((e) => TableValue.fromJson(e)).toList();
    _userPreferences =
        UserPreferences.fromJson(jsonDecode(userPreferencesJson.body));

    setState(() {});
  }

  void deselectTable() {
    _selectedTableID = null;
    _selectedTableDailyAccessCode = null;
    setState(() {});
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
