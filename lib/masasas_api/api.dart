import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:masasas_app/settings.dart';
import 'package:masasas_app/data/error_messages.dart';
import 'package:pointycastle/export.dart';

enum MasasasResult { ok, badRequest, connectionError }

class MasasasResponse {
  MasasasResponse(this.body, this.result);
  MasasasResult result;
  String body;

  @override
  String toString() {
    return body;
  }
}

/// Contains implementations for all the endpoints defined in the masasas table interface
class MasasasApi {
  static final Client _httpClient = Client();
  static String? cachedPem;
  static late RSA cipher;

  static Future<MasasasResponse> _handleRequest(
    List<String> path,
    String? body,
  ) async {
    Response response;
    if (body == null) {
      try {
        response = await _httpClient.get(
          Uri(
            scheme: Settings.apiScheme,
            host: Settings.apiHost,
            port: Settings.apiPort,
            pathSegments: path,
          ),
        );
      } catch (e) {
        if (kDebugMode) print(e);
        return MasasasResponse(ErrorMessages.genericConnectionError,
            MasasasResult.connectionError);
      }
    } else {
      try {
        response = await _httpClient.post(
          Uri(
            scheme: Settings.apiScheme,
            host: Settings.apiHost,
            port: Settings.apiPort,
            pathSegments: path,
          ),
          body: body,
        );
      } catch (e) {
        if (kDebugMode) print(e);
        return MasasasResponse(ErrorMessages.genericConnectionError,
            MasasasResult.connectionError);
      }
    }
    if (response.statusCode != 200) {
      return MasasasResponse(response.body, MasasasResult.badRequest);
    }
    return MasasasResponse(response.body, MasasasResult.ok);
  }

  /// ```text
  /// Encrypt a [String] using the server's client rsa key
  ///
  /// - OK Request value -
  /// Returns a
  static Future<MasasasResponse> rsaEncrypt(String str,
      [String typeOfString = "password"]) async {
    MasasasResponse rsaPem = await _handleRequest(["rsa"], null);

    if (rsaPem.result != MasasasResult.ok) return rsaPem;

    try {
      if (rsaPem.body != cachedPem) {
        cachedPem = rsaPem.body;
        cipher =
            RSA(publicKey: RSAKeyParser().parse(rsaPem.body) as RSAPublicKey);
      }
      return MasasasResponse(
          cipher.encrypt(utf8.encode(str)).base16.toUpperCase(),
          MasasasResult.ok);
    } catch (e) {
      if (kDebugMode) print(e);
      return MasasasResponse(
          "Failed encrypting $typeOfString", MasasasResult.badRequest);
    }
  }

  /// ```text
  /// Get user id and daily access code
  ///
  /// - OK Request value -
  /// Returns the user id and daily access code as [Json]
  ///
  /// - Bad Request errors -
  /// "Invalid user id or daily access code"
  static Future<MasasasResponse> getUser(String userID, String password) async {
    MasasasResponse passwordRSA = await rsaEncrypt(password);
    if (passwordRSA.result != MasasasResult.ok) return passwordRSA;

    return await _handleRequest(
        ["user", userID, passwordRSA.body.toUpperCase()], null);
  }

  /// ```text
  /// Get user preferences
  ///
  /// - OK Request value -
  /// Returns the user preferences as [Json]
  ///
  /// - Bad Request errors -
  /// "Invalid user id or daily access code"
  static Future<MasasasResponse> getUserPreferences(
          String userID, String userDailyAccessCodeRSA) async =>
      await _handleRequest(
          ["user", userID, userDailyAccessCodeRSA, "get_preferences"], null);

  /// ```text
  /// Get if the user is able to set preferences
  ///
  /// - OK Request value -
  /// Returns the user personalization state as a [String] representation of a [bool]
  ///
  /// Bad Request errors:
  /// "Invalid user id or daily access code"
  static Future<MasasasResponse> getUserPersonalizationState(
          String userID, String userDailyAccessCodeRSA) async =>
      await _handleRequest(
          ["user", userID, userDailyAccessCodeRSA, "get_personalization_state"],
          null);

  /// ```text
  /// Get if the user is able to delete their own account
  ///
  /// - OK Request value -
  /// Returns the user self deletion state as a [String] representation of a [bool]
  ///
  /// Bad Request errors:
  /// "Invalid user id or daily access code"
  static Future<MasasasResponse> getUserSelfDeletionState(
          String userID, String userDailyAccessCodeRSA) async =>
      await _handleRequest(
          ["user", userID, userDailyAccessCodeRSA, "get_personalization_state"],
          null);

