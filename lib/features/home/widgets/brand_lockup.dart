import 'package:flutter/material.dart';

class BrandLockup extends StatelessWidget {
  const BrandLockup({this.compact = false, this.splash = false, super.key});

  final bool compact;
  final bool splash;

  @override
  Widget build(BuildContext context) {
    if (splash) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.recycling_rounded, size: 126, color: Colors.white),
          SizedBox(height: 14),
          Text(
            'EcoRoute',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.recycling_rounded,
          size: compact ? 44 : 120,
          color: const Color(0xFF123B1A),
        ),
        const SizedBox(width: 10),
        Text(
          'EcoRoute',
          style: TextStyle(
            fontSize: compact ? 20 : 40,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF123B1A),
          ),
        ),
      ],
    );
  }
}

class ResponsiveButtonLabel extends StatelessWidget {
  const ResponsiveButtonLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class WelcomeIcon extends StatelessWidget {
  const WelcomeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFDCEFE0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.waving_hand_rounded, color: Color(0xFF2E7D32)),
    );
  }
}
