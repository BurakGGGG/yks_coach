import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const quick = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 280);
  static const emphasized = Duration(milliseconds: 420);

  static const enterCurve = Curves.easeOutCubic;
  static const exitCurve = Curves.easeInCubic;

  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.maybeOf(context)?.disableAnimations == true
      ? Duration.zero
      : value;
}

class SurfaceCard extends StatefulWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.border = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool border;

  @override
  State<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends State<SurfaceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedScale(
      scale: _pressed && !reduceMotion ? .975 : 1,
      duration: reduceMotion ? Duration.zero : AppMotion.quick,
      curve: AppMotion.enterCurve,
      child: RepaintBoundary(
        child: Material(
          color: scheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: widget.border
                ? BorderSide(color: scheme.outlineVariant)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: widget.onTap == null
                ? null
                : (value) => setState(() => _pressed = value),
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    );
  }
}

class PagePadding extends StatelessWidget {
  const PagePadding({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: AnimatedEntrance(child: child),
    );
  }
}

class AnimatedEntrance extends StatefulWidget {
  const AnimatedEntrance({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration delay;

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.emphasized,
    );
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fade = curve;
    _slide = Tween(
      begin: const Offset(0, .035),
      end: Offset.zero,
    ).animate(curve);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: Tween(begin: .992, end: 1.0).animate(_fade),
          child: widget.child,
        ),
      ),
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    required this.value,
    this.color,
    this.backgroundColor,
    this.minHeight = 8,
    super.key,
  });

  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0, 1)),
      duration: AppMotion.duration(context, const Duration(milliseconds: 650)),
      curve: AppMotion.enterCurve,
      builder: (context, animatedValue, _) => LinearProgressIndicator(
        value: animatedValue,
        minHeight: minHeight,
        borderRadius: BorderRadius.circular(99),
        color: color,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: AppMotion.emphasized,
        reverseTransitionDuration: AppMotion.standard,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppMotion.enterCurve,
            reverseCurve: AppMotion.exitCurve,
          );
          final secondaryCurved = CurvedAnimation(
            parent: secondaryAnimation,
            curve: AppMotion.enterCurve,
            reverseCurve: AppMotion.exitCurve,
          );
          return SlideTransition(
            position: Tween(
              begin: Offset.zero,
              end: const Offset(-.025, 0),
            ).animate(secondaryCurved),
            child: FadeTransition(
              opacity: Tween(begin: 0.92, end: 1.0).animate(curved),
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(.055, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: ScaleTransition(
                  scale: Tween(begin: .985, end: 1.0).animate(curved),
                  child: RepaintBoundary(child: child),
                ),
              ),
            ),
          );
        },
      );
}

class AppSnack {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }
}