  /// ```text
  /// Get the list of all tables and their daily access codes
  ///
  /// - OK Request value -
  /// Returns the tables list as [Json]
  ///
  /// - Bad Request errors -
  /// "Invalid user id or daily access code"
  static Future<MasasasResponse> getTables(
          String userID, String userDailyAccessCodeRSA) async =>
      await _handleRequest(
          ["user", userID, userDailyAccessCodeRSA, "get_tables"], null);

  /// ```text
  /// Delete self
  ///
  /// - OK Request value -
  /// Returns the deleted user preferences as [Json]
  ///
  /// - Bad Request errors -
  /// "Invalid user id or daily access code"
  ///
  /// "User self deletion is disabled"
  ///
  /// "Cannot delete the last administrator"
  static Future<MasasasResponse> deleteUserSelf(
          String userID, String userDailyAccessCodeRSA) async =>
      await _handleRequest(
          ["user", userID, userDailyAccessCodeRSA, "delete_user"], null);

  /// ```text
  /// Set user preferences
  ///
  /// - OK Request value -
  /// Returns the set preferences as [Json]
  ///
  /// - Bad Request errors -
  /// "Invalid user id or daily access code"
  ///
  /// "User personalization is disabled"
  ///
  /// """
  /// Invalid user preferences:
  /// [BODY]
  /// Correct format:
  /// [EXAMPLE]
  /// """
  static Future<MasasasResponse> setPreferences(String userID,
          String userDailyAccessCodeRSA, String preferencesJson) async =>
      await _handleRequest(
          ["user", userID, userDailyAccessCodeRSA, "set_preferences"],
          preferencesJson);

  /// ```text
  /// Get table data
  ///
  /// - OK Request value -
  /// Returns the table data as [Json]
  ///
  /// - Bad Request errors -
  /// "Invalid table id or daily access code"
  static Future<MasasasResponse> getTableData(
          String tableID, String tableDailyAccessCode) async =>
      await _handleRequest(
          ["table", tableID, tableDailyAccessCode, "get_data"], null);

  /// ```text
  /// Set table height (num, in meters)
  ///
  /// - OK Request value -
  /// Returns the set table height as a [String] representation of a [num]
  ///
  /// - Bad Request errors -
  /// "Invalid table id or daily access code"
  ///
  /// "Invalid table height, should be a double in meters"
  static Future<MasasasResponse> setTableHeight(
          String tableID, String tableDailyAccessCode, num height) async =>
      await _handleRequest(
          ["table", tableID, tableDailyAccessCode, "set_height"],
          height.toString());

  /// ```text
  /// Set table height percentage (num, 0 to 1)
  ///
  /// - OK Request value -
  /// Returns the set table height percentage as a [String] representation of a [num]
  ///
  /// - Bad Request errors -
  /// "Invalid table id or daily access code"
  ///
  /// "Invalid table height percentage, should be a double between 0 and 1"
  static Future<MasasasResponse> setTableHeightPercentage(String tableID,
          String tableDailyAccessCode, num heightPercentage) async =>
      await _handleRequest(
          ["table", tableID, tableDailyAccessCode, "set_height_percentage"],
          heightPercentage.toString());

  /// ```text
  /// Get the list of all users
  ///
  /// - OK Request value -
  /// Returns if the user is an administrator as a [String] representation of a [bool]
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  static Future<MasasasResponse> adminGet(
          String adminID, String adminDailyAccessCode) async =>
      await _handleRequest(["admin", adminID, adminDailyAccessCode], null);

  /// ```text
  /// Get the list of all users
  ///
  /// - OK Request value -
  /// Returns the users list as [Json]
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  static Future<MasasasResponse> adminGetUsers(
          String adminID, String adminDailyAccessCode) async =>
      await _handleRequest(
          ["admin", adminID, adminDailyAccessCode, "get_users"], null);

  /// ```text
  /// Disable initial warning about the default account
  ///
  /// - OK Request value -
  /// The [String] "Warning disabled"
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  static Future<MasasasResponse> adminDisableGuestWarning(
          String adminID, String adminDailyAccessCode) async =>
      await _handleRequest(
          ["admin", adminID, adminDailyAccessCode, "disable_guest_warning"],
          null);

  /// ```text
  /// Enable the ability of the users to delete their own accounts
  ///
  /// - OK Request value -
  /// The [String] "User self deletion enabled"
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  static Future<MasasasResponse> adminEnableUsersSelfDeletion(
          String adminID, String adminDailyAccessCode) async =>
      await _handleRequest(
          ["admin", adminID, adminDailyAccessCode, "enable_user_self_deletion"],
          null);

