import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart';
import 'package:masasas_app/config.dart';

String encrypt(String str) =>
    hex.encode(sha256.convert(utf8.encode(str)).bytes).toUpperCase();

String dailyAccessCode(String passwordEncrypted) => encrypt(
        "$passwordEncrypted${DateTime.now().toUtc().day}${DateTime.now().toUtc().year}")
    .toUpperCase();

Uri apiURI(Iterable<String> path) => Uri(
      scheme: Config.api.scheme,
      host: Config.api.host,
      port: Config.api.port,
      pathSegments: path,
    );

Client httpClient = Client();
