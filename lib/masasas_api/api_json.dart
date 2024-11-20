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
  ({
    String type,
    String key,
    String url,
  })? api,
  ({
    String name,
  })? bluetooth,
]) {
  return """{
  "Data": {
    "MacAddress": "$macAddress",
    "ConnectionMode": "$connectionMode",
    "Manufacturer": "$manufacturer",
    "MinHeight": $minHeight,
    "MaxHeight": $maxHeight,
    "CurrentHeight": ${currentHeight ?? minHeight},
    "Name": "$name",
    "Icon": "$icon",
    "Api": ${api == null ? "null" : tableApiDataJson(api.type, api.key, api.url)},
    "Bluetooth": ${bluetooth == null ? "null" : tableBluetoothDataJson(bluetooth.name)}
  }
}""";
}

/// Returns the json representation of a [TableData.ApiData] (server type)
/// used in the [MasasasAPI.adminImportTablesExternalApi] method
String tableApiDataJson(
  String type,
  String url,
  String key,
) =>
    """{
  "Type": "$type",
  "Url": "$url",
  "Key": "$key"
}""";

/// Returns the json representation of a [TableData.BluetoothData] (server type)
/// TODO not used yet because bluetooth functionality is not implemented
String tableBluetoothDataJson(
  String name,
) =>
    """{
  "Name": "$name"
}""";
