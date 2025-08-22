import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nusa360/services/nusa360_api.dart';
import '../models/destination.dart';
import '../widgets/glass_card.dart';

class DestinationDetailPage extends StatefulWidget {
  final Destination destination;
  const DestinationDetailPage({super.key, required this.destination});

  @override
  State<DestinationDetailPage> createState() => _DestinationDetailPageState();
}

class _DestinationDetailPageState extends State<DestinationDetailPage> {
  final apiService = ApiService();
  final _askCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _sheetController = DraggableScrollableController();

  bool _asking = false;
  String? _aiAnswer;
  String? _lastQuestion;

  // Sheet disembunyikan dahulu
  bool _showSheet = false;

  // Simpan nilai minChildSize untuk referensi listener
  static const double _minSheet = 0.20;

  late final VoidCallback _sheetListener;

  @override
  void initState() {
    super.initState();
    _sheetListener = () {
      if (!_sheetController.isAttached) return;
      final size = _sheetController.size;
      // Saat user swipe turun hingga ke min, sembunyikan sheet
      if (_showSheet && size <= _minSheet + 0.002) {
        // Hindari setState saat build: gunakan microtask
        scheduleMicrotask(() {
          if (mounted) _hideSheet();
        });
      }
    };
    _sheetController.addListener(_sheetListener);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_sheetListener);
    _sheetController.dispose(); // opsional, tapi disarankan
    _askCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  ({String name, String avatarEmoji, Color color}) _persona() {
    switch (widget.destination.id) {
      case 'toba-lake':
        return (
          name: 'Tara, Pemandu Batak',
          avatarEmoji: '🪶',
          color: const Color(0xFF3E8E7E),
        );
      case 'labuan-bajo':
        return (
          name: 'Jojo, Pemandu NTT',
          avatarEmoji: '🐉',
          color: const Color(0xFFB85745),
        );
      case 'raja-ampat':
        return (
          name: 'Waigeo Guide',
          avatarEmoji: '🐠',
          color: const Color(0xFF2F6D8C),
        );
      case 'borobudur':
        return (
          name: 'Maya, Heritage Guide',
          avatarEmoji: '🛕',
          color: const Color(0xFF7A5E3A),
        );
      default:
        return (
          name: 'NusaAI Guide',
          avatarEmoji: '🧭',
          color: const Color(0xFF6C63FF),
        );
    }
  }

  List<String> _suggestions() {
    final name = widget.destination.name;
    final region = widget.destination.region;
    final base = <String>[
      'Sejarah singkat $name',
      'Itinerary 2 hari di $name',
      'Kuliner khas di $region',
      'Rute menuju $name dari Jakarta',
      'Waktu terbaik berkunjung ke $name',
    ];
    if (_lastQuestion != null) {
      base.add('Ada alternatif lain terkait "${_lastQuestion!}"?');
      base.add('Perkiraan biaya untuk ${_lastQuestion!}');
    }
    return base;
  }

