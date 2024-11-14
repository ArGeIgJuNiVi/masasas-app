// ignore_for_file: constant_identifier_names

import 'dart:math';

import 'package:flutter/material.dart';

class TableValue {
  TableValue(this.id, this.dailyAccessCode, this.data);
  String id;
  String dailyAccessCode;
  TableData data;

  static TableValue fromJson(json) => TableValue(
      json["ID"], json["DailyAccessCode"], TableData.fromJson(json["Data"]));
}

class TableData {
  TableData(this.macAddress, this.manufacturer, this.maxHeight, this.minHeight,
      this.currentHeight, this.location, this.icon);
  String macAddress;
  String manufacturer;
  double maxHeight;
  double minHeight;
  double currentHeight;
  String location;
  String icon;

  static TableData fromJson(json) => TableData(
        json["MacAddress"],
        json["Manufacturer"],
        json["MaxHeight"].toDouble(),
        json["MinHeight"].toDouble(),
        json["CurrentHeight"].toDouble(),
        json["Location"],
        json["Icon"],
      );
}

class HeightValue {
  double value;
  String unit;

  HeightValue(this.value, this.unit);

  static HeightValue fromJson(json) =>
      HeightValue(json["Value"].toDouble(), json["Unit"]);

  @override
  String toString() {
    return switch (unit) {
      "%" => "${(value * 100).toStringAsFixed(0)} %",
      _ => "$value $unit",
    };
  }

  double toAbsoluteHeight(double minHeight, double maxHeight) {
    return switch (unit) {
      "%" => value * (maxHeight - minHeight) + minHeight,
      "cm" => value * 100,
      _ => value,
    };
  }

  Map<String, dynamic> toJson() => {
        "Value": value,
        "Unit": unit,
      };
}

class UserPreferences {
  UserPreferences(this.name, this.heightPresets);
  String name;

  List<HeightValue> heightPresets;

  static UserPreferences fromJson(json) => UserPreferences(
        json["Name"],
        (json["HeightPresets"] as List<dynamic>)
            .map((e) => HeightValue.fromJson(e))
            .toList()
            .cast(),
      );

  Map<String, dynamic> toJson() => {
        "Name": name,
        "HeightPresets": heightPresets,
      };
}

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

Widget deskIcon(String iconName) => switch (iconName) {
      _ => const Icon(
          Icons.table_restaurant,
          size: 48,
        ),
    };
double unitAdjusted(String unit, double val) {
  return switch (unit) {
    "%" => val / 100,
    _ => val,
  };
}
