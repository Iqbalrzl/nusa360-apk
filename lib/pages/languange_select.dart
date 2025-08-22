import 'package:flutter/material.dart';
import 'package:nusa360/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage>
    with SingleTickerProviderStateMixin {
  final List<String> languages = const ['Bahasa Indonesia', 'English'];
  String? selected;

  bool isOpen = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  void _toggleDropdown() {
    setState(() {
      isOpen = !isOpen;
      if (isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const creamBg = Color(0xFFF9F8F3);

    return Scaffold(
      backgroundColor: creamBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Dekorasi bawah
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

                            // Custom Dropdown seperti capture
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Label
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, bottom: 8),
                                  child: Text(
                                    'Select job role',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black54,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),

                                // Dropdown Container
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Main dropdown button
                                      GestureDetector(
                                        onTap: _toggleDropdown,
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  selected ?? "Pilih Bahasa",
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15,
                                                    color:
                                                        selected == null
                                                            ? Colors.black54
                                                            : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                isOpen
                                                    ? Icons.keyboard_arrow_up
                                                    : Icons.keyboard_arrow_down,
                                                color: Colors.black54,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Dropdown items
                                      SizeTransition(
                                        sizeFactor: _expandAnimation,
                                        axisAlignment: -1,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: BorderSide(
                                                color: Colors.grey.shade200,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            children:
                                                languages
                                                    .map(
                                                      (e) => GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            selected = e;
                                                            isOpen = false;
                                                            _controller
                                                                .reverse();
                                                          });
                                                        },
                                                        child: Container(
                                                          width:
                                                              double.infinity,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 16,
                                                                vertical: 12,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            border:
                                                                e !=
                                                                        languages
                                                                            .last
                                                                    ? Border(
                                                                      bottom: BorderSide(
                                                                        color:
                                                                            Colors.grey.shade100,
                                                                        width:
                                                                            0.5,
                                                                      ),
                                                                    )
                                                                    : null,
                                                          ),
                                                          child: Align(
                                                            alignment:
                                                                Alignment
                                                                    .centerLeft,
                                                            child: Text(
                                                              e,
                                                              style: const TextStyle(
                                                                fontFamily:
                                                                    'Inter',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 15,
                                                                color:
                                                                    Colors
                                                                        .black87,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Tombol lanjutkan
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
