/// Returns the json representation of an [UnsecuredUser] (server type)
/// used in the [MasasasAPI.adminCreateUser] method
Future<String> newUserJson(
  String password,
  String username,
  String alias, [
  bool administrator = false,
  bool allowedPersonalization = true,
  bool allowedSelfDeletion = true,
]) async =>
    """
{
  "Password": "$password",
  "Preferences": {
    "Name": "$username",
    "HeightPresets": []
  },
  "Alias": ${alias.isNotEmpty ? '"$alias"' : null},
  "Administrator": $administrator,
  "AllowedPersonalization": $allowedPersonalization,
  "AllowedSelfDeletion": $allowedSelfDeletion
}
""";

/// Returns the json representation of an [UnsecuredTable] (server type)
/// used in the [MasasasAPI.adminCreateTable] method
String newTableJson(
  String macAddress,
  String connectionMode,
  String manufacturer,
  num minHeight,
  num maxHeight,
  String name, [
  num? currentHeight,
  String icon = "table",
]) =>
    """
{
  "Data": {
    "MacAddress": "$macAddress",
    "ConnectionMode": "$connectionMode",
    "Manufacturer": "$manufacturer",
    "MinHeight": $minHeight,
    "MaxHeight": $maxHeight,
    "CurrentHeight": ${currentHeight ?? minHeight},
    "Name": "$name",
    "Icon": "$icon"
  }
}
""";
