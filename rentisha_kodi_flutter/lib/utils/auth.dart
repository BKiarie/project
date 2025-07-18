import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String>> getAuthHeaders() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  return {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
} 