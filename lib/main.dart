
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MangoApp());
}

class MangoApp extends StatelessWidget {
  const MangoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mango Detect',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F8F3),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  XFile? selectedImage;
  Uint8List? selectedImageBytes;

  final ImagePicker picker = ImagePicker();

  String metode = 'svm';
  String hasil = '';
  String status = '';

  bool loading = false;

  // Android Emulator menggunakan alamat khusus 10.0.2.2
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000';

  Future<void> pilihGambar(ImageSource source) async {
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() {
          selectedImage = image;
          selectedImageBytes = bytes;
          hasil = '';
          status = '';
        });
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka kamera: $error'),
        ),
      );
    }
  }

  Future<void> deteksiMangga() async {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih gambar mangga terlebih dahulu'),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
      hasil = '';
      status = '';
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict?metode=$metode'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          selectedImageBytes!,
          filename: selectedImage!.name,
        ),
      );

      var response = await request.send();

      var responseBody = await response.stream.bytesToString();

      var data = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        setState(() {
          hasil = data['hasil_prediksi'].toString();
          status = 'success';
        });
      } else {
        setState(() {
          status = data['detail']?.toString() ?? 'Prediksi gagal';
        });
      }
    } catch (e) {
      setState(() {
        status = 'Gagal menghubungkan ke server: $e';
      });
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mango Detect',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const Icon(
              Icons.eco,
              size: 65,
              color: Colors.green,
            ),

            const SizedBox(height: 10),

            const Text(
              'Deteksi Kematangan Mangga',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Pilih gambar buah mangga untuk mengetahui tingkat kematangannya.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 25),

            Container(
              height: 230,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.shade200),
              ),

              child: selectedImage == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 65,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text('Belum ada gambar mangga'),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.memory(
                        selectedImageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => pilihGambar(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => pilihGambar(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeri'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            const Text(
              'Pilih Metode Klasifikasi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: metode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),

              items: const [
                DropdownMenuItem(
                  value: 'svm',
                  child: Text('Support Vector Machine (SVM)'),
                ),
                DropdownMenuItem(
                  value: 'naive_bayes',
                  child: Text('Naive Bayes'),
                ),
              ],

              onChanged: (value) {
                setState(() {
                  metode = value!;
                  hasil = '';
                });
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: loading ? null : deteksiMangga,
                icon: const Icon(Icons.search),
                label: Text(
                  loading ? 'Sedang Mendeteksi...' : 'Deteksi Mangga',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 25),

            if (status == 'success')
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 45,
                      ),

                      const Text(
                        'Hasil Deteksi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        hasil,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),

                      Text('Metode: ${metode.toUpperCase()}'),
                    ],
                  ),
                ),
              ),

            if (status.isNotEmpty && status != 'success')
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
