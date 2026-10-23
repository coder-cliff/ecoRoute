import 'package:flutter/material.dart';

class BrandLockup extends StatelessWidget {
  const BrandLockup({this.compact = false, this.splash = false, super.key});

  final bool compact;
  final bool splash;

  @override
  Widget build(BuildContext context) {
    if (splash) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/EcoRoute_logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.recycling_rounded,
                size: 120,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'EcoRoute',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(compact ? 8 : 18),
          child: Image.asset(
            'assets/EcoRoute_logo.png',
            width: compact ? 34 : 70,
            height: compact ? 34 : 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.recycling_rounded,
              size: compact ? 34 : 70,
              color: const Color(0xFF123B1A),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'EcoRoute',
          style: TextStyle(
            fontSize: compact ? 20 : 36,
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
