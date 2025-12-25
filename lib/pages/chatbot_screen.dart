import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:nusa360/services/nusa360_api.dart';
import 'package:nusa360/services/websocket.dart';

// =====================================
// NusaAI Palette (natural gold update)
// =====================================
class NusaPalette {
  static const primary = Color(0xFFC44B4B); // Merah bata
  static const bone = Color(0xFFF9F8F3); // Putih tulang
  static const gold = Color(0xFFC5A880); // Natural gold (lebih blend-in)
  static const green = Color(0xFF4F6C42); // Hijau tua
  static const greyDark = Color(0xFF333333);
  static const greyLight = Color(0xFFDDDDDD);
}

// =====================================
// Message types to integrate content
// =====================================
enum ChatContent { text, suggestions, card }

class DestinationCardData {
  final String title;
  final String location;
  final String imageUrl;
  final String description;

  const DestinationCardData({
    required this.title,
    required this.location,
    required this.imageUrl,
    required this.description,
  });
}

// Kompatibel (mutable text untuk streaming)
class ChatMessage {
  String text;
  final bool isUser;

  // Extended: suggestions & cards di dalam chat
  final ChatContent content;
  final List<String>? suggestions;
  final DestinationCardData? card;
  bool isStreaming;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.content = ChatContent.text,
    this.suggestions,
    this.card,
    this.isStreaming = false,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final WebSocketService _webSocketService = WebSocketService();
  final _apiService = ApiService();

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isStreaming = false;

  String? _avatarUrl;

  @override
  void initState() {
    super.initState();

    // Muat avatar user
    _loadAvatar();

    // Koneksi WebSocket + streaming token
    _webSocketService.connect(
      onMessage: (message) {
        setState(() {
          if (message == "[END_OF_STREAM]") {
            _isStreaming = false;
            if (_messages.isNotEmpty && !_messages.last.isUser) {
              _messages.last.isStreaming = false;
            }
          } else {
            if (_isStreaming &&
                _messages.isNotEmpty &&
                !_messages.last.isUser) {
              _messages.last.text += message; // append token
              _messages.last.isStreaming = true;
            } else {
              _messages.add(
                ChatMessage(
                  text: message,
                  isUser: false,
                  content: ChatContent.text,
                  isStreaming: true,
                ),
              );
              _isStreaming = true;
            }
          }
        });
        _scrollToLatest();
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _injectWelcome();
      _scrollToLatest();
    });
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadAvatar() async {
    final avatarUrl = await _apiService.getAvatarUrl();
    if (avatarUrl != null) {
      setState(() {
        _avatarUrl =
            '$avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}'; // cache-bust
      });
    }
  }

  // =====================================
  // Welcome + Suggestions + Cards
  // =====================================
  void _injectWelcome() {
    if (_messages.isNotEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          text:
              "Selamat datang! Saya NusaAI, maestro budaya Indonesia. Siap menemani Anda menjelajahi keindahan nusantara—dari sejarah, filosofi adat, bahasa daerah, hingga rekomendasi destinasi budaya.",
          isUser: false,
          content: ChatContent.text,
        ),
      );
      _messages.add(
        ChatMessage(
          text: "",
          isUser: false,
          content: ChatContent.suggestions,
          suggestions: [
            "Ke mana enaknya liburan budaya?",
            "Cerita filosofi adat Batak",
            "Itinerary 3 hari: Yogyakarta budaya",
            "Ucapan salam dalam bahasa daerah",
          ],
        ),
      );
    });
  }

  void _injectDestinationCards() {
    final cards = <DestinationCardData>[
      const DestinationCardData(
        title: "Danau Toba",
        location: "Sumatra Utara",
        imageUrl:
            "http://103.63.25.133:8080/opt/nusa360/uploads/public/toba.png",
        description:
            "Rumah suku Batak. Filosofi 'Dalihan Na Tolu' menjadi pilar relasi sosial: somba marhula-hula, manat mardongan tubu, elek marboru.",
      ),
      const DestinationCardData(
        title: "Labuan Bajo",
        location: "Nusa Tenggara Timur",
        imageUrl:
            "http://103.63.25.133:8080/opt/nusa360/uploads/public/bajo.png",
        description:
            "Gerbang menuju Taman Nasional Komodo. Budaya lokal memadukan kearifan bahari dan tradisi tenun ikat yang khas.",
      ),
      const DestinationCardData(
        title: "Candi Borobudur",
        location: "Magelang, Jawa Tengah",
        imageUrl:
            "http://103.63.25.133:8080/opt/nusa360/uploads/public/borobudur.png",
        description:
            "Warisan Buddha abad ke-8. Reliefnya memuat kisah moral dan filosofi hidup; sunrise dari puncak jadi pengalaman sakral.",
      ),
    ];

    setState(() {
      for (final c in cards) {
        _messages.add(
          ChatMessage(
            text: "",
            isUser: false,
            content: ChatContent.card,
            card: c,
          ),
        );
      }
    });
    _scrollToLatest();
  }

  // =====================================
  // Sending & Scrolling
  // =====================================
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, content: ChatContent.text),
      );
      _messages.add(
        ChatMessage(
          text: "",
          isUser: false,
          content: ChatContent.text,
          isStreaming: true,
        ),
      );
      _isStreaming = true;
    });

    _webSocketService.sendQuestion(text);
    _controller.clear();
    _scrollToLatest();
  }

  void _sendPrecomposed(String text) {
    _controller.text = text;
    _sendMessage();
  }

  void _onSuggestionTapped(String s) {
    if (s.toLowerCase().contains("ke mana") ||
        s.toLowerCase().contains("liburan")) {
      setState(() {
        _messages.add(
          ChatMessage(text: s, isUser: true, content: ChatContent.text),
        );
      });
      _injectDestinationCards();
      return;
    }
    _sendPrecomposed(s);
  }

  void _scrollToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0.0, // reverse: paling bawah
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _copyText(String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Teks disalin')));
  }

  // =====================================
  // UI
  // =====================================
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: NusaPalette.bone,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _GlassAppBar(
          isTyping: _isStreaming,
          onBack: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          avatarUrl: _avatarUrl,
        ),
      ),
      body: Stack(
        children: [
          const _GlowBackground(),
          // Full-screen glass veil untuk efek frosted yang kuat
          const _FullGlassOverlay(),
          Column(
            children: [
              Expanded(
                child:
                    _messages.isEmpty
                        ? const SizedBox.shrink()
                        : ListView.builder(
                          controller: _scroll,
                          reverse: true,
                          padding: EdgeInsets.fromLTRB(
                            12,
                            12,
                            12,
                            12 + bottomInset,
                          ),

                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[_messages.length - 1 - index];
                            switch (msg.content) {
                              case ChatContent.text:
                                final prev =
                                    index > 0
                                        ? _messages[_messages.length -
                                            1 -
                                            (index - 1)]
                                        : null;
                                final showAvatar =
                                    prev == null || prev.isUser != msg.isUser;
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _ChatBubble(
                                      message: msg,
                                      showAvatar: showAvatar,
                                      onCopy: () => _copyText(msg.text),
                                      userAvatarUrl: _avatarUrl,
                                    ),
                                    if (msg.isStreaming && !msg.isUser)
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          left: 56.0,
                                          top: 6.0,
                                        ),
                                        child: _TypingIndicator(),
                                      ),
                                  ],
                                );
                              case ChatContent.suggestions:
                                return _SuggestionBubble(
                                  suggestions: msg.suggestions ?? const [],
                                  onTap: _onSuggestionTapped,
                                );
                              case ChatContent.card:
                                if (msg.card == null)
                                  return const SizedBox.shrink();
                                return _DestinationCard(
                                  data: msg.card!,
                                  onLearnMore:
                                      () => _sendPrecomposed(
                                        "Ceritakan lebih detail tentang ${msg.card!.title}—sejarah, filosofi, adat, dan bahasa daerah setempat.",
                                      ),
                                );
                            }
                          },
                        ),
              ),
              _Composer(controller: _controller, onSend: _sendMessage),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ],
      ),
    );
  }
}

