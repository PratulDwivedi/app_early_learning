import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_config.dart';
import '../models/response_message_model.dart';

class SupabaseApiHelper {
  static Future<Map<String, String>> httpHeader(String? route) async {
    final prefs = await SharedPreferences.getInstance();

    // Default schema
    String schema = 'edu';

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
        'access_token': accessToken,
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

  // POST request
  static Future<ResponseMessageModel> post(
    String route,
    Map<String, dynamic>? data,
  ) async {
    final headers = await httpHeader(route);

    String functionName = route.trim().split('.').last;

    Uri uri = Uri.parse('${appConfig.apiBaseUrl}/rest/v1/rpc/$functionName');
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );
    return ResponseMessageModel.fromJson(jsonDecode(response.body));
  }

  static Future<ResponseMessageModel> postEdg(
    String route,
    Map<String, dynamic>? data,
  ) async {
    final headers = await httpHeader(route);

    String functionName = route.trim().split('.').last;

    Uri uri = Uri.parse('${appConfig.apiBaseUrl}/functions/v1/$functionName');
    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(data),
    );
    return ResponseMessageModel.fromJson(jsonDecode(response.body));
  }
}
