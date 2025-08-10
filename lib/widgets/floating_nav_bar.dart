import 'package:flutter/material.dart';

class FloatingNavBar extends StatelessWidget {
  final VoidCallback onAiTap;
  final VoidCallback onHomeTap;
  final VoidCallback onProfileTap;
  final int currentIndex;

  const FloatingNavBar({
    super.key,
    required this.onAiTap,
    required this.onHomeTap,
    required this.onProfileTap,
    this.currentIndex = 1, // 0: AI, 1: Home, 2: Profile
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFC84E4E);
    final inactive = primary.withOpacity(0.55);

    Widget item(IconData icon, int index, VoidCallback onTap) {
      final active = currentIndex == index;
      return InkResponse(
        onTap: onTap,
        radius: 28,
        child: Icon(icon, size: 26, color: active ? primary : inactive),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item(Icons.grid_view_rounded, 0, onAiTap),
          const SizedBox(width: 36),
          item(Icons.home_rounded, 1, onHomeTap),
          const SizedBox(width: 36),
          item(Icons.account_circle_rounded, 2, onProfileTap),
        ],
      ),
    );
  }
}
