import 'package:flutter/material.dart';

/// Simple fade-in wrapper used to gently reveal content once available.
class FadeIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double begin;
  final double end;
  final Duration? delay;

  const FadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
    this.curve = Curves.easeOutCubic,
    this.begin = 0.0,
    this.end = 1.0,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    if (delay == null) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: begin, end: end),
        duration: duration,
        curve: curve,
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
        child: child,
      );
    }
    // Add a small FutureBuilder gate to start animation after delay.
    return FutureBuilder<void>(
      future: Future.delayed(delay!),
      builder: (context, snap) {
        final started = snap.connectionState == ConnectionState.done;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: begin, end: started ? end : begin),
          // Use shorter duration if still waiting to avoid layout hold.
          duration: duration,
          curve: curve,
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child),
          child: child,
        );
      },
    );
  }
}

/// AnimatedSwitcher preset with scale+fade (small scale delta) to unify transitions.
class ScaleFadeSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve inCurve;
  final Curve outCurve;
  final double minScale;

  const ScaleFadeSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 250),
    this.inCurve = Curves.easeOutCubic,
    this.outCurve = Curves.easeInCubic,
    this.minScale = 0.96,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: inCurve,
      switchOutCurve: outCurve,
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: inCurve,
          reverseCurve: outCurve,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: minScale, end: 1).animate(curved),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: child.key, child: child),
    );
  }
}
