import 'package:flutter/material.dart';

class AnimatedOverlayColor extends StatefulWidget {
  final Duration duration;
  final Curve curve;
  final Widget child;
  final Color color1;
  final Color color2;

  const AnimatedOverlayColor(
      {Key? key,
      required this.child,
      Duration? duration,
      Curve? curve,
      required this.color1,
      required this.color2})
      : curve = curve ?? Curves.easeInOut,
        duration = duration ?? const Duration(seconds: 1),
        super(key: key);

  @override
  State<AnimatedOverlayColor> createState() => _AnimatedOverlayColorState();
}

class _AnimatedOverlayColorState extends State<AnimatedOverlayColor>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation _animation;

  Color get color1 => widget.color1;
  Color get color2 => widget.color2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else {
        if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            widget.child,
            Container(
              color: Color.lerp(color1, color2, _animation.value),
            )
          ],
        );
      },
    );
  }
}
