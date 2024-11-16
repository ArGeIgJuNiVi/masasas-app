import 'package:masasas_app/api.dart';

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
  "PasswordRSA": "${await MasasasApi.rsaEncrypt(password)}",
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
