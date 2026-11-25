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

    // Nama field harus "model_name" (dibaca oleh backend main.py)
    request.fields['model_name'] = modelName;

    // Gambar dikirim apa adanya (bytes asli, tanpa resize/kompresi)
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await image.readAsBytes(),
        filename: image.name,
      ),
    );

    // LOG: cek apa yang dikirim ke server
    debugPrint('KIRIM model_name = $modelName, file = ${image.name}');

    final http.StreamedResponse response;
    final String responseBody;

    try {
      response = await request.send().timeout(const Duration(seconds: 30));
      responseBody = await response.stream.bytesToString();
    } catch (e) {
      throw Exception(
        'Tidak dapat terhubung ke server ($baseUrl). '
        'Pastikan backend sudah berjalan.\n$e',
      );
    }

    // LOG: cek jawaban mentah dari server
    debugPrint('STATUS = ${response.statusCode}');
    debugPrint('JAWABAN = $responseBody');

    dynamic result;
    try {
      result = jsonDecode(responseBody);
    } catch (_) {
      throw Exception(
        'Respons server tidak valid (status ${response.statusCode}).',
      );
    }

    if (response.statusCode == 200 && result is Map<String, dynamic>) {
      return result;
    }

    final detail = (result is Map) ? result['detail'] : null;

    throw Exception(
      detail?.toString() ?? 'Gagal melakukan deteksi',
    );
  }
}