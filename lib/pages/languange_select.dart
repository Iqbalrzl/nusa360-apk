import 'package:flutter/material.dart';
import 'package:nusa360/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  final List<String> languages = const ['Bahasa Indonesia', 'English'];
  String? selected;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selected_language');
    if (saved != null && mounted) {
      setState(() => selected = saved);
    }
  }

  Future<void> _continue() async {
    if (selected == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', selected!);
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    const creamBg = Color(0xFFF9F8F3); // latar krem sesuai LoginPage

    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Dekorasi gambar bawah seperti di LoginPage
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

            // Konten utama
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final contentW = maxW > 440 ? 420.0 : maxW * 0.9;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints.tightFor(width: contentW),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo seperti di LoginPage
                            const SizedBox(height: 24),
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
                              'PILIH\nBAHASA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                fontFamily: 'Inter',
                                height: 1.2,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Dropdown bergaya seperti input di LoginPage (border hitam, pill)
                            DropdownButtonFormField<String>(
                              value: selected,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.black,
                              ),
                              hint: const Text(
                                'Pilih Bahasa',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
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
                              style: const TextStyle(
                                color: Colors.black87,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                              ),
                              items:
                                  languages
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                          value: e,
                                          child: Text(
                                            e,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (val) => setState(() => selected = val),
                            ),

                            const SizedBox(height: 20),

                            // Tombol 'Lanjutkan' seperti di LoginPage (merah, pill, full width)
                            SizedBox(
                              width: double.infinity,
                              height: 45,
                              child: ElevatedButton(
                                onPressed: selected == null ? null : _continue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC44B4B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  minimumSize: const Size(double.infinity, 45),
                                ),
                                child: const Text(
                                  'Lanjutkan',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
