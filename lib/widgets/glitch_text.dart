import 'package:flutter/material.dart';
import 'dart:math';


class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;

  const GlitchText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  String _displayText = '';
  final List<String> _glitchChars = [
    '█', '▓', '▒', '░', '▀', '▄', '■', '□',
    '!', '@', '#', '\$', '%', '^', '&', '*',
  ];

  @override
  void initState() {
    super.initState();
    _displayText = widget.text;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.addListener(_updateGlitch);
    _controller.repeat();
  }

  void _updateGlitch() {
    final progress = _controller.value;

    // Glitch at specific intervals
    if (progress < 0.1 ||
        (progress > 0.3 && progress < 0.35) ||
        (progress > 0.6 && progress < 0.65) ||
        (progress > 0.9 && progress < 0.92)) {
      setState(() {
        _displayText = _generateGlitchText();
      });
    } else {
      if (_displayText != widget.text) {
        setState(() {
          _displayText = widget.text;
        });
      }
    }
  }

  String _generateGlitchText() {
    final chars = widget.text.split('');
    final glitchedChars = <String>[];

    for (int i = 0; i < chars.length; i++) {
      // 30% chance to glitch each character
      if (_random.nextDouble() < 0.3) {
        glitchedChars.add(_glitchChars[_random.nextInt(_glitchChars.length)]);
      } else {
        glitchedChars.add(chars[i]);
      }
    }

    return glitchedChars.join();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 8,
      color: Theme.of(context).colorScheme.primary,
      shadows: [
        Shadow(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          blurRadius: 20,
        ),
        Shadow(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          blurRadius: 40,
          offset: const Offset(2, 2),
        ),
      ],
    );

    return Stack(
      children: [
        Positioned(
          left: -2,
          top: 0,
          child: Opacity(
            opacity: 0.3,
            child: Text(
              widget.text,
              style: (widget.style ?? defaultStyle)?.copyWith(
                color: Colors.cyan,
              ),
            ),
          ),
        ),
        Positioned(
          left: 2,
          top: 0,
          child: Opacity(
            opacity: 0.3,
            child: Text(
              widget.text,
              style: (widget.style ?? defaultStyle)?.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ),
        // Main text (with glitch effect)
        Text(
          _displayText,
          style: widget.style ?? defaultStyle,
        ),
      ],
    );
  }
}