import 'package:flutter/material.dart';

import 'detection_screen.dart';
import 'history_screen.dart';
import 'package:mango_detection/login_screen.dart'; // memakai warna (kBg, kPrimary, dst.) dan MangoLogo

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: logo + nama aplikasi
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(child: MangoLogo(size: 30)),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mango Detection',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: kText,
                        ),
                      ),
                      Text(
                        'Deteksi Kematangan Mangga',
                        style: TextStyle(color: kMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 35),

              const Text(
                'Selamat Datang!',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Kenali tingkat kematangan buah mangga dengan mudah menggunakan teknologi Computer Vision.',
                style: TextStyle(color: kMuted, fontSize: 14, height: 1.6),
              ),

              const SizedBox(height: 25),

              // Kartu utama
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deteksi Kematangan Mangga',
                      style: TextStyle(
                        color: kOnPrimary,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Upload atau ambil foto buah mangga untuk mengetahui tingkat kematangannya.',
                      style: TextStyle(
                        color: kOnPrimary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DetectionScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Mulai Deteksi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kText,
                        foregroundColor: kBg,
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 52),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Kategori Kematangan',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: categoryCard(
                      'Mentah',
                      'Hijau',
                      const Color(0xFF3F7D20),
                      Icons.eco,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: categoryCard(
                      'Matang',
                      'Kuning',
                      kPrimary,
                      Icons.wb_sunny,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: categoryCard(
                      'Lewat Matang',
                      'Cokelat',
                      const Color(0xFF7A4B2A),
                      Icons.warning_amber,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                'Menu Lainnya',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),

              const SizedBox(height: 15),

              menuButton(
                context,
                Icons.history,
                'Riwayat Deteksi',
                'Lihat hasil deteksi sebelumnya',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistoryScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              menuButton(
                context,
                Icons.info_outline,
                'Tentang Aplikasi',
                'Informasi sistem deteksi mangga',
                () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Mango Detection',
                    applicationVersion: '1.0.0',
                    children: const [
                      Text(
                        'Aplikasi untuk mendeteksi tingkat kematangan buah mangga menggunakan Computer Vision.',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget categoryCard(
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 29),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: kText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: kMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget menuButton(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: kLink, size: 27),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: kText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 15, color: kMuted),
          ],
        ),
      ),
    );
  }
}