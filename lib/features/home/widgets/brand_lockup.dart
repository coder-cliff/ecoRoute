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
        Container(
          width: compact ? 32 : 56,
          height: compact ? 32 : 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF0D2618),
              width: 1.6,
            ),
          ),
          child: Center(
            child: Icon(
              Icons.eco_outlined,
              size: compact ? 18 : 30,
              color: const Color(0xFF0D2618),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'EcoRoute',
          style: TextStyle(
            fontSize: compact ? 22 : 36,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0D2618),
            letterSpacing: -0.3,
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
      width: 58,
      height: 58,
      decoration: const BoxDecoration(
        color: Color(0x1F0D2618),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.waving_hand_rounded, color: Color(0xFF0D2618), size: 28),
    );
  }
}
