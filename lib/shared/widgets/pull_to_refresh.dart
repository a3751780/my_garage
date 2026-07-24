import 'dart:math' as math;

import 'package:flutter/material.dart';

class PullToRefresh extends StatefulWidget {
  const PullToRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.triggerDistance = 82,
    this.maxIndicatorExtent = 72,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double triggerDistance;
  final double maxIndicatorExtent;

  @override
  State<PullToRefresh> createState() => _PullToRefreshState();
}

class _PullToRefreshState extends State<PullToRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _resetController;
  Animation<double>? _resetAnimation;
  double _pullExtent = 0;
  bool _isAtTop = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
        final animation = _resetAnimation;

        if (animation == null) {
          return;
        }

        setState(() => _pullExtent = animation.value);
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indicatorExtent = math.min(_pullExtent, widget.maxIndicatorExtent);
    final progress = (_pullExtent / widget.triggerDistance).clamp(0.0, 1.0);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Listener(
        onPointerMove: _handlePointerMove,
        onPointerUp: (_) => _settle(),
        onPointerCancel: (_) => _settle(),
        child: Stack(
          children: [
            widget.child,
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: indicatorExtent,
              child: IgnorePointer(
                child: Opacity(
                  opacity: _isRefreshing ? 1 : progress,
                  child: _PullIndicator(
                    progress: progress,
                    isRefreshing: _isRefreshing,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    _isAtTop = notification.metrics.extentBefore <= 0 &&
        notification.metrics.pixels <= notification.metrics.minScrollExtent;
    return false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_isRefreshing) {
      return;
    }

    final delta = event.delta.dy;

    if (delta > 0 && _isAtTop) {
      _resetController.stop();
      setState(() {
        _pullExtent = math.min(
          widget.triggerDistance * 1.35,
          _pullExtent + delta * 0.72,
        );
      });
      return;
    }

    if (delta < 0 && _pullExtent > 0) {
      _resetController.stop();
      setState(() {
        _pullExtent = math.max(0, _pullExtent + delta);
      });
    }
  }

  Future<void> _settle() async {
    if (_isRefreshing) {
      return;
    }

    if (_pullExtent < widget.triggerDistance) {
      _animatePullExtentTo(0);
      return;
    }

    setState(() {
      _isRefreshing = true;
      _pullExtent = widget.maxIndicatorExtent;
    });

    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
        _animatePullExtentTo(0);
      }
    }
  }

  void _animatePullExtentTo(double target) {
    _resetAnimation = Tween<double>(
      begin: _pullExtent,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _resetController,
        curve: Curves.easeOutCubic,
      ),
    );
    _resetController
      ..reset()
      ..forward();
  }
}

class _PullIndicator extends StatelessWidget {
  const _PullIndicator({
    required this.progress,
    required this.isRefreshing,
  });

  final double progress;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 42,
        height: 42,
        margin: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            value: isRefreshing ? null : progress,
          ),
        ),
      ),
    );
  }
}
