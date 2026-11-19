import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

  static Future<Map<String, dynamic>> predict(
    XFile image,
    String modelName,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/predict'),
    );

    request.fields['model_name'] = modelName;

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await image.readAsBytes(),
        filename: image.name,
      ),
    );

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    final result = jsonDecode(responseBody);

    if (response.statusCode == 200) {
      return result;
    }

    throw Exception(
      result['detail'] ?? 'Gagal melakukan deteksi'
    );
  }
}