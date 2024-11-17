import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:masasas_app/masasas_api/api.dart';
import 'package:masasas_app/height.dart';
import 'package:masasas_app/settings.dart';
import 'package:masasas_app/user_stats.dart';

class TableManager extends StatefulWidget {
  const TableManager({
    super.key,
    required this.deselectTable,
    required this.selectedTableID,
    required this.selectedTableDailyAccessCode,
    required this.userID,
    required this.userDailyAccessCode,
    required this.invalidateUserCredentials,
  });

  final Function([String]) deselectTable;
  final Function([String]) invalidateUserCredentials;
  final String selectedTableID;
  final String selectedTableDailyAccessCode;
  final String userID;
  final String userDailyAccessCode;

  @override
  State<TableManager> createState() => _TableManagerState();
}

class _TableManagerState extends State<TableManager> {
  bool _personalizationEnabled = false;
  Timer? _updateData;
  Map? _selectedTableData;
  Map? _userPreferences;
  int _retryCounter = 0;
  String _tableUnit = Settings.app.defaultUnit;
  final SessionStats _stats = SessionStats();
  bool _statsOpen = false;

  double percentHeight() =>
      (_selectedTableData!["Data"]["CurrentHeight"] -
          _selectedTableData!["Data"]["MinHeight"]) /
      (_selectedTableData!["Data"]["MaxHeight"] -
          _selectedTableData!["Data"]["MinHeight"]);

  void checkPersonalization() async {
    MasasasResponse personalizationJson =
        await MasasasApi.getUserPersonalizationState(
            widget.userID, widget.userDailyAccessCode);

    switch (personalizationJson.result) {
      case MasasasResult.ok:
        _personalizationEnabled =
            bool.parse(personalizationJson.body, caseSensitive: false);
        setState(() {});
        return;
      case MasasasResult.badRequest:
        widget.invalidateUserCredentials(personalizationJson.body);
        return;
      case MasasasResult.connectionError:
        widget.deselectTable(personalizationJson.body);
        return;
    }
  }

  void updateData([Timer? state]) async {
    MasasasResponse tableJson = await MasasasApi.getTableData(
        widget.selectedTableID, widget.selectedTableDailyAccessCode);
    MasasasResponse userPreferencesJson = await MasasasApi.getUserPreferences(
        widget.userID, widget.userDailyAccessCode);

    switch ((tableJson.result, userPreferencesJson.result)) {
      case (MasasasResult.connectionError, _):
        _retryCounter++;
        if (_retryCounter >= 5) {
          widget.invalidateUserCredentials(tableJson.body);
        }
        return;

      case (_, MasasasResult.connectionError):
        _retryCounter++;
        if (_retryCounter >= 5) {
          widget.invalidateUserCredentials(userPreferencesJson.body);
        }
        return;

      case (MasasasResult.badRequest, _):
        widget.invalidateUserCredentials(tableJson.body);
        return;

      case (_, MasasasResult.badRequest):
        widget.invalidateUserCredentials(userPreferencesJson.body);
        return;

      case (MasasasResult.ok, MasasasResult.ok):
        _retryCounter = 0;
        _selectedTableData = jsonDecode(tableJson.body);
        _userPreferences = jsonDecode(userPreferencesJson.body);
        _stats.addDataPoint(
          _selectedTableData!["Data"]["CurrentHeight"],
          _selectedTableData!["Data"]["MinHeight"],
          _selectedTableData!["Data"]["MaxHeight"],
        );
        return setState(() {});
    }
  }

  @override
  void initState() {
    checkPersonalization();
    updateData();
    _updateData = Timer.periodic(const Duration(seconds: 1), updateData);
    super.initState();
  }

  @override
  void dispose() {
    _updateData?.cancel();
    super.dispose();
  }

  void setTableHeight(num val) async {
    MasasasResponse tableHeightString = await MasasasApi.setTableHeight(
        widget.selectedTableID, widget.selectedTableDailyAccessCode, val);
    switch (tableHeightString.result) {
      case MasasasResult.ok:
        _selectedTableData!["Data"]["CurrentHeight"] =
            num.parse(tableHeightString.body);
        return setState(() {});

      case MasasasResult.badRequest:
        widget.deselectTable(tableHeightString.body);
        return;

      case MasasasResult.connectionError:
        widget.invalidateUserCredentials(tableHeightString.body);
        return;
    }
  }

