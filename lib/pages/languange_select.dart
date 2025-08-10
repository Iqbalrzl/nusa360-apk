import 'package:flutter/material.dart';
import 'package:nusa360/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/brand_header.dart';
import '../widgets/decor_bottom_placeholder.dart';

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
    const primary = Color(0xFFC84E4E);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: 180,
                    child: DecorBottomPlaceholder(color: Color(0xB3C84E4E)),
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth;
                final contentW = maxW > 440 ? 420.0 : maxW * 0.9;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints.tightFor(width: contentW),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),
                          const BrandHeader(),
                          const SizedBox(height: 64),
                          const Text(
                            'PILIH\nBAHASA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<String>(
                              value: selected,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              hint: const Text('Pilih bahasa'),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items:
                                  languages
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (val) => setState(() => selected = val),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: selected == null ? null : _continue,
                              child: const Text(
                                'Lanjutkan',
                                style: TextStyle(fontWeight: FontWeight.w700),
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
          ],
        ),
      ),
    );
  }
}
