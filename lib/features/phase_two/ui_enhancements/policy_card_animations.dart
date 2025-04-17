import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PolicyCardAnimations {
  static Widget applySelectAnimation(Widget child) {
    return child.animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    )
      .shimmer(
        duration: const Duration(seconds: 2),
        color: Colors.white.withOpacity(0.3),
        curve: Curves.easeInOutSine,
      )
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.05, 1.05),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
  }

  static Widget applyHoverAnimation(Widget child) {
    return child.animate(
      onPlay: (controller) => controller.forward(),
    )
      .elevation(
        begin: 2,
        end: 8,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      )
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.03, 1.03),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
  }

  static Widget applyDragAnimation(Widget child) {
    return child.animate()
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.1, 1.1),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      )
      .elevation(
        begin: 2,
        end: 12,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
  }

  static Widget applySuccessAnimation(Widget child) {
    return child.animate()
      .scale(
        begin: const Offset(1.0, 1.0),
        end: const Offset(1.1, 1.1),
        duration: const Duration(milliseconds: 200),
      )
      .then()
      .scale(
        begin: const Offset(1.1, 1.1),
        end: const Offset(1.0, 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.bounceOut,
      )
      .elevation(
        begin: 2,
        end: 0,
        duration: const Duration(milliseconds: 300),
      );
  }

  static Widget applyErrorAnimation(Widget child) {
    return child.animate()
      .shakeX(
        amount: 10,
        hz: 4,
        duration: const Duration(milliseconds: 500),
      )
      .elevation(
        begin: 8,
        end: 2,
        duration: const Duration(milliseconds: 300),
      );
  }

  static Widget applyFlipAnimation(Widget child, {required Widget backContent}) {
    return AnimatedFlipCard(
      frontContent: child,
      backContent: backContent,
    );
  }
}

class AnimatedFlipCard extends StatefulWidget {
  final Widget frontContent;
  final Widget backContent;

  const AnimatedFlipCard({
    super.key,
    required this.frontContent,
    required this.backContent,
  });

  @override
  State<AnimatedFlipCard> createState() => _AnimatedFlipCardState();
}

class _AnimatedFlipCardState extends State<AnimatedFlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFrontVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleCard() {
    if (_isFrontVisible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFrontVisible = !_isFrontVisible;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * 3.14159;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
          
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: angle < 1.57079
                ? widget.frontContent
                : Transform(
                    transform: Matrix4.identity()..rotateY(3.14159),
                    alignment: Alignment.center,
                    child: widget.backContent,
                  ),
          );
        },
      ),
    );
  }
}