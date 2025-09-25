import 'package:flutter/material.dart';

/// Custom page transitions for improved navigation experience
class CustomPageTransitions {
  /// Optimized slide transition from right to left
  /// Enhanced for smoother performance and reduced visual glitches
  static Route<T> slideFromRight<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(
        milliseconds: 280,
      ), // Slightly faster for smoother feel
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;

        // Use easeOutCubic for more natural deceleration
        final slideAnimation = animation.drive(
          Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        );

        // Add subtle fade for smoother visual transition
        final fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
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

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  /// Optimized fade transition with scale - perfect for profile screens
  /// Reduces visual glitches and provides smooth user experience
  static Route<T> fadeWithScale<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 250), // Optimized timing
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Different curves for fade and scale for more natural motion
        final fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        );

        final scaleAnimation = animation.drive(
          Tween(
            begin: 0.92,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(scale: scaleAnimation, child: child),
        );
      },
    );
  }

  /// Optimized search transition - minimal motion for better search UX
  /// Designed to reduce visual distractions during search interactions
  static Route<T> searchTransition<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(
        milliseconds: 200,
      ), // Fast for responsiveness
      reverseTransitionDuration: const Duration(milliseconds: 150),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Subtle slide up with quick fade - less jarring for search
        const begin = Offset(0.0, 0.03); // Very minimal slide
        const end = Offset.zero;

        final slideAnimation = animation.drive(
          Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeOutQuart)),
        );

        final fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  /// Transição de página para Android
  static Route<T> adaptiveTransition<T extends Object?>(
    Widget page,
    BuildContext context,
  ) {
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

        var slideTween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var fadeTween = Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut));

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

  /// Push with search optimized animation
  Future<T?> pushSearch<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.searchTransition<T>(page));
  }

  /// Push with adaptive animation based on platform
  Future<T?> pushAdaptive<T extends Object?>(
    Widget page,
    BuildContext context,
  ) {
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

  /// Push with search optimized animation
  Future<T?> pushSearch<T extends Object?>(Widget page) {
    return Navigator.of(this).pushSearch<T>(page);
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
