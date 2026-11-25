import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../login_screen.dart'; // memakai warna (kBg, kPrimary, dst.)
import 'result_screen.dart';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  final ImagePicker picker = ImagePicker();
  XFile? image;
  Uint8List? imageBytes;

  Future<void> pickImage(ImageSource source) async {
    try {
      // PERBAIKAN: imageQuality dihapus supaya gambar TIDAK dikompres ulang.
      // Fitur HSV sensitif terhadap perubahan warna, jadi gambar yang dikirim
      // ke backend harus sama dengan gambar aslinya.
      final XFile? selectedImage = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (selectedImage != null) {
        final bytes = await selectedImage.readAsBytes();
        if (!mounted) return;
        setState(() {
          image = selectedImage;
          imageBytes = bytes;
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
          'Deteksi Mangga',
          style: TextStyle(fontWeight: FontWeight.w700, color: kText),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Gambar Mangga',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Pilih gambar buah mangga yang ingin diperiksa tingkat kematangannya.',
              style: TextStyle(color: kMuted, height: 1.5),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kBorder, width: 1.5),
                ),
                child: image == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 75,
                            color: kPrimary,
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Belum ada gambar dipilih',
                            style: TextStyle(color: kMuted),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.memory(
                          imageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Ambil Foto'),
              style: buttonStyle(),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Pilih dari Galeri'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                foregroundColor: kLink,
                side: const BorderSide(color: kBorder, width: 1.5),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: image == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ResultScreen(
                            image: image!,
                            imageBytes: imageBytes!,
                          ),
                        ),
                      );
                    },
              style: buttonStyle(),
              child: const Text('Deteksi Kematangan'),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: kPrimary,
      foregroundColor: kOnPrimary,
      disabledBackgroundColor: kChip,
      disabledForegroundColor: kMuted,
      elevation: 0,
      minimumSize: const Size(double.infinity, 52),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}