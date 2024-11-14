import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:masasas_app/config.dart';
import 'package:masasas_app/data/error_messages.dart';

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

  static Future<MasasasResponse> _handleRequest(
    List<String> path,
    String? body,
  ) async {
    Response response;
    if (body == null) {
      try {
        response = await _httpClient.get(
          Uri(
            scheme: Config.api.scheme,
            host: Config.api.host,
            port: Config.api.port,
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
            scheme: Config.api.scheme,
            host: Config.api.host,
            port: Config.api.port,
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
  /// Get user daily access code
  ///
  /// - OK Request value -
  /// Returns the daily access code as a [String]
  ///
  /// - Bad Request errors -
  /// "Invalid user id or daily access code"
  static Future<MasasasResponse> getUserDailyAccessCode(
          String userID, String password) async =>
      await _handleRequest(["user", userID, password], null);

  /// ```text
  /// Get user preferences
  ///
  /// - OK Request value -
  /// Returns the user preferences as [Json]
  ///
  /// - Bad Request errors -
  /// "Invalid user id or daily access code"
  static Future<MasasasResponse> getUserPreferences(
          String userID, String userDailyAccessCode) async =>
      await _handleRequest(
          ["user", userID, userDailyAccessCode, "get_preferences"], null);

  /// ```text
  /// Get if the user is able to set preferences
  ///
  /// - OK Request value -
  /// Returns the user personalization state as [String] representation of a [bool]
  ///
  /// Bad Request errors:
  /// ""Invalid user id or daily access code""
  static Future<MasasasResponse> getUserPersonalizationState(
          String userID, String userDailyAccessCode) async =>
      await _handleRequest(
          ["user", userID, userDailyAccessCode, "get_personalization_state"],
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
          String userID, String userDailyAccessCode) async =>
      await _handleRequest(
          ["user", userID, userDailyAccessCode, "get_tables"], null);

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
          String userID, String userDailyAccessCode) async =>
      await _handleRequest(
          ["user", userID, userDailyAccessCode, "delete_user"], null);

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
          String userDailyAccessCode, String preferencesJson) async =>
      await _handleRequest(
          ["user", userID, userDailyAccessCode, "set_preferences"],
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
  /// Set table height (double, in meters)
  ///
  /// - OK Request value -
  /// Returns the set table height as a [String] representation of a [double]
  ///
  /// - Bad Request errors -
  /// "Invalid table id or daily access code"
  ///
  /// "Invalid table height, should be a double in meters"
  static Future<MasasasResponse> setTableHeight(
          String tableID, String tableDailyAccessCode, double height) async =>
      await _handleRequest(
          ["table", tableID, tableDailyAccessCode, "set_height"],
          height.toString());

  /// ```text
  /// Set table height percentage (double, 0 to 1)
  ///
  /// - OK Request value -
  /// Returns the set table height percentage as a [String] representation of a [double]
  ///
  /// - Bad Request errors -
  /// "Invalid table id or daily access code"
  ///
  /// "Invalid table height percentage, should be a double between 0 and 1"
  static Future<MasasasResponse> setTableHeightPercentage(String tableID,
          String tableDailyAccessCode, double heightPercentage) async =>
      await _handleRequest(
          ["table", tableID, tableDailyAccessCode, "set_height_percentage"],
          heightPercentage.toString());

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
  /// Set the time to reload a file or null to disable automatic reloading (double, in seconds)
  ///
  /// - OK Request value -
  /// Returns the set reload time in seconds as a [String] representing a [double]
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  ///
  /// "Invalid config reload time, should be a double in seconds, or null to disable reloading"
  static Future<MasasasResponse> adminSetConfigReloadTimeSeconds(
          String adminID, String adminDailyAccessCode, double time) async =>
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
          ["admin", adminID, adminDailyAccessCode, "create_user"], userJson);

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
          ["admin", adminID, adminDailyAccessCode, "create_table"], tableJson);
}
