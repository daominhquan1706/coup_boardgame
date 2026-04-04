part of '../page.dart';

const Duration _kTapMotion = Duration(milliseconds: 120);
const Duration _kEmphasisMotion = Duration(milliseconds: 260);
const Duration _kCoinMotion = Duration(milliseconds: 720);
const Duration _kFlipMotion = Duration(milliseconds: 620);

class _GamePressable extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _GamePressable({
    required this.onTap,
    required this.child,
  });

  @override
  State<_GamePressable> createState() => _GamePressableState();
}

class _GamePressableState extends State<_GamePressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: _kTapMotion,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _AnimatedCoinValue extends StatefulWidget {
  final int coins;
  final Alignment deltaAlignment;
  final Offset deltaTravel;
  final Widget Function(BuildContext context, int displayCoins, double emphasisScale) builder;

  const _AnimatedCoinValue({
    required this.coins,
    required this.deltaAlignment,
    required this.deltaTravel,
    required this.builder,
  });

  @override
  State<_AnimatedCoinValue> createState() => _AnimatedCoinValueState();
}

class _AnimatedCoinValueState extends State<_AnimatedCoinValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _emphasisScale;
  int _fromCoins = 0;
  int _displayVersion = 0;
  int? _delta;
  Timer? _deltaTimer;

  @override
  void initState() {
    super.initState();
    _fromCoins = widget.coins;
    _controller = AnimationController(vsync: this, duration: _kCoinMotion);
    _emphasisScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.14).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.14, end: 1.0).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 58,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant _AnimatedCoinValue oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.coins == widget.coins) return;

    _fromCoins = oldWidget.coins;
    _displayVersion += 1;
    _delta = widget.coins - oldWidget.coins;
    _controller.forward(from: 0);
    _deltaTimer?.cancel();
    _deltaTimer = Timer(_kCoinMotion, () {
      if (!mounted) return;
      setState(() {
        _delta = null;
      });
    });
    setState(() {});
  }

  @override
  void dispose() {
    _deltaTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delta = _delta;
    final deltaColor = delta == null || delta == 0
        ? _kGold
        : delta.isNegative
            ? const Color(0xFFFB7185)
            : const Color(0xFF4ADE80);

    return Stack(
      clipBehavior: Clip.none,
      alignment: widget.deltaAlignment,
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey('coins-${widget.coins}-$_displayVersion'),
          tween: Tween(begin: _fromCoins.toDouble(), end: widget.coins.toDouble()),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return AnimatedBuilder(
              animation: _emphasisScale,
              builder: (context, child) {
                return widget.builder(context, value.round(), _emphasisScale.value);
              },
            );
          },
        ),
        if (delta != null && delta != 0)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final opacity = (1 - (_controller.value * 1.15)).clamp(0.0, 1.0);
              final travel = Offset(
                widget.deltaTravel.dx * _controller.value,
                widget.deltaTravel.dy * _controller.value,
              );

              return IgnorePointer(
                child: Opacity(
                  opacity: opacity,
                  child: Transform.translate(
                    offset: travel,
                    child: Text(
                      '${delta > 0 ? '+' : ''}$delta',
                      style: TextStyle(
                        color: deltaColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _AnimatedTurnAvatar extends StatefulWidget {
  final bool isCurrentTurn;
  final double size;
  final Widget child;

  const _AnimatedTurnAvatar({
    required this.isCurrentTurn,
    required this.size,
    required this.child,
  });

  @override
  State<_AnimatedTurnAvatar> createState() => _AnimatedTurnAvatarState();
}

class _AnimatedTurnAvatarState extends State<_AnimatedTurnAvatar> {
  double _burst = 0.0;

  @override
  void initState() {
    super.initState();
    _burst = widget.isCurrentTurn ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(covariant _AnimatedTurnAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCurrentTurn == widget.isCurrentTurn) return;
    setState(() {
      _burst = widget.isCurrentTurn ? 1.0 : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: _burst),
      duration: _kEmphasisMotion,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final glowOpacity = widget.isCurrentTurn ? (0.16 + (0.28 * value)) : 0.0;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            IgnorePointer(
              child: Container(
                width: widget.size + 14 + (8 * value),
                height: widget.size + 14 + (8 * value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kGold.withValues(alpha: glowOpacity * 0.78),
                    width: 1.6,
                  ),
                  boxShadow: widget.isCurrentTurn
                      ? [
                          BoxShadow(
                            color: _kGold.withValues(alpha: glowOpacity),
                            blurRadius: 18 + (10 * value),
                            spreadRadius: 1 + (2 * value),
                          ),
                        ]
                      : const [],
                ),
              ),
            ),
            Transform.scale(
              scale: 1 + (0.03 * value),
              child: child,
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _AnimatedInfluenceMarker extends StatefulWidget {
  final CoupCardModel? card;
  final bool compact;
  final double? markerHeight;

  const _AnimatedInfluenceMarker({
    required this.card,
    required this.compact,
    this.markerHeight,
  });

  @override
  State<_AnimatedInfluenceMarker> createState() => _AnimatedInfluenceMarkerState();
}

class _AnimatedInfluenceMarkerState extends State<_AnimatedInfluenceMarker>
    with SingleTickerProviderStateMixin {
  static const double _miniAspectRatio = 64 / 92;
  late final AnimationController _controller;

  bool get _revealed => widget.card?.isRevealed ?? false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _kFlipMotion);
    if (_revealed) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedInfluenceMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasRevealed = oldWidget.card?.isRevealed ?? false;
    if (!wasRevealed && _revealed) {
      _controller.forward(from: 0);
      return;
    }
    if (!_revealed) {
      _controller.value = 0;
      return;
    }
    _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildMiniCard({
    required double width,
    required double height,
    required Widget child,
  }) {
    final radius = (height * 0.11).clamp(4.5, 9.0);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: FittedBox(
          fit: BoxFit.fill,
          child: IgnorePointer(child: child),
        ),
      ),
    );
  }

  Widget _buildBack(double width, double height) {
    final useSmallCard = height <= 34;

    return _buildMiniCard(
      width: width,
      height: height,
      child: CardWidget(isHidden: true, small: useSmallCard),
    );
  }

  Widget _buildFront(double width, double height) {
    final useSmallCard = height <= 34;

    return _buildMiniCard(
      width: width,
      height: height,
      child: CardWidget(
        roleType: widget.card?.roleType,
        small: useSmallCard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.markerHeight ?? (widget.compact ? 24.0 : 28.0);
    final width = height * _miniAspectRatio;

    if (!_revealed && _controller.isDismissed) {
      return _buildBack(width, height);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final angle = math.pi * progress;
        final showFront = angle >= math.pi / 2;
        final adjustedAngle = showFront ? angle - math.pi : angle;
        final pop = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(adjustedAngle),
          child: Transform.scale(
            scale: 0.94 + (0.1 * pop),
            child: showFront ? _buildFront(width, height) : _buildBack(width, height),
          ),
        );
      },
    );
  }
}
