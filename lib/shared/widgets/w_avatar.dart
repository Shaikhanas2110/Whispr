import 'package:flutter/material.dart';
import '../../app/theme.dart';

class WAvatar extends StatelessWidget {
  final String pseudonym;
  final int colorIndex;
  final double size;
  final bool isPremium;
  final bool showRing;

  const WAvatar({
    super.key,
    required this.pseudonym,
    required this.colorIndex,
    this.size = 36,
    this.isPremium = false,
    this.showRing = false,
  });

  Color get _color => WTheme.avatarColors[colorIndex % WTheme.avatarColors.length];
  String get _initials => pseudonym.length >= 2 ? pseudonym.substring(0, 2).toUpperCase() : pseudonym.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withOpacity(0.15),
        border: Border.all(
          color: showRing ? _color : _color.withOpacity(0.3),
          width: showRing ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: _color,
            fontSize: size * 0.3,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );

    if (!isPremium) return avatar;

    return Stack(
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: size * 0.35,
            height: size * 0.35,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: WTheme.purpleGradient,
            ),
            child: Center(
              child: Text('✦', style: TextStyle(fontSize: size * 0.18, color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}
