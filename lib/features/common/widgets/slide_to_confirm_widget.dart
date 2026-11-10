import 'package:flutter/material.dart';

/// Tactile, field-safe slider widget to prevent accidental taps in vibrating environments
class SlideToConfirmWidget extends StatefulWidget {
  const SlideToConfirmWidget({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.icon = Icons.arrow_forward_rounded,
    this.sliderColor = const Color(0xFF1E5E3A),
    this.backgroundColor = const Color(0xFFE8ECE7),
    this.textColor = const Color(0xFF0D2618),
    this.height = 56.0,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onConfirmed;
  final IconData icon;
  final Color sliderColor;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final bool isLoading;

  @override
  State<SlideToConfirmWidget> createState() => _SlideToConfirmWidgetState();
}

class _SlideToConfirmWidgetState extends State<SlideToConfirmWidget> {
  double _dragPosition = 0.0;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - widget.height;

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(color: widget.sliderColor.withOpacity(0.3), width: 1.5),
          ),
          child: Stack(
            children: [
              // Background Centered Text
              Center(
                child: widget.isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: widget.sliderColor),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              color: widget.textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),

              // Drag Thumb
              if (!widget.isLoading)
                Positioned(
                  left: _dragPosition,
                  top: 2,
                  bottom: 2,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (_confirmed) return;
                      setState(() {
                        _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_confirmed) return;
                      if (_dragPosition >= maxDrag * 0.8) {
                        setState(() {
                          _dragPosition = maxDrag;
                          _confirmed = true;
                        });
                        widget.onConfirmed();
                      } else {
                        setState(() {
                          _dragPosition = 0.0;
                        });
                      }
                    },
                    child: Container(
                      width: widget.height - 4,
                      height: widget.height - 4,
                      decoration: BoxDecoration(
                        color: widget.sliderColor,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _confirmed ? Icons.check : widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
