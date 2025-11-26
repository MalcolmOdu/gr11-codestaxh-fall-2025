import 'package:flutter/material.dart';

class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration normal = Duration(milliseconds: 300);

  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOut;

  static Widget fadeIn ({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: duration ?? normal,
        builder: (context, value, child) {
          return Opacity(opacity: value, child: child);
        },
      child: child,
    );
  }

  static Widget slideInFromBottom({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 50.0, end: 0.0),
        duration: duration ?? normal,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0.0, value),
            child: Opacity(opacity: 1 - (value/90), child: child),
          );
        },
      child: child,
    );
  }

  static Widget scaleIn({
    required Widget child,
    Duration? duration,
    Curve? curve,
  }) {
    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: duration ?? normal,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: child,
    );
  }
}