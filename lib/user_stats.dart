import 'dart:collection';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:masasas_app/height.dart';
import 'package:masasas_app/settings.dart';

class SessionStats {
  Queue<num> _heights = Queue();
  int _lastMinute = -1;
  int _totalMinutes = 0;
  int _minutesSitting = 0;
  int _minutesSinceLastStand = 0;

  String _minutesToString(int m) => m >= 60
      ? "${(m ~/ 60).toString().padLeft(2, "0")} h ${(m % 60).toString().padLeft(2, "0")} m"
      : "$m m";

  int get length => _heights.length;

  bool get sittingTooLong =>
      _minutesSinceLastStand >= Settings.trackingSittingTooLongMinutes;

  int get minutes => _totalMinutes;
  String get time => _minutesToString(_totalMinutes);

  int get minutesSitting => _minutesSitting;
  String get timeSitting => _minutesToString(_minutesSitting);

  int get minutesStanding => _totalMinutes - _minutesSitting;
  String get timeStanding => _minutesToString(_totalMinutes - _minutesSitting);

  void addDataPoint(num height, num minHeight, num maxHeight) {
    var currentMinute = DateTime.now().minute;

    // in debug mode, every data point is added, instead of the first per minute
    if (currentMinute != _lastMinute) {
      _heights.add(height);
      _lastMinute = currentMinute;
      _totalMinutes++;

      if (_heights.length > Settings.trackingMaxMinutes) {
        _heights.removeFirst();
      }

      if (height <=
          Settings.trackingSittingHeight
              .toAbsoluteHeight(minHeight, maxHeight)) {
        _minutesSinceLastStand++;
        _minutesSitting++;
      } else {
        _minutesSinceLastStand = 0;
      }
    }
  }

  LineChartBarData heights(String unit) {
    double i = 1;
    num minVal = double.infinity, maxVal = double.negativeInfinity;
    for (num heightValue in _heights) {
      if (heightValue < minVal) {
        minVal = heightValue;
      }
      if (heightValue > maxVal) {
        maxVal = heightValue;
      }
    }

    List<FlSpot> spots = _heights
        .map(
          (val) => FlSpot(
            i++,
            (HeightValue(unit, val).unitValue.toDouble() * 100).round() / 100,
          ),
        )
        .toList();

    return LineChartBarData(
      spots: spots,
    );
  }

  SessionStats();

  SessionStats.fromJson(json) {
    _heights = Queue();
    for (var val in json["heights"]) {
      _heights.add(val);
    }
    _totalMinutes = json["totalMinutes"];
    _minutesSitting = json["minutesSitting"];
  }

  Map toJson() => {
        "heights": _heights.toList(),
        "totalMinutes": _totalMinutes,
        "minutesSitting": _minutesSitting,
      };
}

class UserStats extends StatefulWidget {
  const UserStats({
    super.key,
    required this.sessions,
    required this.currentSession,
    required this.min,
    required this.max,
  });

  final Map<String, SessionStats> sessions;
  final String currentSession;
  final double min;
  final double max;

  @override
  State<UserStats> createState() => _UserStatsState();
}

class _UserStatsState extends State<UserStats> {
  String _unit = Settings.appDefaultUnit;
  late String _sessionSelection;

  @override
  void initState() {
    _sessionSelection = widget.currentSession;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 100,
              child: LineChart(
                LineChartData(
                  minY: HeightValue(_unit, widget.min).unitValue.toDouble(),
                  maxY: HeightValue(_unit, widget.max).unitValue.toDouble(),
                  lineBarsData: [
                    widget.sessions[_sessionSelection]!.heights(_unit),
                  ],
                  lineTouchData: const LineTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) =>
                            Text(HeightValue.adjusted(_unit, value).toString()),
                        reservedSize: 50,
                        minIncluded: false,
                        maxIncluded: false,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          var time = (DateTime.now().subtract(Duration(
                              minutes:
                                  widget.sessions.length - value.toInt())));
                          return Transform.rotate(
                            angle: pi / 6,
                            child: Text(
                                ("   ${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}")),
                          );
                        },
                        reservedSize: 50,
                        minIncluded: false,
                        maxIncluded: false,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                      "Time sitting:\n${widget.sessions[_sessionSelection]!.timeSitting}",
                      textAlign: TextAlign.center),
                  Text(
                      "Time standing:\n${widget.sessions[_sessionSelection]!.timeStanding}",
                      textAlign: TextAlign.center),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Unit:"),
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: DropdownButton(
                          value: _unit,
                          items: const [
                            DropdownMenuItem(value: "m", child: Text("m")),
                            DropdownMenuItem(value: "cm", child: Text("cm")),
                            DropdownMenuItem(
                                value: "burgers", child: Text("inch"))
                          ],
                          onChanged: (String? val) {
                            _unit = val ?? Settings.appDefaultUnit;
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: widget.sessions.length > 1,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Session:"),
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: DropdownButton(
                            value: _sessionSelection,
                            items: widget.sessions.keys
                                .map(
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(val),
                                  ),
                                )
                                .toList(),
                            onChanged: (String? val) {
                              _sessionSelection = val ?? widget.currentSession;
                              setState(() {});
                            },
                          ),
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
    );
  }
}
