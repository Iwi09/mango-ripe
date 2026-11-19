import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  String selectedModel = 'best_model';

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
      final response = await ApiService.predict(
        widget.image,
        selectedModel,
      );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Deteksi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(
                widget.imageBytes,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Pilih Algoritma',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: selectedModel,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'best_model',
                  child: Text('Model Terbaik'),
                ),
                DropdownMenuItem(
                  value: 'naive_bayes',
                  child: Text('Naive Bayes'),
                ),
                DropdownMenuItem(
                  value: 'svm',
                  child: Text('SVM'),
                ),
              ],
              onChanged: loading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          selectedModel = value;
                          result = null;
                          error = null;
                        });
                      }
                    },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loading ? null : detectMango,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF347A45),
                  foregroundColor: Colors.white,
                ),
                child: loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Mulai Deteksi'),
              ),
            ),

            const SizedBox(height: 20),

            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              ),

            if (result != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF347A45),
                      size: 45,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Hasil Klasifikasi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      result!['ripeness'].toString(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF347A45),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Algoritma: ${result!['model']}',
                    ),

                    if (result!['confidence'] != null)
                      Text(
                        'Confidence: ${NumberFormatHelper.format(result!['confidence'])}%',
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class NumberFormatHelper {
  static String format(dynamic value) {
    return (value as num).toStringAsFixed(2);
  }
}