  Future<void> _ensureSheetAndSnap(double size) async {
    if (!_showSheet) {
      setState(() => _showSheet = true);
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    if (_sheetController.isAttached) {
      unawaited(
        _sheetController.animateTo(
          size,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  Future<void> _hideSheet() async {
    if (_sheetController.isAttached) {
      try {
        await _sheetController.animateTo(
          _minSheet,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        );
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _showSheet = false);
    }
  }

  Future<void> _askAi([String? predefined]) async {
    final q = predefined ?? _askCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _asking = true;
      _aiAnswer = null;
      _lastQuestion = q;
    });
    try {
      final ctx = '${widget.destination.name}, ${widget.destination.region}';
      final res = await apiService.askAi(q, ctx);
      setState(() {
        _aiAnswer = res ?? 'Maaf, saya belum bisa menemukan jawaban.';
      });
      await _ensureSheetAndSnap(0.62);
    } catch (e) {
      setState(() {
        _aiAnswer = 'Terjadi kesalahan. Coba lagi.';
      });
      await _ensureSheetAndSnap(0.62);
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFFC84E4E);

    return Scaffold(
      body: Stack(
        children: [
          // Background gambar destinasi
          Positioned.fill(
            child:
                widget.destination.imageUrl == null
                    ? Container(color: primary.withOpacity(0.25))
                    : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.destination.imageUrl!,
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                        // Gradient untuk keterbacaan teks
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x99000000),
                                Color(0x33000000),
                                Color(0x99000000),
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
          ),

          // Konten atas: back, judul besar, ask bubble, tombol AR
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ), // batas biar ga mepet
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button merah bulat
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFC84E4E),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Judul besar (destinasi)
                  Text(
                    '${widget.destination.name},\n${widget.destination.region}',
                    style: const TextStyle(
                      fontSize: 34,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Input Tanya AI
                  Center(
                    child: Container(
                      height: 46,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _askCtrl,
                              focusNode: _focusNode,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _askAi(),
                              decoration: const InputDecoration(
                                hintText: 'Tanya AI...',
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _askAi(),
                            icon: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Tombol AR + Selengkapnya
                  Center(
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mode AR segera hadir'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC84E4E),
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 14,
                            ),
                          ),
                          child: const Text(
                            'Mode AR',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () => _ensureSheetAndSnap(0.62),
                          child: const Text(
                            'Selengkapnya',
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RENDER SHEET (tanpa NotificationListener)
          if (_showSheet)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.28,
              minChildSize: _minSheet,
              maxChildSize: 0.92,
              snap: true,
              snapSizes: const [0.28, 0.62, 0.92],
              builder: (context, scrollController) {
                final persona = _persona();
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: GlassCard(
                    borderRadius: 28,
                    blur: 16,
                    tint: Colors.white.withOpacity(0.65),
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onVerticalDragUpdate: (details) {
                            if (_sheetController.isAttached) {
                              final newSize =
                                  _sheetController.size -
                                  details.primaryDelta! /
                                      MediaQuery.of(context).size.height;
                              _sheetController.jumpTo(
                                newSize.clamp(_minSheet, 0.92),
                              );
                            }
                          },
                          onVerticalDragEnd: (details) {
                            if ((details.primaryVelocity ?? 0) > 250) {
                              _hideSheet();
                            }
                          },
                          child: Container(
                            width: 64,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.08),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            children: [
                              const _SectionHeader(title: 'Deskripsi'),
                              const SizedBox(height: 8),
                              Text(
                                _descFor(widget.destination),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  height: 1.45,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 22),
                              if (_aiAnswer != null || _asking) ...[
                                const _SectionHeader(title: 'Hasil'),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _PersonaAvatar(persona: persona),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child:
                                          _asking
                                              ? const _TypingBubble()
                                              : Text(
                                                _aiAnswer ?? '',
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  height: 1.5,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                              ],
                              const _SectionHeader(title: 'Tanyakan juga'),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _suggestions()
                                        .map(
                                          (s) => ActionChip(
                                            backgroundColor: Colors.white,
                                            side: BorderSide(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                            ),
                                            label: Text(s),
                                            onPressed: () => _askAi(s),
                                          ),
                                        )
                                        .toList(),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  _PersonaAvatar(persona: persona, small: true),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Dijawab oleh ${persona.name}',
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _descFor(Destination d) {
    if (d.id == 'toba-lake') {
      return 'Danau Toba di Sumatera Utara adalah danau vulkanik terbesar di Asia Tenggara, '
          'terkenal akan panorama alamnya dan budaya Batak. Pulau Samosir terletak di tengah danau. '
          'Destinasi ini populer untuk menikmati pemandangan, budaya, dan sejarah geologinya.';
    }
    if (d.id == 'labuan-bajo') {
      return 'Labuan Bajo merupakan gerbang menuju Taman Nasional Komodo dengan gugusan pulau yang eksotis. '
          'Snorkeling, trekking ke padang savana, dan menyaksikan matahari terbenam adalah agenda favorit.';
    }
    if (d.id == 'raja-ampat') {
      return 'Raja Ampat dikenal sebagai surga bawah laut dengan keanekaragaman hayati yang menakjubkan. '
          'Cocok untuk penyelaman, snorkeling, dan fotografi alam.';
    }
    if (d.id == 'borobudur') {
      return 'Candi Borobudur, warisan dunia UNESCO, merupakan monumen Buddha megah dengan relief yang kaya makna. '
          'Waktu terbaik untuk berkunjung adalah saat matahari terbit.';
    }
    return 'Destinasi populer di Indonesia dengan kekayaan budaya dan alam.';
  }
}

// --- Komponen pendukung tetap sama di bawah ini ---
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1.2, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }
}

class _PersonaAvatar extends StatelessWidget {
  final ({String name, String avatarEmoji, Color color}) persona;
  final bool small;
  const _PersonaAvatar({required this.persona, this.small = false});
  @override
  Widget build(BuildContext context) {
    final size = small ? 28.0 : 44.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            persona.color.withOpacity(0.9),
            persona.color.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: persona.color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          persona.avatarEmoji,
          style: TextStyle(fontSize: small ? 14 : 20),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.6, end: 1.0)
                .chain(
                  CurveTween(
                    curve: Interval(i * 0.2, 1.0, curve: Curves.easeInOut),
                  ),
                )
                .animate(_controller),
            child: const CircleAvatar(
              radius: 4,
              backgroundColor: Colors.black54,
            ),
          ),
        );
      }),
    );
  }
}
