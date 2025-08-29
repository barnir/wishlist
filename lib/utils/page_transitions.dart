import 'package:flutter/material.dart';

/// Custom page transitions for improved navigation experience
class CustomPageTransitions {
  /// Slide transition from right to left
  static Route<T> slideFromRight<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Slide transition from bottom to top
  static Route<T> slideFromBottom<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutExpo;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Fade transition with slight scale
  static Route<T> fadeWithScale<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutQuart;

        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        var scaleTween = Tween(begin: 0.95, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        );
      },
    );
  }

  /// Transição de página para Android
  static Route<T> adaptiveTransition<T extends Object?>(Widget page, BuildContext context) {
    // Usar transição otimizada para Android
    return fadeWithScale<T>(page);
  }

  /// Modal bottom sheet transition
  static Route<T> modalBottomSheet<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      opaque: false,
      barrierColor: Colors.black54,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var slideTween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
    );
  }
}

/// Extension methods for easy navigation with custom transitions
extension NavigatorStateExtensions on NavigatorState {
  /// Push with slide from right animation
  Future<T?> pushSlideRight<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.slideFromRight<T>(page));
  }

  /// Push with slide from bottom animation
  Future<T?> pushSlideBottom<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.slideFromBottom<T>(page));
  }

  /// Push with fade and scale animation
  Future<T?> pushFadeScale<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.fadeWithScale<T>(page));
  }

  /// Push with adaptive animation based on platform
  Future<T?> pushAdaptive<T extends Object?>(Widget page, BuildContext context) {
    return push<T>(CustomPageTransitions.adaptiveTransition<T>(page, context));
  }

  /// Push as modal bottom sheet
  Future<T?> pushModalBottomSheet<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.modalBottomSheet<T>(page));
  }
}

/// Extension methods for BuildContext navigation
extension BuildContextExtensions on BuildContext {
  /// Push with slide from right animation
  Future<T?> pushSlideRight<T extends Object?>(Widget page) {
    return Navigator.of(this).pushSlideRight<T>(page);
  }

  /// Push with slide from bottom animation
  Future<T?> pushSlideBottom<T extends Object?>(Widget page) {
    return Navigator.of(this).pushSlideBottom<T>(page);
  }

  /// Push with fade and scale animation
  Future<T?> pushFadeScale<T extends Object?>(Widget page) {
    return Navigator.of(this).pushFadeScale<T>(page);
  }

  /// Push with adaptive animation based on platform
  Future<T?> pushAdaptive<T extends Object?>(Widget page) {
    return Navigator.of(this).pushAdaptive<T>(page, this);
  }

  /// Push as modal bottom sheet
  Future<T?> pushModalBottomSheet<T extends Object?>(Widget page) {
    return Navigator.of(this).pushModalBottomSheet<T>(page);
  }
}