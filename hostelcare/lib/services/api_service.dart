import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart' show XFile;

class ApiService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  static Map<String, String> _headers(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  static Future<Map<String, dynamic>> get(String url) async {
    final token = await _getToken();
    final response = await http.get(Uri.parse(url), headers: _headers(token));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> put(String url, Map<String, dynamic> body) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse(url),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> delete(String url) async {
    final token = await _getToken();
    final response = await http.delete(Uri.parse(url), headers: _headers(token));
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> multipartPost(
    String url, {
    Map<String, String>? fields,
    List<XFile>? files,
    String fileField = 'images',
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest('POST', Uri.parse(url));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (fields != null) request.fields.addAll(fields);
    if (files != null) {
      for (final file in files) {
        if (kIsWeb) {
          final bytes = await file.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            fileField,
            bytes,
            filename: file.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
        }
      }
    }
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _processResponse(response);
  }

  static Map<String, dynamic> _processResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw ApiException(body['message'] ?? 'Something went wrong', response.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