  void addPreset(HeightValue val) {
    savePresets(
        List.from(_userPreferences!["HeightPresets"])..add(val.toJson()));
  }

  void savePresets(List presets) async {
    Map preferences = Map.from(_userPreferences!);
    preferences["HeightPresets"] = presets;
    MasasasResponse preferencesJson = await MasasasApi.setPreferences(
        widget.userID, widget.userDailyAccessCode, jsonEncode(preferences));

    switch (preferencesJson.result) {
      case MasasasResult.ok:
        _userPreferences = jsonDecode(preferencesJson.body);
        return setState(() {});

      case MasasasResult.badRequest:
        if (preferencesJson.body == "User personalization is disabled") {
          _personalizationEnabled = false;
          setState(() {});
          return;
        } else {
          widget.deselectTable(preferencesJson.body);
          return;
        }
      case MasasasResult.connectionError:
        widget.invalidateUserCredentials(preferencesJson.body);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    double px = MediaQuery.of(context).size.shortestSide / 1000;

    if (_selectedTableData == null || _userPreferences == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        Flex(
          direction: MediaQuery.of(context).size.aspectRatio > 3 / 4
              ? Axis.horizontal
              : Axis.vertical,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Center(
                  child: Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                      text: "${_selectedTableData!["Data"]["Location"]}\n",
                      style: const TextStyle(
                          fontSize: 20, fontStyle: FontStyle.italic),
                      children: [
                        TextSpan(
                          text: "${widget.selectedTableID}\n",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Flex(
                    direction: MediaQuery.of(context).orientation ==
                            Orientation.portrait
                        ? Axis.vertical
                        : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: "Raise table ${HeightValue(_tableUnit, 0.1)}",
                        onPressed: () => setTableHeight(
                          _selectedTableData!["Data"]["CurrentHeight"] + 0.1,
                        ),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      SizedBox(
                        width: 600 * px,
                        height: 600 * px,
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: Durations.medium1,
                              top: 100 * px,
                              left: 0,
                              right: 0,
                              height: 600 * px,
                              child: SvgPicture.string(
                                  '<svg id="ejBqeErvJCg1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 300 300" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" project-id="f9de0a2e30ca4d27a09746df76cf495a" export-id="99ff04c12d4a4d808c33dc45f0c01416" cached="false"><defs><linearGradient id="ejBqeErvJCg12-fill" x1="119.25" y1="310.05" x2="119.25" y2="307.44" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ejBqeErvJCg12-fill-0" offset="3%" stop-color="#9f9fa1"/><stop id="ejBqeErvJCg12-fill-1" offset="100%" stop-color="#818182"/></linearGradient><linearGradient id="ejBqeErvJCg13-fill" x1="107.08" y1="324.66" x2="107.08" y2="321.67" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ejBqeErvJCg13-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ejBqeErvJCg13-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ejBqeErvJCg14-fill" x1="292.92" y1="324.66" x2="292.92" y2="321.67" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ejBqeErvJCg14-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ejBqeErvJCg14-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ejBqeErvJCg15-fill" x1="200" y1="309.68" x2="200" y2="293.58" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ejBqeErvJCg15-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ejBqeErvJCg15-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ejBqeErvJCg16-fill" x1="200" y1="309.68" x2="200" y2="293.58" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ejBqeErvJCg16-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ejBqeErvJCg16-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ejBqeErvJCg17-fill" x1="200" y1="324.67" x2="200" y2="293.62" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ejBqeErvJCg17-fill-0" offset="14%" stop-color="#e1e1e3"/><stop id="ejBqeErvJCg17-fill-1" offset="38%" stop-color="#cfcfd1"/><stop id="ejBqeErvJCg17-fill-2" offset="100%" stop-color="#bbbbbc"/></linearGradient><linearGradient id="ejBqeErvJCg18-fill" x1="177.05" y1="212.65" x2="149.35" y2="-25.39" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ejBqeErvJCg18-fill-0" offset="2%" stop-color="#efefef"/><stop id="ejBqeErvJCg18-fill-1" offset="9%" stop-color="#e4e4e6"/><stop id="ejBqeErvJCg18-fill-2" offset="90%" stop-color="#f7f7f7"/><stop id="ejBqeErvJCg18-fill-3" offset="99%" stop-color="#e4e4e6"/></linearGradient><linearGradient id="ejBqeErvJCg19-fill" x1="14.41" y1="369.529999" x2="274.13" y2="266.289999" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ejBqeErvJCg19-fill-0" offset="0%" stop-color="#585b61"/><stop id="ejBqeErvJCg19-fill-1" offset="85%" stop-color="#484b4e"/><stop id="ejBqeErvJCg19-fill-2" offset="100%" stop-color="#4c4f54"/></linearGradient></defs><rect width="32.872445" height="46" rx="0" ry="0" transform="matrix(.395468 0 0 1.328439 52.257648 150.128221)" fill="#2b2b2c"/><rect width="32.872445" height="46" rx="0" ry="0" transform="matrix(.395468 0 0 1.328439 237.257648 150)" fill="#2b2b2c"/><rect width="25" height="15.440486" rx="0" ry="0" transform="matrix(1 0 0 0.323824 46.257648 206.236415)" fill="#2b2b2c"/><rect width="25" height="15.440486" rx="0" ry="0" transform="matrix(1 0 0 0.323824 231.257648 206.108194)" fill="#2b2b2c"/></svg>'),
                            ),
                            AnimatedPositioned(
                              top: (100 - 50 * percentHeight()) * px,
                              left: 0,
                              right: 0,
                              height: 600 * px,
                              duration: Durations.medium1,
                              child: SvgPicture.string(
                                  '<svg id="ee9WZQtLjcF1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 300 300" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" project-id="f9de0a2e30ca4d27a09746df76cf495a" export-id="397b371c59ff4d508b923a81212fc7d8" cached="false"><defs><linearGradient id="ee9WZQtLjcF12-fill" x1="119.25" y1="310.05" x2="119.25" y2="307.44" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ee9WZQtLjcF12-fill-0" offset="3%" stop-color="#9f9fa1"/><stop id="ee9WZQtLjcF12-fill-1" offset="100%" stop-color="#818182"/></linearGradient><linearGradient id="ee9WZQtLjcF13-fill" x1="107.08" y1="324.66" x2="107.08" y2="321.67" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ee9WZQtLjcF13-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ee9WZQtLjcF13-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ee9WZQtLjcF14-fill" x1="292.92" y1="324.66" x2="292.92" y2="321.67" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ee9WZQtLjcF14-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ee9WZQtLjcF14-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ee9WZQtLjcF15-fill" x1="200" y1="309.68" x2="200" y2="293.58" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ee9WZQtLjcF15-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ee9WZQtLjcF15-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ee9WZQtLjcF16-fill" x1="200" y1="309.68" x2="200" y2="293.58" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ee9WZQtLjcF16-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ee9WZQtLjcF16-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ee9WZQtLjcF17-fill" x1="200" y1="324.67" x2="200" y2="293.62" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ee9WZQtLjcF17-fill-0" offset="14%" stop-color="#e1e1e3"/><stop id="ee9WZQtLjcF17-fill-1" offset="38%" stop-color="#cfcfd1"/><stop id="ee9WZQtLjcF17-fill-2" offset="100%" stop-color="#bbbbbc"/></linearGradient><linearGradient id="ee9WZQtLjcF18-fill" x1="177.05" y1="212.65" x2="149.35" y2="-25.39" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ee9WZQtLjcF18-fill-0" offset="2%" stop-color="#efefef"/><stop id="ee9WZQtLjcF18-fill-1" offset="9%" stop-color="#e4e4e6"/><stop id="ee9WZQtLjcF18-fill-2" offset="90%" stop-color="#f7f7f7"/><stop id="ee9WZQtLjcF18-fill-3" offset="99%" stop-color="#e4e4e6"/></linearGradient><linearGradient id="ee9WZQtLjcF19-fill" x1="14.41" y1="369.529999" x2="274.13" y2="266.289999" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ee9WZQtLjcF19-fill-0" offset="0%" stop-color="#585b61"/><stop id="ee9WZQtLjcF19-fill-1" offset="85%" stop-color="#484b4e"/><stop id="ee9WZQtLjcF19-fill-2" offset="100%" stop-color="#4c4f54"/></linearGradient></defs><rect width="25.287199" height="60" rx="0" ry="0" transform="matrix(.395457 0 0 1 53.757648 132.683243)" fill="#2b2b2c"/><rect width="25.287199" height="60" rx="0" ry="0" transform="matrix(.395457 0 0 1 238.757648 132.683243)" fill="#2b2b2c"/></svg>'),
                            ),
                            AnimatedPositioned(
                              top: (100 - 100 * percentHeight()) * px,
                              left: 0,
                              right: 0,
                              height: 600 * px,
                              duration: Durations.medium1,
                              child: SvgPicture.string(
                                  '<svg id="ecinkXvVIga1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 300 300" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" project-id="f9de0a2e30ca4d27a09746df76cf495a" export-id="413f1cbf4a1e42f29966c862e5b340c2" cached="false"><defs><linearGradient id="ecinkXvVIga12-fill" x1="119.25" y1="310.05" x2="119.25" y2="307.44" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ecinkXvVIga12-fill-0" offset="3%" stop-color="#9f9fa1"/><stop id="ecinkXvVIga12-fill-1" offset="100%" stop-color="#818182"/></linearGradient><linearGradient id="ecinkXvVIga13-fill" x1="107.08" y1="324.66" x2="107.08" y2="321.67" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ecinkXvVIga13-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ecinkXvVIga13-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ecinkXvVIga14-fill" x1="292.92" y1="324.66" x2="292.92" y2="321.67" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ecinkXvVIga14-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ecinkXvVIga14-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ecinkXvVIga15-fill" x1="200" y1="309.68" x2="200" y2="293.58" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ecinkXvVIga15-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ecinkXvVIga15-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ecinkXvVIga16-fill" x1="200" y1="309.68" x2="200" y2="293.58" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ecinkXvVIga16-fill-0" offset="3%" stop-color="#b8b8ba"/><stop id="ecinkXvVIga16-fill-1" offset="100%" stop-color="#9d9d9e"/></linearGradient><linearGradient id="ecinkXvVIga17-fill" x1="200" y1="324.67" x2="200" y2="293.62" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ecinkXvVIga17-fill-0" offset="14%" stop-color="#e1e1e3"/><stop id="ecinkXvVIga17-fill-1" offset="38%" stop-color="#cfcfd1"/><stop id="ecinkXvVIga17-fill-2" offset="100%" stop-color="#bbbbbc"/></linearGradient><linearGradient id="ecinkXvVIga18-fill" x1="177.05" y1="212.65" x2="149.35" y2="-25.39" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ecinkXvVIga18-fill-0" offset="2%" stop-color="#efefef"/><stop id="ecinkXvVIga18-fill-1" offset="9%" stop-color="#e4e4e6"/><stop id="ecinkXvVIga18-fill-2" offset="90%" stop-color="#f7f7f7"/><stop id="ecinkXvVIga18-fill-3" offset="99%" stop-color="#e4e4e6"/></linearGradient><linearGradient id="ecinkXvVIga19-fill" x1="14.41" y1="369.529999" x2="274.13" y2="266.289999" spreadMethod="pad" gradientUnits="userSpaceOnUse" gradientTransform="translate(0 0)"><stop id="ecinkXvVIga19-fill-0" offset="0%" stop-color="#585b61"/><stop id="ecinkXvVIga19-fill-1" offset="85%" stop-color="#484b4e"/><stop id="ecinkXvVIga19-fill-2" offset="100%" stop-color="#4c4f54"/></linearGradient></defs><rect width="46" height="46" rx="0" ry="0" transform="matrix(5.27048 0 0 0.156723 28.77896 104.252255)" fill="#917149"/><rect width="46" height="46" rx="0" ry="0" transform="matrix(.163376 0 0 1.647589 55 111.333292)" fill="#2b2b2c"/><rect width="46" height="46" rx="0" ry="0" transform="matrix(.163376 0 0 1.647589 240 111.461513)" fill="#2b2b2c"/><g transform="matrix(.295089 0 0 0.232373 90.9822 29.617049)"><path d="M123.19,309.51v0" transform="translate(.000002-3.322938)" fill="url(#ecinkXvVIga12-fill)"/><path d="M102.46,321.54l-.67,1.11c-.228616.37054-.242436.834832-.036263,1.218313s.601086.628025,1.036263.641687h3.9c1.619127.000562,3.23411-.163617,4.82-.49v0c.642732-.115357,1.088371-.706004,1.022876-1.355713s-.620052-1.13953-1.272876-1.124287Z" transform="translate(.000002-3.322938)" fill="url(#ecinkXvVIga13-fill)"/><path d="M297.54,321.54h-8.84c-.652824-.015243-1.207381.474577-1.272876,1.124287s.380144,1.240356,1.022876,1.355713v0c1.58589.326383,3.200873.490562,4.82.49h3.9c.435177-.013662.83009-.258205,1.036263-.641687s.192353-.847773-.036263-1.218313Z" transform="translate(.000002-3.322938)" fill="url(#ecinkXvVIga14-fill)"/><path d="" transform="translate(.000002-3.322938)" fill="url(#ecinkXvVIga15-fill)"/><path d="M284.88,308.87c.368194.018649.716785-.166798.907076-.482557s.191416-.710606.002924-1.027443" transform="translate(.000002-3.322938)" fill="url(#ecinkXvVIga16-fill)"/><path d="M298.21,321.17l-1.86-3.07c-.757868-1.255431-1.99784-2.144741-3.43-2.46L210.85,297.7c-1.97994-.43327-3.698365-1.653496-4.76-3.38l-.9-1.46c-.214767-.349014-.590411-.566887-1-.58h-3.09c-.443994.002695-.85085.248344-1.06.64-.20915-.391656-.616006-.637305-1.06-.64h-3.09c-.409589.013113-.785233.230986-1,.58l-.9,1.46c-1.061635,1.726504-2.78006,2.94673-4.76,3.38l-82.07,17.94c-1.43216.315259-2.672132,1.204569-3.43,2.46l-1.86,3.07c-.228616.37054-.242436.834832-.036263,1.218313s.601086.628025,1.036263.641687h3.9c1.619127.000562,3.23411-.163617,4.82-.49L200,304.31l88.45,18.22c1.58589.326383,3.200873.490562,4.82.49h3.9c.439165-.001707.843523-.239321,1.058732-.622145s.208055-.851774-.018732-1.227855Z" transform="translate(.000002-3.322938)" fill="url(#ecinkXvVIga17-fill)"/><rect width="326.5" height="188.09" rx="2.73" ry="2.73" transform="translate(36.750002 102.167062)" fill="url(#ecinkXvVIga18-fill)" stroke="#e6e6e6" stroke-miterlimit="10"/><rect width="172.51" height="310.93" rx="1.42" ry="1.42" transform="matrix(0 1-1 0 355.460002 109.947062)" fill="url(#ecinkXvVIga19-fill)"/></g></svg>'),
                            ),
                            AnimatedPositioned(
                              duration: Durations.medium1,
                              top: (225 - 100 * percentHeight()) * px,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Text(
                                  HeightValue(
                                          _tableUnit,
                                          _selectedTableData!["Data"]
                                              ["CurrentHeight"])
                                      .toString(),
                                  style: TextStyle(fontSize: 30 * px),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip:
                            "Lower table ${HeightValue(_tableUnit, 0.1)}  ",
                        onPressed: () => setTableHeight(
                            _selectedTableData!["Data"]["CurrentHeight"] - 0.1),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                    ],
                  ),
                ),
                DropdownButton(
                  value: _tableUnit,
                  items: const [
                    DropdownMenuItem(value: "m", child: Text("m")),
                    DropdownMenuItem(value: "cm", child: Text("cm")),
                    DropdownMenuItem(value: "burgers", child: Text("inch"))
                  ],
                  onChanged: (String? val) {
                    setState(() => _tableUnit = val ?? "m");
                  },
                ),
              ],
            ),
            Expanded(
              child: Card(
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 12.0,
                              left: 16.0,
                              right: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Presets:",
                                  style: TextStyle(fontSize: 32),
                                ),
                                Visibility(
                                  visible: _personalizationEnabled,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text("Add preset"),
                                    onPressed: () => showDialog<String>(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          DialogInput(addPreset: addPreset),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              onReorder: (oldIndex, newIndex) {
                                if (newIndex > oldIndex) newIndex--;
                                var tmp = _userPreferences!["HeightPresets"]
                                    [oldIndex];
                                _userPreferences!["HeightPresets"]
                                    .removeAt(oldIndex);
                                _userPreferences!["HeightPresets"]
                                    .insert(newIndex, tmp);
                                savePresets(_userPreferences!["HeightPresets"]);
                              },
                              itemCount:
                                  _userPreferences!["HeightPresets"].length,
                              itemBuilder: (context, index) => ListTile(
                                key: Key(index.toString()),
                                leading: _personalizationEnabled
                                    ? ReorderableDragStartListener(
                                        enabled: _personalizationEnabled,
                                        key: Key(index.toString()),
                                        index: index,
                                        child: const Icon(Icons.drag_handle),
                                      )
                                    : null,
                                title: Text(HeightValue.fromJson(
                                        _userPreferences!["HeightPresets"]
                                            [index])
                                    .toString()),
                                trailing: _personalizationEnabled
                                    ? IconButton(
                                        onPressed: () {
                                          List presets =
                                              _userPreferences!["HeightPresets"]
                                                  .toList();
                                          presets.removeAt(index);
                                          savePresets(presets);
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ))
                                    : null,
                                onTap: () {
                                  setTableHeight(HeightValue.fromJson(
                                          _userPreferences!["HeightPresets"]
                                              [index])
                                      .toAbsoluteHeight(
                                          _selectedTableData!["Data"]
                                              ["MinHeight"],
                                          _selectedTableData!["Data"]
                                              ["MaxHeight"]));
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
            visible: _statsOpen,
            child: UserStats(
              stats: _stats,
              min: _selectedTableData!["Data"]["MinHeight"],
              max: _selectedTableData!["Data"]["MaxHeight"],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Visibility(
            visible: Settings.tracking.enabled,
            child: IconButton(
              tooltip: "Stats",
              onPressed: () => setState(() => _statsOpen = !_statsOpen),
              icon: Icon(
                Icons.line_axis,
                color: _statsOpen ? Colors.red : null,
              ),
            ),
          ),
        ),
        BackButton(
          onPressed: () => widget.deselectTable(),
        ),
        AnimatedPositioned(
          bottom: _stats.sittingTooLong &&
                  _selectedTableData!["Data"]["CurrentHeight"] <
                      Settings.tracking.sittingHeight.value
              ? 0
              : -100,
          left: 0,
          right: 0,
          duration: Durations.medium1,
          child: const Center(
            child: Dialog(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "You have been sitting for a long time\nConsider standing",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DialogInput extends StatefulWidget {
  const DialogInput({super.key, required this.addPreset});
  final Function(HeightValue) addPreset;
  @override
  State<DialogInput> createState() => _DialogState();
}

class _DialogState extends State<DialogInput> {
  final TextEditingController _presetController = TextEditingController();
  String _presetUnit = Settings.app.defaultUnit;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _presetController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                      decoration: const InputDecoration(
                        labelText: "Preset Value",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButton(
                        value: _presetUnit,
                        items: const [
                          DropdownMenuItem(value: "m", child: Text("m")),
                          DropdownMenuItem(value: "cm", child: Text("cm")),
                          DropdownMenuItem(value: "%", child: Text("%")),
                          DropdownMenuItem(
                              value: "burgers", child: Text("inch"))
                        ],
                        onChanged: (String? val) {
                          setState(() => _presetUnit = val ?? "m");
                        }),
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    widget.addPreset(
                      HeightValue.adjusted(
                          _presetUnit, double.parse(_presetController.text)),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Ok'),
                ),
                const SizedBox(
                  width: 64,
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