  /// ```text
  /// Disable the ability of the users to delete their own accounts
  ///
  /// - OK Request value -
  /// The [String] "User self deletion disabled"
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  static Future<MasasasResponse> adminDisableUsersSelfDeletion(
          String adminID, String adminDailyAccessCode) async =>
      await _handleRequest([
        "admin",
        adminID,
        adminDailyAccessCode,
        "disable_user_self_deletion"
      ], null);

  /// ```text
  /// Enable the ability of the users to modify their account personalization
  ///
  /// - OK Request value -
  /// The [String] "User personalization enabled"
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  static Future<MasasasResponse> adminEnableUsersPersonalization(
          String adminID, String adminDailyAccessCode) async =>
      await _handleRequest([
        "admin",
        adminID,
        adminDailyAccessCode,
        "enable_user_personalization"
      ], null);

  /// ```text
  /// Disable the ability of the users to modify their account personalization
  ///
  /// - OK Request value -
  /// The [String] "User personalization disabled"
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  static Future<MasasasResponse> adminDisableUsersPersonalization(
          String adminID, String adminDailyAccessCode) async =>
      await _handleRequest([
        "admin",
        adminID,
        adminDailyAccessCode,
        "disable_user_personalization"
      ], null);

  /// ```text
  /// Enable the ability of a user to modify their account personalization
  ///
  /// - OK Request value -
  /// The [String] "User personalization enabled"
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  ///
  /// "User does not exist"
  static Future<MasasasResponse> adminEnableUserPersonalization(
          String adminID, String adminDailyAccessCode, String userID) async =>
      await _handleRequest([
        "admin",
        adminID,
        adminDailyAccessCode,
        "enable_user_personalization",
        userID
      ], null);

  /// ```text
  /// Disable the ability of a user to modify their account personalization
  ///
  /// - OK Request value -
  /// The [String] "User personalization disabled"
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  ///
  /// "User does not exist"
  static Future<MasasasResponse> adminDisableUserPersonalization(
          String adminID, String adminDailyAccessCode, String userID) async =>
      await _handleRequest([
        "admin",
        adminID,
        adminDailyAccessCode,
        "disable_user_personalization",
        userID
      ], null);

  /// ```text
  /// Delete a user account
  ///
  /// - OK Request value -
  /// The [String] "Deleted user $userID"
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  ///
  /// "Cannot delete last administrator"
  ///
  /// "User does not exist"
  static Future<MasasasResponse> adminDeleteUser(
          String adminID, String adminDailyAccessCode, String userID) async =>
      await _handleRequest(
          ["admin", adminID, adminDailyAccessCode, "delete_user", userID],
          null);

  /// ```text
  /// Delete a table
  ///
  /// - OK Request value -
  /// The [String] "Deleted table $userID"
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  ///
  /// "Table does not exist"
  static Future<MasasasResponse> adminDeleteTable(
          String adminID, String adminDailyAccessCode, String tableID) async =>
      await _handleRequest(
          ["admin", adminID, adminDailyAccessCode, "delete_table", tableID],
          null);

  /// ```text
  /// Set the time to reload a file or null to disable automatic reloading (num, in seconds)
  ///
  /// - OK Request value -
  /// Returns the set reload time in seconds as a [String] representing a [num]
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  ///
  /// "Invalid config reload time, should be a double in seconds, or null to disable reloading"
  static Future<MasasasResponse> adminSetConfigReloadTimeSeconds(
          String adminID, String adminDailyAccessCode, num time) async =>
      await _handleRequest(
          ["admin", adminID, adminDailyAccessCode, "set_config_reload_seconds"],
          time.toString());

  /// ```text
  /// Create or update a user account
  ///
  /// - OK Request value -
  /// Returns the set user data as Json
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  ///
  /// "Cannot edit the last administrator"
  ///
  /// """
  /// Invalid user:
  /// [BODY]
  /// Correct format:
  /// [EXAMPLE]
  /// """
  static Future<MasasasResponse> adminCreateUser(String adminID,
          String adminDailyAccessCode, String userID, String userJson) async =>
      await _handleRequest(
          ["admin", adminID, adminDailyAccessCode, "create_user", userID],
          userJson);

  /// ```text
  /// Create or update a table
  ///
  /// - OK Request value -
  /// Returns the set table data as Json
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  ///
  /// """
  /// Invalid table:
  /// [BODY]
  /// Correct format:
  /// [EXAMPLE]
  /// """
  static Future<MasasasResponse> adminCreateTable(
          String adminID,
          String adminDailyAccessCode,
          String tableID,
          String tableJson) async =>
      await _handleRequest(
          ["admin", adminID, adminDailyAccessCode, "create_table", tableID],
          tableJson);
}
