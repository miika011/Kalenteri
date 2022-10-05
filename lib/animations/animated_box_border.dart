import 'package:flutter/material.dart';

class AnimatedBoxBorder extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Border border1;
  final Border border2;
  final TickerProvider? _vsync;

  AnimatedBoxBorder({
    Key? key,
    required this.child,
    Duration? duration,
    Curve? curve,
    Border? border1,
    Border? border2,
    TickerProvider? vsync,
  })  : _vsync = vsync,
        border1 = border1 ??
            Border.all(color: const Color.fromARGB(255, 163, 247, 8), width: 1),
        border2 = border2 ?? Border.all(color: Colors.green, width: 2.5),
        curve = curve ?? Curves.easeInOut,
        duration = duration ?? const Duration(seconds: 1),
        super(key: key);

  @override
  State<AnimatedBoxBorder> createState() => _AnimatedBoxBorderState();
}

class _AnimatedBoxBorderState extends State<AnimatedBoxBorder>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation _animation;
  late final TickerProvider _vsync;

  @override
  void initState() {
    super.initState();
    _vsync = widget._vsync ?? this;

    _controller = AnimationController(
      vsync: _vsync,
      duration: widget.duration,
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          _controller.forward();
        } else if (status == AnimationStatus.completed) {
          _controller.reverse();
        }
      })
      ..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
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
      builder: (BuildContext context, Widget? child) {
        return Container(
          decoration: ShapeDecoration(
            shape:
                Border.lerp(widget.border1, widget.border2, _animation.value)!,
          ),
          child: widget.child,
        );
      },
    );
  }
}
