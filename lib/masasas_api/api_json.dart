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
  String location,
  String macAddress,
  String manufacturer,
  num minHeight,
  num maxHeight, [
  num? currentHeight,
  String icon = "table",
]) =>
    """
{
  "Data": {
    "Location": "$location",
    "MacAddress": "$macAddress",
    "Manufacturer": "$manufacturer",
    "MinHeight": $minHeight,
    "MaxHeight": $maxHeight,
    "CurrentHeight": ${currentHeight ?? minHeight},
    "Icon": "$icon"
  }
}
""";
