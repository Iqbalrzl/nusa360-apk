import 'package:flutter/material.dart';
import 'stroke_text.dart';

class BrandHeader extends StatelessWidget {
  final double titleSize;
  final double subSize;
  const BrandHeader({super.key, this.titleSize = 36, this.subSize = 28});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFC84E4E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NUSA',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
            fontSize: titleSize,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        StrokeText(
          '360',
          fontSize: subSize,
          strokeColor: Colors.black,
          strokeWidth: 2.0,
          fillColor: Colors.white,
        ),
      ],
    );
  }
}
