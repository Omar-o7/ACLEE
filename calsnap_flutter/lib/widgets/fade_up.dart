import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Staggered entrance: fade + rise, Apple-like easing.
/// Give each section an increasing [index] for a natural cascade.
class FadeUp extends StatefulWidget {
  final int index;
  final Widget child;
  const FadeUp({super.key, this.index = 0, required this.child});

  @override
  State<FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<FadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppMotion.entrance);
    final curve = CurvedAnimation(parent: _c, curve: AppMotion.easeOutExpo);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curve);
    _offset = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(curve);
    Future.delayed(AppMotion.staggerStep * widget.index, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
