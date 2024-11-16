class HeightValue {
  String unit;
  num value;

  HeightValue(this.unit, this.value);

  static HeightValue fromJson(json) => HeightValue(json["Unit"], json["Value"]);

  @override
  String toString() {
    return switch (unit) {
      "m" => "${value.toStringAsFixed(2)} m",
      "%" => "${(value * 100).toStringAsFixed(0)} %",
      "cm" => "${(value * 100).toStringAsFixed(0)} cm",
      "burgers" => "${(value / 0.0254).toStringAsFixed(0)} \"",
      _ => "$value $unit",
    };
  }

  num toAbsoluteHeight(num minHeight, num maxHeight) {
    return switch (unit) {
      "%" => value * (maxHeight - minHeight) + minHeight,
      _ => value,
    };
  }

  static adjusted(String unit, num value) {
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
