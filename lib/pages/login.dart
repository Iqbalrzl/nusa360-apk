import 'package:flutter/material.dart';
import 'package:nusa360/pages/landing_pages.dart';
import 'package:nusa360/pages/register.dart';
import 'package:nusa360/services/nusa360_api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final apiService = ApiService();
  final _usernameOrEmailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _usernameOrEmailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final res = await apiService.login(
      _usernameOrEmailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (res != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login berhasil')));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingPage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login gagal')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8F3), // krem seperti UI referensi
      body: SafeArea(
        child: Stack(
          children: [
            // Dekorasi bawah seperti contoh UI
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/motif.png',
                fit: BoxFit.cover,
                height: 180,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo atas
                    Image.asset(
                      'assets/logo.png',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'Logo tidak ditemukan',
                          style: TextStyle(color: Colors.red),
                        );
                      },
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      'MASUK',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Form tetap, hanya gaya input yang disesuaikan
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameOrEmailCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: 'email',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.isEmpty)
                                        ? 'Wajib diisi'
                                        : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              hintText: 'kata sandi',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                ),
                              ),
                              suffixIcon: IconButton(
                                onPressed:
                                    () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator:
                                (v) =>
                                    (v == null || v.length < 4)
                                        ? 'Minimal 4 karakter'
                                        : null,
                          ),
                          const SizedBox(height: 20),

                          // Tombol sesuai UI: merah, pill, full width
                          SizedBox(
                            width: double.infinity,
                            height: 48, // sedikit lebih tinggi, tetap selaras
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC44B4B),
                                minimumSize: const Size(
                                  double.infinity,
                                  45,
                                ), // referensi
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child:
                                  _loading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Tautan ke register, gaya sesuai UI
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            child: const Text.rich(
                              TextSpan(
                                text: "Belum punya akun? ",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'klik disini',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
