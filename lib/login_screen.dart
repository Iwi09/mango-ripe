import 'package:flutter/material.dart';

import 'register_screen.dart';
import 'screens/home_screen.dart';

// ===== Warna =====
const kBg = Color(0xFFFFFBF0);
const kPrimary = Color(0xFFE8870E);
const kOnPrimary = Color(0xFF1F1500);
const kText = Color(0xFF2B2A1F);
const kMuted = Color(0xFF6B6650);
const kBorder = Color(0xFFD9CC9A);
const kLink = Color(0xFF9A4A00);
const kChip = Color(0xFFEFEAD4);
const kDivider = Color(0xFFEADFB8);
const kResultBg = Color(0xFFFCE9B2);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // TODO: ganti dengan autentikasi asli (Firebase Auth / API backend)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  InputDecoration _decoration(String hint, {Widget? suffix}) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: 1.5),
        );
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: border(kBorder),
      focusedBorder: border(kPrimary),
      errorBorder: border(Colors.red.shade700),
      focusedErrorBorder: border(Colors.red.shade700),
      suffixIcon: suffix,
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(
                    child: MangoLogo(size: 44),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Selamat datang',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                  'Masuk untuk mulai mendeteksi kematangan mangga',
                  style: TextStyle(fontSize: 15, color: kMuted),
                ),
                const SizedBox(height: 28),

                // Email
                _label('Email'),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration('nama@email.com'),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Email wajib diisi';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Kata sandi
                _label('Kata sandi'),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  decoration: _decoration(
                    'Masukkan kata sandi',
                    suffix: IconButton(
                      tooltip: _obscure ? 'Tampilkan' : 'Sembunyikan',
                      icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: halaman lupa kata sandi
                    },
                    child: const Text('Lupa kata sandi?',
                        style: TextStyle(
                            color: kLink, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 8),

                // Tombol Masuk
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: kOnPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: kOnPrimary),
                          )
                        : const Text('Masuk'),
                  ),
                ),
                const SizedBox(height: 16),

                // Pemisah
                const Row(
                  children: [
                    Expanded(child: Divider(color: kDivider)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('atau',
                          style: TextStyle(color: kMuted, fontSize: 13)),
                    ),
                    Expanded(child: Divider(color: kDivider)),
                  ],
                ),
                const SizedBox(height: 16),

                // Tamu
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: masuk sebagai tamu
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kChip,
                      foregroundColor: kText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Lanjutkan sebagai tamu'),
                  ),
                ),
                const SizedBox(height: 32),

                // Ke Register
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Belum punya akun? ',
                          style: TextStyle(fontSize: 15)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text('Daftar',
                            style: TextStyle(
                                fontSize: 15,
                                color: kLink,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Logo mangga (digambar dengan kode, tanpa file gambar) =====
class MangoLogo extends StatelessWidget {
  final double size;
  const MangoLogo({super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _MangoPainter());
  }
}

class _MangoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset p(double x, double y) => Offset(x * w, y * h);

    // Badan mangga
    final body = Path()
      ..moveTo(p(0.18, 0.34).dx, p(0.18, 0.34).dy)
      ..cubicTo(p(0.20, 0.16).dx, p(0.20, 0.16).dy, p(0.50, 0.12).dx,
          p(0.50, 0.12).dy, p(0.70, 0.30).dx, p(0.70, 0.30).dy)
      ..cubicTo(p(0.88, 0.46).dx, p(0.88, 0.46).dy, p(0.96, 0.70).dx,
          p(0.96, 0.70).dy, p(0.86, 0.84).dx, p(0.86, 0.84).dy)
      ..cubicTo(p(0.78, 0.94).dx, p(0.78, 0.94).dy, p(0.58, 0.90).dx,
          p(0.58, 0.90).dy, p(0.40, 0.80).dx, p(0.40, 0.80).dy)
      ..cubicTo(p(0.20, 0.68).dx, p(0.20, 0.68).dy, p(0.16, 0.50).dx,
          p(0.16, 0.50).dy, p(0.18, 0.34).dx, p(0.18, 0.34).dy)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFFFF3C4));

    // Daun
    final leaf = Path()
      ..moveTo(p(0.30, 0.20).dx, p(0.30, 0.20).dy)
      ..cubicTo(p(0.40, 0.04).dx, p(0.40, 0.04).dy, p(0.62, 0.02).dx,
          p(0.62, 0.02).dy, p(0.66, 0.04).dx, p(0.66, 0.04).dy)
      ..cubicTo(p(0.60, 0.18).dx, p(0.60, 0.18).dy, p(0.44, 0.24).dx,
          p(0.44, 0.24).dy, p(0.30, 0.20).dx, p(0.30, 0.20).dy)
      ..close();
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF3F7D20));

    // Tangkai
    canvas.drawLine(
      p(0.26, 0.28),
      p(0.30, 0.15),
      Paint()
        ..color = kOnPrimary
        ..strokeWidth = w * 0.07
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}