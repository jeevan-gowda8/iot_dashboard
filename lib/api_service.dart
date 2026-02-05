// ignore_for_file: empty_catches

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ Headers required for Thingsay in APK release
  static const Map<String, String> _headers = {
    "User-Agent": "Mozilla/5.0",
    "Accept": "*/*",
    "Connection": "keep-alive",
  };

  /// ✅ GET that can return JSON OR plain text
  static Future<dynamic> fetchData(String url) async {
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final body = res.body.trim();

        // If JSON → decode
        if (body.startsWith('{') || body.startsWith('[')) {
          return jsonDecode(body);
        }

        // If plain text → return as string
        return body.replaceAll('"', '');
      }
    } catch (e) {}

    return null;
  }

  /// ✅ POST → ON/OFF
  static Future<void> postTrigger(String url) async {
    try {
      await http.post(
        Uri.parse(url),
        headers: _headers,
      );
    } catch (e) {}
  }
}
