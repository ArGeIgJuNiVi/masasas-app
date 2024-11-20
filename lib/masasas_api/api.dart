import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:masasas_app/settings.dart';
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
  static final HttpClient _httpClient = HttpClient()
    ..badCertificateCallback = (_, __, ___) => true;
  static String? cachedPem;

  static Future<MasasasResponse> _handleRequest(
    String path,
    String? body,
  ) async {
    HttpClientResponse response;
    String responseBody;
    if (body == null) {
      try {
        response = await ((await _httpClient
                .getUrl(
                  Uri(
                    scheme: Settings.apiScheme,
                    host: Settings.apiHost,
                    port: Settings.apiPort,
                    path: path,
                  ),
                )
                .timeout(
                  Duration(seconds: 3),
                  onTimeout: () => throw ("getUrl timeout"),
                )))
            .close()
            .timeout(
              Duration(seconds: 3),
              onTimeout: () => throw ("getUrl close timeout"),
            );
        responseBody = await response.transform(utf8.decoder).join();
      } catch (e) {
        if (kDebugMode) print(e);
        return MasasasResponse(ErrorMessages.genericConnectionError,
            MasasasResult.connectionError);
      }
    } else {
      try {
        response = await ((await _httpClient
                .postUrl(
                  Uri(
                    scheme: Settings.apiScheme,
                    host: Settings.apiHost,
                    port: Settings.apiPort,
                    path: path,
                  ),
                )
                .timeout(
                  Duration(seconds: 3),
                  onTimeout: () => throw ("postUrl timeout"),
                ))
              ..write(body))
            .close()
            .timeout(
              Duration(seconds: 3),
              onTimeout: () => throw ("postUrl close timeout"),
            );
        responseBody = await response.transform(utf8.decoder).join();
      } catch (e) {
        if (kDebugMode) print(e);
        return MasasasResponse(ErrorMessages.genericConnectionError,
            MasasasResult.connectionError);
      }
    }
    if (response.statusCode != 200) {
      return MasasasResponse(responseBody, MasasasResult.badRequest);
    }
    return MasasasResponse(responseBody, MasasasResult.ok);
  }

  /// ```text
  /// Get user id and daily access code
  ///
  /// - OK Request value -
  /// Returns the user id and daily access code as [Json]
  ///
  /// - Bad Request errors -
  /// "Invalid user id or daily access code"
  static Future<MasasasResponse> getUser(String userID, String password) {
    return _handleRequest("/user/$userID/$password", null);
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
          String userID, String userDailyAccessCode) =>
      _handleRequest(
          "/user/$userID/$userDailyAccessCode/get_preferences", null);

  /// ```text
  /// Get if the user is able to set preferences
  ///
  /// - OK Request value -
  /// Returns the user personalization state as a [String] representation of a [bool]
  ///
  /// Bad Request errors:
  /// "Invalid user id or daily access code"
  static Future<MasasasResponse> getUserPersonalizationState(
          String userID, String userDailyAccessCode) =>
      _handleRequest(
          "/user/$userID/$userDailyAccessCode/get_personalization_state", null);

  /// ```text
  /// Get if the user is able to delete their own account
  ///
  /// - OK Request value -
  /// Returns the user self deletion state as a [String] representation of a [bool]
  ///
  /// Bad Request errors:
  /// "Invalid user id or daily access code"
  static Future<MasasasResponse> getUserSelfDeletionState(
          String userID, String userDailyAccessCode) =>
      _handleRequest(
          "/user/$userID/$userDailyAccessCode/get_self_deletion_state", null);

  /// ```text
  /// Get the list of all tables and their daily access codes
  ///
  /// - OK Request value -
  /// Returns the tables list as [Json]
  ///
  /// - Bad Request errors -
  /// "Invalid user id or daily access code"
  static Future<MasasasResponse> getTables(
          String userID, String userDailyAccessCode) =>
      _handleRequest("/user/$userID/$userDailyAccessCode/get_tables", null);

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
          String userID, String userDailyAccessCode) =>
      _handleRequest("/user/$userID/$userDailyAccessCode/delete_user", null);

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
  static Future<MasasasResponse> setPreferences(
          String userID, String userDailyAccessCode, String preferencesJson) =>
      _handleRequest("/user/$userID/$userDailyAccessCode/set_preferences",
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
          String tableID, String tableDailyAccessCode) =>
      _handleRequest("/table/$tableID/$tableDailyAccessCode/get_data", null);

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
          String tableID, String tableDailyAccessCode, num height) =>
      _handleRequest("/table/$tableID/$tableDailyAccessCode/set_height",
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
  static Future<MasasasResponse> setTableHeightPercentage(
          String tableID, String tableDailyAccessCode, num heightPercentage) =>
      _handleRequest(
          "/table/$tableID/$tableDailyAccessCode/set_height_percentage",
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
          String adminID, String adminDailyAccessCode) =>
      _handleRequest("/admin/$adminID/$adminDailyAccessCode", null);

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
          String adminID, String adminDailyAccessCode) =>
      _handleRequest("/admin/$adminID/$adminDailyAccessCode/get_users", null);

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
          String adminID, String adminDailyAccessCode) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/disable_guest_warning", null);

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
          String adminID, String adminDailyAccessCode) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/enable_user_self_deletion",
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
          String adminID, String adminDailyAccessCode) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/disable_user_self_deletion",
          null);

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
          String adminID, String adminDailyAccessCode) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/enable_user_personalization",
          null);

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
          String adminID, String adminDailyAccessCode) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/disable_user_personalization",
          null);

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
          String adminID, String adminDailyAccessCode, String userID) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/enable_user_personalization/$userID",
          null);

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
          String adminID, String adminDailyAccessCode, String userID) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/disable_user_personalization/$userID",
          null);

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
          String adminID, String adminDailyAccessCode, String userID) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/delete_user/$userID", null);

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
          String adminID, String adminDailyAccessCode, String tableID) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/delete_table/$tableID", null);

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
  static Future<MasasasResponse> adminSetConfigReloadSeconds(
          String adminID, String adminDailyAccessCode, num time) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/set_config_reload_seconds",
          time.toString());

  /// ```text
  /// Set the time to update the tables' data using the external api or null to disable it (num, in seconds)
  ///
  /// - OK Request value -
  /// Returns the set request frequency in seconds as a [String] representing a [num]
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  ///
  /// "Invalid api request frequency time, should be a double in seconds, or null to disable requests"
  static Future<MasasasResponse> adminSetExternalApiRequestFrequencySeconds(
          String adminID, String adminDailyAccessCode, num time) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/set_external_api_request_frequency_seconds",
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
          String adminDailyAccessCode, String userID, String userJson) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/create_user/$userID",
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
  static Future<MasasasResponse> adminCreateTable(String adminID,
          String adminDailyAccessCode, String tableID, String tableJson) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/create_table/$tableID",
          tableJson);

  /// ```text
  /// Import the tables from the provided external api
  ///
  /// - OK Request value -
  /// The string "Imported tables successfully"
  ///
  /// - Bad Request errors -
  /// "Invalid admin id or daily access code"
  ///
  /// "Unauthorized user"
  ///
  /// "Failed importing tables"
  ///
  /// """
  /// Invalid api connection details:
  /// {bodyText}
  /// correct format:
  /// {JsonSerializer.Serialize(Data.NewTable.Data.Api, Utils.JsonOptions)}
  /// """
  static Future<MasasasResponse> adminImportTablesExternalApi(
          String adminID, String adminDailyAccessCode, String apiDataJson) =>
      _handleRequest(
          "/admin/$adminID/$adminDailyAccessCode/import_tables_external_api",
          apiDataJson);
}
