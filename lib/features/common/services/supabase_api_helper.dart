import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_config.dart';
import '../models/auth_response_model.dart';
import '../models/response_message_model.dart';

class SupabaseApiHelper {
  static Future<bool>? _refreshInFlight;

  static Future<Map<String, String>> httpHeader(String? route) async {
    final prefs = await SharedPreferences.getInstance();

    // Default schema
    String schema = 'public';

    if (route != null && route.trim().isNotEmpty) {
      final parts = route.trim().split('.');
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        schema = parts.first;
      }
    }

    final accessToken = prefs.getString('access_token');

    return {
      'Content-Type': 'application/json',
      'Content-Profile': schema, // Supabase schema
      'apikey': appConfig.localKey,
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  static Future<ResponseMessageModel> safeApiCall(
    Future<ResponseMessageModel> Function() call,
  ) async {
    try {
      return await call();
    } catch (e) {
      return ResponseMessageModel.error(message: e.toString());
    }
  }

  static Future<AuthResponseModel> signin(
    String route,
    Map<String, dynamic>? data,
  ) async {
    final headers = await httpHeader(route);

    Uri uri = Uri.parse(
      '${appConfig.apiBaseUrl}/auth/v1/token?grant_type=password',
    );
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );
    return AuthResponseModel.fromJson(jsonDecode(response.body));
  }

  static bool _isJwtExpiredResponse(ResponseMessageModel response) {
    final message = response.message.toLowerCase();
    return response.statusCode == 401 ||
        message.contains('jwt expired') ||
        message.contains('token expired') ||
        message.contains('invalid jwt');
  }

  static Future<AuthResponseModel> refreshSession(String refreshToken) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'apikey': appConfig.localKey,
    };

    final uri = Uri.parse(
      '${appConfig.apiBaseUrl}/auth/v1/token?grant_type=refresh_token',
    );
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    return AuthResponseModel.fromJson(jsonDecode(response.body));
  }

  static Future<bool> tryRefreshAccessToken() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }

    _refreshInFlight = _refreshAccessTokenInternal();
    try {
      return await _refreshInFlight!;
    } finally {
      _refreshInFlight = null;
    }
  }

  static Future<bool> _refreshAccessTokenInternal() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    final refreshResponse = await refreshSession(refreshToken);
    final newAccessToken = refreshResponse.accessToken;

    if (newAccessToken == null || newAccessToken.isEmpty) {
      return false;
    }

    await prefs.setString('access_token', newAccessToken);
    if (refreshResponse.refreshToken != null &&
        refreshResponse.refreshToken!.isNotEmpty) {
      await prefs.setString('refresh_token', refreshResponse.refreshToken!);
    }
    return true;
  }

  // POST request
  static Future<ResponseMessageModel> post(
    String route,
    Map<String, dynamic>? data,
  ) async {
    String functionName = route.trim().split('.').last;
    final body = jsonEncode(data ?? {});

    final headers = await httpHeader(route);
    Uri uri = Uri.parse('${appConfig.apiBaseUrl}/rest/v1/rpc/$functionName');
    final firstResponse = await http.post(uri, headers: headers, body: body);
    final parsedFirst = ResponseMessageModel.fromJson(
      jsonDecode(firstResponse.body),
    );

    if (_isJwtExpiredResponse(parsedFirst)) {
      final refreshed = await tryRefreshAccessToken();
      if (refreshed) {
        final retriedHeaders = await httpHeader(route);
        final retryResponse = await http.post(
          uri,
          headers: retriedHeaders,
          body: body,
        );
        return ResponseMessageModel.fromJson(jsonDecode(retryResponse.body));
      }
    }

    return parsedFirst;
  }

  static Future<ResponseMessageModel> postEdg(
    String route,
    Map<String, dynamic>? data,
  ) async {
    String functionName = route.trim().split('.').last;

    final headers = await httpHeader(route);
    Uri uri = Uri.parse('${appConfig.apiBaseUrl}/functions/v1/$functionName');
    final firstResponse = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );
    final parsedFirst = ResponseMessageModel.fromJson(
      jsonDecode(firstResponse.body),
    );

    if (_isJwtExpiredResponse(parsedFirst)) {
      final refreshed = await tryRefreshAccessToken();
      if (refreshed) {
        final retriedHeaders = await httpHeader(route);
        final retryResponse = await http.post(
          uri,
          headers: retriedHeaders,
          body: jsonEncode(data),
        );
        return ResponseMessageModel.fromJson(jsonDecode(retryResponse.body));
      }
    }

    return parsedFirst;
  }

  static ResponseMessageModel _parseAuthApiResponse(
    http.Response response, {
    String successMessage = 'Request successful',
  }) {
    final statusCode = response.statusCode;
    final dynamic decoded = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;

    if (statusCode >= 200 && statusCode < 300) {
      return ResponseMessageModel(
        isSuccess: true,
        statusCode: statusCode,
        message: successMessage,
        data: const [],
      );
    }

    String errorMessage = 'Request failed';
    if (decoded is Map<String, dynamic>) {
      errorMessage =
          (decoded['msg'] ??
                  decoded['message'] ??
                  decoded['error_description'] ??
                  decoded['error'])
              ?.toString() ??
          errorMessage;
    }

    return ResponseMessageModel.error(
      statusCode: statusCode,
      message: errorMessage,
    );
  }

  static Future<ResponseMessageModel> updateAuthPassword(
    String newPassword,
  ) async {
    final uri = Uri.parse('${appConfig.apiBaseUrl}/auth/v1/user');
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null || accessToken.isEmpty) {
      return ResponseMessageModel.error(
        statusCode: 401,
        message: 'Session expired. Please login again.',
      );
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'apikey': appConfig.localKey,
      'Authorization': 'Bearer $accessToken',
    };

    final firstResponse = await http.put(
      uri,
      headers: headers,
      body: jsonEncode({'password': newPassword}),
    );
    final parsedFirst = _parseAuthApiResponse(
      firstResponse,
      successMessage: 'Password updated successfully',
    );

    if (_isJwtExpiredResponse(parsedFirst)) {
      final refreshed = await tryRefreshAccessToken();
      if (refreshed) {
        final refreshedToken = prefs.getString('access_token');
        if (refreshedToken == null || refreshedToken.isEmpty) {
          return ResponseMessageModel.error(
            statusCode: 401,
            message: 'Session expired. Please login again.',
          );
        }

        final retriedHeaders = <String, String>{
          'Content-Type': 'application/json',
          'apikey': appConfig.localKey,
          'Authorization': 'Bearer $refreshedToken',
        };
        final retryResponse = await http.put(
          uri,
          headers: retriedHeaders,
          body: jsonEncode({'password': newPassword}),
        );
        return _parseAuthApiResponse(
          retryResponse,
          successMessage: 'Password updated successfully',
        );
      }
    }

    return parsedFirst;
  }
}