// =====================================
// Full-screen glass overlay (iOS-like)
// =====================================
class _FullGlassOverlay extends StatelessWidget {
  const _FullGlassOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(color: Colors.white.withOpacity(0.10)),
        ),
      ),
    );
  }
}

// =====================================
// Glass AppBar dengan Back Button & User Avatar
// =====================================
class _GlassAppBar extends StatelessWidget {
  final bool isTyping;
  final VoidCallback onBack;
  final String? avatarUrl;
  const _GlassAppBar({
    required this.isTyping,
    required this.onBack,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              border: Border.all(color: Colors.white.withOpacity(0.65)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    _GlassCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: onBack,
                    ),
                    const SizedBox(width: 8),
                    // Avatar NusaAI (ikon/gradien)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Colors.white, NusaPalette.primary],
                              radius: 0.9,
                            ),
                          ),
                        ),
                        const Icon(Icons.temple_buddhist, color: Colors.white),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "NusaAI",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: NusaPalette.greyDark,
                            ),
                          ),
                          Text(
                            isTyping
                                ? "Mengetik..."
                                : "Maestro Budaya Indonesia",
                            style: TextStyle(
                              color: NusaPalette.greyDark.withOpacity(0.7),
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar user (foto jika ada)
                    _UserAvatarChip(avatarUrl: avatarUrl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatarChip extends StatelessWidget {
  final String? avatarUrl;
  const _UserAvatarChip({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: NusaPalette.primary,
        backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
        onBackgroundImageError:
            hasImage
                ? (_, __) {
                  // noop fallback ke ikon
                }
                : null,
        child:
            hasImage
                ? null
                : const Icon(Icons.person, size: 18, color: Colors.white),
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  const _GlassCircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = NusaPalette.greyDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withOpacity(0.5),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, size: 18, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================
// Background glows (lampu)
// =====================================
class _GlowBackground extends StatelessWidget {
  const _GlowBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Soft vertical wash
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [NusaPalette.bone, Color(0xFFFFFAF4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Primary glow (top-left)
        Positioned(
          top: -90,
          left: -70,
          child: _GlowCircle(
            size: 260,
            color: NusaPalette.primary.withOpacity(0.28),
          ),
        ),
        // Natural gold glow (top-right)
        Positioned(
          top: -40,
          right: -60,
          child: _GlowCircle(
            size: 220,
            color: NusaPalette.gold.withOpacity(0.26),
          ),
        ),
        // Green glow (bottom-right)
        Positioned(
          bottom: -110,
          right: -60,
          child: _GlowCircle(
            size: 300,
            color: NusaPalette.green.withOpacity(0.22),
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
          radius: 0.8,
        ),
      ),
    );
  }
}

// =====================================
// Chat bubbles
// =====================================
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;
  final VoidCallback onCopy;
  final String? userAvatarUrl;

  const _ChatBubble({
    required this.message,
    required this.showAvatar,
    required this.onCopy,
    required this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    final avatar =
        isUser
            ? _UserAvatarChip(avatarUrl: userAvatarUrl)
            : CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: NusaPalette.primary,
              ),
            );

    final bubble =
        isUser
            ? _UserBubble(child: _bubbleText(message.text, isUser))
            : _AIBubble(child: _bubbleText(message.text, isUser));

    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isUser ? 64 : 12,
        right: isUser ? 12 : 64,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser && showAvatar)
            avatar
          else if (!isUser)
            const SizedBox(width: 32),
          const SizedBox(width: 8),
          Flexible(child: GestureDetector(onLongPress: onCopy, child: bubble)),
          const SizedBox(width: 8),
          if (isUser && showAvatar)
            avatar
          else if (isUser)
            const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _bubbleText(String text, bool isUser) {
    return SelectableText(
      text.isEmpty ? ' ' : text,
      style: TextStyle(
        color: isUser ? NusaPalette.greyDark : Colors.white,
        height: 1.38,
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _AIBubble extends StatelessWidget {
  final Widget child;
  const _AIBubble({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: NusaPalette.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(
            color: NusaPalette.primary.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _UserBubble extends StatelessWidget {
  final Widget child;
  const _UserBubble({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(6),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: NusaPalette.greyLight.withOpacity(0.75),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// =====================================
// Suggestions bubble (chips) — pakai natural gold
// =====================================
class _SuggestionBubble extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onTap;
  const _SuggestionBubble({required this.suggestions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final maxWidth =
        MediaQuery.of(context).size.width - 24; // padding global ListView
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  border: Border.all(color: Colors.white.withOpacity(0.65)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      suggestions
                          .map(
                            (s) => _ChipButton(label: s, onTap: () => onTap(s)),
                          )
                          .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ChipButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NusaPalette.gold.withOpacity(0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: NusaPalette.gold),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: NusaPalette.greyDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================
// Destination Card (in-chat)
// =====================================
class _DestinationCard extends StatelessWidget {
  final DestinationCardData data;
  final VoidCallback onLearnMore;
  const _DestinationCard({required this.data, required this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    final maxWidth =
        MediaQuery.of(context).size.width - 24; // padding global ListView

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      child: Align(
        alignment: Alignment.centerLeft,

        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  border: Border.all(color: Colors.white.withOpacity(0.65)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          data.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: NusaPalette.greyLight,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image,
                                  color: NusaPalette.greyDark,
                                ),
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: NusaPalette.greyDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.place,
                                size: 16,
                                color: NusaPalette.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data.location,
                                style: TextStyle(
                                  color: NusaPalette.greyDark.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data.description,
                            style: TextStyle(
                              color: NusaPalette.greyDark.withOpacity(0.9),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _CardButton(
                                label: "Pelajari Lebih Lanjut",
                                icon: Icons.travel_explore,
                                onTap: onLearnMore,
                              ),
                              const SizedBox(width: 8),
                              _CardButton(
                                label: "Lihat Itinerary",
                                icon: Icons.map_outlined,
                                onTap: () => onLearnMore(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _CardButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NusaPalette.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: NusaPalette.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: NusaPalette.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================
// Composer (glass input) — ikon pakai natural gold
// =====================================
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                border: Border.all(color: Colors.white.withOpacity(0.65)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.tips_and_updates_rounded, size: 20),
                    color: NusaPalette.gold,
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: const InputDecoration(
                        hintText: "Balas ke NusaAI...",
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(color: NusaPalette.greyDark),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.attach_file_rounded, size: 20),
                    color: NusaPalette.gold,
                    onPressed: () {},
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.photo_camera_outlined, size: 20),
                    color: NusaPalette.gold,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 40,
                    width: 40,
                    child: ElevatedButton(
                      onPressed: onSend,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                        elevation: 0,
                        backgroundColor: NusaPalette.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================
// Typing indicator
// =====================================
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _anims = List.generate(
      3,
      (i) => CurvedAnimation(
        parent: _c,
        curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _dot(Animation<double> anim) {
    return ScaleTransition(
      scale: Tween(begin: 0.6, end: 1.0).animate(anim),
      child: Container(
        width: 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: const BoxDecoration(
          color: NusaPalette.greyDark,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: _anims.map(_dot).toList());
  }
}
