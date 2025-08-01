import 'package:flutter/material.dart';

enum SlideDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

class SlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;
  final Duration duration;
  final Curve curve;

  SlidePageRoute({
    required this.page,
    this.direction = SlideDirection.rightToLeft,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          settings: settings,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: _getSlideAnimation(animation, direction, curve),
              child: child,
            );
          },
        );

  static Animation<Offset> _getSlideAnimation(
    Animation<double> animation,
    SlideDirection direction,
    Curve curve,
  ) {
    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
    
    switch (direction) {
      case SlideDirection.leftToRight:
        return Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation);
      case SlideDirection.rightToLeft:
        return Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation);
      case SlideDirection.topToBottom:
        return Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        ).animate(curvedAnimation);
      case SlideDirection.bottomToTop:
        return Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(curvedAnimation);
    }
  }
}

class FadeSlidePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SlideDirection direction;
  final Duration duration;
  final Curve curve;

  FadeSlidePageRoute({
    required this.page,
    this.direction = SlideDirection.rightToLeft,
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeInOut,
    RouteSettings? settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          settings: settings,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = _getSlideAnimation(animation, direction, curve);
            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(parent: animation, curve: curve));

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );

  static Animation<Offset> _getSlideAnimation(
    Animation<double> animation,
    SlideDirection direction,
    Curve curve,
  ) {
    final curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
    
    switch (direction) {
      case SlideDirection.leftToRight:
        return Tween<Offset>(
          begin: const Offset(-0.3, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation);
      case SlideDirection.rightToLeft:
        return Tween<Offset>(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).animate(curvedAnimation);
      case SlideDirection.topToBottom:
        return Tween<Offset>(
          begin: const Offset(0.0, -0.3),
          end: Offset.zero,
        ).animate(curvedAnimation);
      case SlideDirection.bottomToTop:
        return Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(curvedAnimation);
    }
  }
}

// Navigation Helper Extensions
extension NavigationExtensions on BuildContext {
  // Slide navigation methods
  Future<T?> slideToPage<T>(
    Widget page, {
    SlideDirection direction = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return Navigator.push<T>(
      this,
      SlidePageRoute<T>(
        page: page,
        direction: direction,
        duration: duration,
        curve: curve,
      ),
    );
  }

  Future<T?> slideReplacePage<T>(
    Widget page, {
    SlideDirection direction = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return Navigator.pushReplacement<T, dynamic>(
      this,
      SlidePageRoute<T>(
        page: page,
        direction: direction,
        duration: duration,
        curve: curve,
      ),
    );
  }

  // Fade + Slide navigation methods
  Future<T?> fadeSlideToPage<T>(
    Widget page, {
    SlideDirection direction = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    return Navigator.push<T>(
      this,
      FadeSlidePageRoute<T>(
        page: page,
        direction: direction,
        duration: duration,
        curve: curve,
      ),
    );
  }

  Future<T?> fadeSlideReplacePage<T>(
    Widget page, {
    SlideDirection direction = SlideDirection.rightToLeft,
    Duration duration = const Duration(milliseconds: 350),
    Curve curve = Curves.easeInOut,
  }) {
    return Navigator.pushReplacement<T, dynamic>(
      this,
      FadeSlidePageRoute<T>(
        page: page,
        direction: direction,
        duration: duration,
        curve: curve,
      ),
    );
  }
}