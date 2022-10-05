import 'package:flutter/material.dart';

class AnimatedOverlayColor extends StatefulWidget {
  final Duration duration;
  final Curve curve;
  final Widget child;
  final Color color1;
  final Color color2;
  final TickerProvider? _vsync;

  const AnimatedOverlayColor({
    Key? key,
    required this.child,
    required this.color1,
    required this.color2,
    TickerProvider? vsync,
    Duration? duration,
    Curve? curve,
  })  : _vsync = vsync,
        curve = curve ?? Curves.easeInOut,
        duration = duration ?? const Duration(seconds: 1),
        super(key: key);

  @override
  State<AnimatedOverlayColor> createState() => _AnimatedOverlayColorState();
}

class _AnimatedOverlayColorState extends State<AnimatedOverlayColor>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation _animation;
  late final TickerProvider _vsync;

  Color get color1 => widget.color1;
  Color get color2 => widget.color2;

  @override
  void initState() {
    super.initState();
    _vsync = widget._vsync ?? this;
    _controller = AnimationController(vsync: _vsync, duration: widget.duration);
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
              color: Color.lerp(
                color1,
                color2,
                _animation.value,
              ),
            )
          ],
        );
      },
    );
  }
}
