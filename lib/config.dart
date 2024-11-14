import 'package:masasas_app/utils.dart';

class Config {
  static var api = (scheme: "http", host: "localhost", port: 5088);

  static var guestCredentials =
      (id: "guest", encryptedPassword: encrypt("1234"));

  static save() {}

  static load() {}
}
