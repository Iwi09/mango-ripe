import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../login_screen.dart'; // memakai warna (kBg, kPrimary, dst.)
import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  final XFile image;
  final Uint8List imageBytes;

  const ResultScreen({
    super.key,
    required this.image,
    required this.imageBytes,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  static const String modelName = 'svm';

  bool loading = false;

  Map<String, dynamic>? result;

  String? error;

  Future<void> detectMango() async {
    setState(() {
      loading = true;
      error = null;
      result = null;
    });

    try {
      // Cek di Debug Console: nilai ini yang dikirim ke ApiService
      debugPrint('MODEL DIPILIH: $modelName');

      final response = await ApiService.predict(
        widget.image,
        modelName,
      );

      // Lihat isi respons server di Debug Console
      debugPrint('RESPON SERVER: $response');

      if (!mounted) return;

      setState(() {
        result = response;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // Mengambil nilai dari respons server, mencoba beberapa kemungkinan nama kunci.
  dynamic _ambil(List<String> keys) {
    if (result == null) return null;
    for (final k in keys) {
      final v = result![k];
      if (v != null) return v;
    }
    return null;
  }

  // Mengambil persentase keyakinan untuk kelas yang diprediksi.
  // Server mengirim "probabilitas" berupa Map, misalnya {OverRipe: 0.64, ...}
  String? _teksConfidence(String label) {
    final data = _ambil(['confidence', 'probabilitas', 'skor']);

    if (data is num) return data.toStringAsFixed(2);

    if (data is Map) {
      final nilai = data[label];
      if (nilai is num) return nilai.toStringAsFixed(2);
    }

    return null;
  }

  Color _warnaHasil(String label) {
    final l = label.toLowerCase();
    if (l.contains('mentah') || l.contains('unripe')) {
      return const Color(0xFF3F7D20);
    }
    if (l.contains('lewat') || l.contains('over')) {
      return const Color(0xFF7A4B2A);
    }
    return kLink; // matang
  }

  Widget _kartuHasil() {
    final ripeness = _ambil(
        ['ripeness', 'hasil_prediksi', 'hasil', 'prediction', 'label', 'kelas']);
    final model = _ambil(['model', 'metode', 'algoritma']);

    // Kunci tidak dikenali: tampilkan pesan + isi respons agar mudah dicek
    if (ripeness == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Hasil tidak ditemukan di respons server.\n\nIsi respons:\n$result',
          style: TextStyle(color: Colors.red.shade800),
        ),
      );
    }

    final label = ripeness.toString();
    final confidence = _teksConfidence(label);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kResultBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Klasifikasi',
            style: TextStyle(fontSize: 13, color: kMuted),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: _warnaHasil(label),
            ),
          ),
          const SizedBox(height: 8),
          if (model != null)
            Text(
              'Algoritma: $model',
              style: const TextStyle(fontSize: 14, color: kText),
            ),
          if (confidence != null)
            Text(
              'Confidence: $confidence%',
              style: const TextStyle(fontSize: 14, color: kText),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: kText),
        title: const Text(
          'Hasil Deteksi',
          style: TextStyle(fontWeight: FontWeight.w700, color: kText),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.memory(
                widget.imageBytes,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Algoritma yang digunakan: SVM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : detectMango,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: kOnPrimary,
                  disabledBackgroundColor: kChip,
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: kOnPrimary,
                        ),
                      )
                    : const Text('Mulai Deteksi'),
              ),
            ),

            const SizedBox(height: 20),

            if (error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  error!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),

            if (result != null) _kartuHasil(),
          ],
        ),
      ),
    );
  }
}
