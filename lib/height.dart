class HeightValue {
  String unit;
  num value;

  HeightValue(this.unit, this.value);

  static HeightValue fromJson(json) => HeightValue(json["Unit"], json["Value"]);

  @override
  String toString() {
    return switch (unit) {
      "burgers" => "${toStringWithoutUnit()} \"",
      _ => "${toStringWithoutUnit()} $unit",
    };
  }

  String toStringWithoutUnit() {
    return switch (unit) {
      "m" => unitValue.toStringAsFixed(2),
      "%" => unitValue.toStringAsFixed(0),
      "cm" => unitValue.toStringAsFixed(0),
      "burgers" => unitValue.toStringAsFixed(0),
      _ => unitValue.toStringAsFixed(2),
    };
  }

  num get unitValue => switch (unit) {
        "m" => value,
        "%" => (value * 100),
        "cm" => (value * 100),
        "burgers" => (value / 0.0254),
        _ => value,
      };

  num toAbsoluteHeight(num minHeight, num maxHeight) {
    return switch (unit) {
      "%" => value * (maxHeight - minHeight) + minHeight,
      _ => value,
    };
  }

  static HeightValue adjusted(String unit, num value) {
    return HeightValue(
      unit,
      switch (unit) {
        "%" => value / 100,
        "cm" => value / 100,
        "burgers" => value * 0.0254,
        _ => value,
      },
    );
  }

  Map<String, dynamic> toJson() => {
        "Unit": unit,
        "Value": value,
      };
}

class PresetValue {
  PresetValue(this.height, this.name);
  HeightValue height;
  String? name;

  static PresetValue fromJson(json) =>
      PresetValue(HeightValue(json["Unit"], json["Value"]), json["Name"]);

  Map<String, dynamic> toJson() => {
        "Unit": height.unit,
        "Value": height.value,
        "Name": name,
      };
}
