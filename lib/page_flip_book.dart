import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// One open book spread. The left and right pages can be any widgets.
@immutable
class BookSpread {
  const BookSpread({required this.left, required this.right});

  final Widget left;
  final Widget right;
}

/// Imperative controls for a [PageFlipBook].
///
/// Keep one controller in the owner State and pass it to the widget. Calls are
/// ignored while a turn is in progress or when the requested spread is absent.
class PageFlipController {
  _PageFlipBookState? _state;

  Future<void> next() => _state?._turn(1) ?? Future<void>.value();
  Future<void> previous() => _state?._turn(-1) ?? Future<void>.value();

  /// Jumps without animation, useful for a table of contents or page picker.
  void jumpTo(int spreadIndex) => _state?._jumpTo(spreadIndex);

  bool get isAnimating => _state?._isBusy ?? false;

  void dispose() => _state = null;

  void _attach(_PageFlipBookState state) => _state = state;
  void _detach(_PageFlipBookState state) {
    if (identical(_state, state)) _state = null;
  }
}

/// A reusable two-page book with a curled, shaded single-sheet page turn.
///
/// `spreads` holds arbitrary page content. A forward turn keeps the current
/// left page in place, turns the current right page, shows the next spread's
/// left page on the sheet's reverse, and reveals its right page underneath.
/// Pages are live widgets at rest and become image textures during a turn.
/// Give the book finite width and height, such as inside an Expanded or SizedBox.
class PageFlipBook extends StatefulWidget {
  const PageFlipBook({
    super.key,
    required this.spreads,
    required this.currentIndex,
    this.controller,
    this.onPageChanged,
    this.reverse = false,
    this.duration = const Duration(milliseconds: 760),
  });

  final List<BookSpread> spreads;
  final int currentIndex;
  final PageFlipController? controller;
  final ValueChanged<int>? onPageChanged;

  /// When true, the outer left corner advances and the outer right corner goes back.
  final bool reverse;
  final Duration duration;

  @override
  State<PageFlipBook> createState() => _PageFlipBookState();
}

class _PageFlipBookState extends State<PageFlipBook>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final CurvedAnimation _progress;
  int _revision = 0;
  int _index = 0;
  int _direction = 0;
  bool _isTurning = false;
  bool _isCapturing = false;
  ui.Image? _frontImage;
  ui.Image? _backImage;
  List<GlobalKey> _leftPageKeys = [];
  List<GlobalKey> _rightPageKeys = [];

  bool get _isBusy => _isTurning || _isCapturing;

  @override
  void initState() {
    super.initState();
    _index = _clampIndex(widget.currentIndex);
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progress = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    widget.controller?._attach(this);
  }

  @override
  void didUpdateWidget(covariant PageFlipBook oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.duration != widget.duration) {
      _animationController.duration = widget.duration;
    }
    if (oldWidget.currentIndex != widget.currentIndex ||
        oldWidget.spreads.length != widget.spreads.length ||
        oldWidget.reverse != widget.reverse) {
      _revision++;
      _animationController.stop(canceled: true);
      _releaseImages();
      _isTurning = false;
      _isCapturing = false;
      _index = _clampIndex(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _frontImage?.dispose();
    _backImage?.dispose();
    _progress.dispose();
    _animationController.dispose();
    super.dispose();
  }

  int _clampIndex(int value) {
    if (widget.spreads.isEmpty) return 0;
    return value.clamp(0, widget.spreads.length - 1);
  }

  Future<void> _turn(int direction) async {
    if (_isBusy || widget.spreads.isEmpty) return;
    final destination = _index + direction;
    if (destination < 0 || destination >= widget.spreads.length) return;

    final revision = _revision;
    if (MediaQuery.disableAnimationsOf(context)) {
      _jumpTo(destination);
      return;
    }
    setState(() => _isCapturing = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || revision != _revision) return;
    final fromRight = (direction > 0) != widget.reverse;
    final frontKey = fromRight ? _rightPageKeys[_index] : _leftPageKeys[_index];
    final backKey = fromRight
        ? _leftPageKeys[destination]
        : _rightPageKeys[destination];
    final frontImage = await _snapshot(frontKey);
    if (!mounted || revision != _revision) {
      frontImage?.dispose();
      return;
    }
    final backImage = await _snapshot(backKey);
    if (!mounted || revision != _revision) {
      frontImage?.dispose();
      backImage?.dispose();
      return;
    }
    if (frontImage == null || backImage == null) {
      frontImage?.dispose();
      backImage?.dispose();
      setState(() => _isCapturing = false);
      return;
    }

    setState(() {
      _frontImage = frontImage;
      _backImage = backImage;
      _isCapturing = false;
      _direction = direction;
      _isTurning = true;
    });
    _animationController.value = 0;
    try {
      await _animationController.forward().orCancel;
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;

    setState(() {
      _index = destination;
      _direction = 0;
      _isTurning = false;
      _frontImage = null;
      _backImage = null;
    });
    _animationController.reset();
    widget.onPageChanged?.call(destination);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      frontImage.dispose();
      backImage.dispose();
    });
  }

  Future<ui.Image?> _snapshot(GlobalKey key) async {
    final pageContext = key.currentContext;
    final renderObject = pageContext?.findRenderObject();
    if (pageContext == null ||
        renderObject is! RenderRepaintBoundary ||
        renderObject.size.isEmpty) {
      return null;
    }
    final pixelRatio = MediaQuery.devicePixelRatioOf(
      pageContext,
    ).clamp(1.0, 2.0);
    try {
      return await renderObject.toImage(pixelRatio: pixelRatio);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'page_flip_book',
          context: ErrorDescription('while capturing a page for a turn'),
        ),
      );
      return null;
    }
  }

  void _releaseImages() {
    final front = _frontImage;
    final back = _backImage;
    _frontImage = null;
    _backImage = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      front?.dispose();
      back?.dispose();
    });
  }

  Widget _paper(Widget content) =>
      ColoredBox(color: const Color(0xFFFFFDF5), child: content);

  Widget _capturePage(
    int index,
    bool left,
    double width,
    double spineWidth,
  ) => Positioned(
    left: left ? 0 : width + spineWidth,
    top: 0,
    bottom: 0,
    width: width,
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: Opacity(
          // A nonzero alpha ensures the boundary paints for toImage(). The
          // opaque live paper above this layer keeps it out of the visible book.
          opacity: .02,
          child: RepaintBoundary(
            key: left ? _leftPageKeys[index] : _rightPageKeys[index],
            child: _paper(
              left ? widget.spreads[index].left : widget.spreads[index].right,
            ),
          ),
        ),
      ),
    ),
  );

  void _jumpTo(int index) {
    if (_isBusy) return;
    final destination = _clampIndex(index);
    if (destination == _index) return;
    setState(() => _index = destination);
    widget.onPageChanged?.call(destination);
  }

  Future<void> _activateOuterCorner({required bool isRight}) {
    final forward = widget.reverse ? !isRight : isRight;
    return _turn(forward ? 1 : -1);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.spreads.isEmpty) return const SizedBox.shrink();
    while (_leftPageKeys.length < widget.spreads.length) {
      _leftPageKeys.add(GlobalKey());
      _rightPageKeys.add(GlobalKey());
    }
    if (_leftPageKeys.length > widget.spreads.length) {
      _leftPageKeys = _leftPageKeys.take(widget.spreads.length).toList();
      _rightPageKeys = _rightPageKeys.take(widget.spreads.length).toList();
    }

    final progress = _progress;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF263A2B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332C332B),
            blurRadius: 25,
            offset: Offset(0, 13),
          ),
          BoxShadow(color: Color(0xFF17251B), blurRadius: 0, spreadRadius: 1),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spineWidth = (constraints.maxWidth * .014).clamp(8.0, 16.0);
            final pageWidth = (constraints.maxWidth - spineWidth) / 2;
            final current = _index;
            final fromRight = (_direction > 0) != widget.reverse;
            final turningRight = _isTurning && fromRight;
            final turningLeft = _isTurning && !fromRight;
            final destination = current + _direction;

            final baseLeft = turningLeft
                ? widget.spreads[destination].left
                : widget.spreads[current].left;
            final baseRight = turningRight
                ? widget.spreads[destination].right
                : widget.spreads[current].right;
            final leftPageIndex = turningLeft ? destination : current;
            final rightPageIndex = turningRight ? destination : current;

            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                if (!_isTurning) ...[
                  if (current > 0)
                    _capturePage(
                      current - 1,
                      widget.reverse,
                      pageWidth,
                      spineWidth,
                    ),
                  if (current + 1 < widget.spreads.length)
                    _capturePage(
                      current + 1,
                      !widget.reverse,
                      pageWidth,
                      spineWidth,
                    ),
                ],
                Row(
                  children: [
                    SizedBox(
                      width: pageWidth,
                      child: RepaintBoundary(
                        key: _leftPageKeys[leftPageIndex],
                        child: _paper(baseLeft),
                      ),
                    ),
                    SizedBox(
                      width: spineWidth,
                      child: _FlipBookSpine(height: constraints.maxHeight),
                    ),
                    SizedBox(
                      width: pageWidth,
                      child: RepaintBoundary(
                        key: _rightPageKeys[rightPageIndex],
                        child: _paper(baseRight),
                      ),
                    ),
                  ],
                ),
                if (_isTurning)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: progress,
                        builder: (context, _) => CustomPaint(
                          painter: _WarpedPagePainter(
                            frontImage: _frontImage!,
                            backImage: _backImage!,
                            progress: progress.value,
                            fromRight: fromRight,
                            pageWidth: pageWidth,
                            spineWidth: spineWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!_isBusy) ...[
                  _cornerTarget(
                    isRight: !widget.reverse,
                    top: true,
                    pageWidth: pageWidth,
                    action: () =>
                        _activateOuterCorner(isRight: !widget.reverse),
                  ),
                  _cornerTarget(
                    isRight: !widget.reverse,
                    top: false,
                    pageWidth: pageWidth,
                    action: () =>
                        _activateOuterCorner(isRight: !widget.reverse),
                  ),
                  _cornerTarget(
                    isRight: widget.reverse,
                    top: true,
                    pageWidth: pageWidth,
                    action: () => _activateOuterCorner(isRight: widget.reverse),
                  ),
                  _cornerTarget(
                    isRight: widget.reverse,
                    top: false,
                    pageWidth: pageWidth,
                    action: () => _activateOuterCorner(isRight: widget.reverse),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cornerTarget({
    required bool isRight,
    required bool top,
    required double pageWidth,
    required VoidCallback action,
  }) {
    final canAdvance = widget.reverse ? !isRight : isRight;
    final available = canAdvance
        ? _index < widget.spreads.length - 1
        : _index > 0;
    if (!available) return const SizedBox.shrink();

    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: isRight ? null : 0,
      right: isRight ? 0 : null,
      width: 54,
      height: 54,
      child: Semantics(
        button: true,
        label: canAdvance ? 'Turn to next spread' : 'Turn to previous spread',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: action,
            child: CustomPaint(
              painter: _CornerHintPainter(
                isRight: isRight,
                top: top,
                color: const Color(0xFF7C705A).withValues(alpha: .18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlipBookSpine extends StatelessWidget {
  const _FlipBookSpine({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0x00A2967D),
            Color(0x44776E5B),
            Color(0x19776E5B),
            Color(0x00A2967D),
          ],
          stops: [0, .28, .68, 1],
        ),
      ),
    ),
  );
}

class _WarpedPagePainter extends CustomPainter {
  const _WarpedPagePainter({
    required this.frontImage,
    required this.backImage,
    required this.progress,
    required this.fromRight,
    required this.pageWidth,
    required this.spineWidth,
  });

  final ui.Image frontImage;
  final ui.Image backImage;
  final double progress;
  final bool fromRight;
  final double pageWidth;
  final double spineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final forward = fromRight;
    final direction = forward ? 1.0 : -1.0;
    // Move across the gutter so both flat endpoints match the live pages.
    final hingeX = pageWidth + spineWidth * (forward ? 1 - progress : progress);
    final curl = math.sin(math.pi * progress).abs();
    final earlyLift = (1 - (progress / .28).clamp(0.0, 1.0)) * curl;

    const columns = 32;
    const rows = 12;
    final positions = <Offset>[];
    final frontTextures = <Offset>[];
    final backTextures = <Offset>[];
    final shades = <Color>[];
    final frontIndices = <int>[];
    final backIndices = <int>[];

    Offset project(double u, double v) {
      final horizontal = u / pageWidth;
      final vertical = v / size.height;
      final topLift = earlyLift * (1 - vertical);
      final angle = math.pi * progress + topLift * .42;
      final curvature = curl * (.72 + .42 * (1 - vertical));
      final startAngle = angle - curvature / 2;
      final endAngle = startAngle + curvature * horizontal;
      final flat = curvature.abs() < .00001;
      final x = flat
          ? u * math.cos(angle)
          : pageWidth * (math.sin(endAngle) - math.sin(startAngle)) / curvature;
      final depth = flat
          ? u * math.sin(angle)
          : pageWidth * (math.cos(startAngle) - math.cos(endAngle)) / curvature;
      final perspective = 1 / (1 + depth.abs() / (pageWidth * 3));
      return Offset(
        hingeX + direction * x * perspective,
        size.height / 2 + (v - size.height / 2) * perspective,
      );
    }

    void addVertex(double u, double v) {
      positions.add(project(u, v));
      final textureX = u / pageWidth;
      final textureY = v / size.height;
      frontTextures.add(
        Offset(
          (forward ? textureX : 1 - textureX) * frontImage.width,
          textureY * frontImage.height,
        ),
      );
      backTextures.add(
        Offset(
          (forward ? 1 - textureX : textureX) * backImage.width,
          textureY * backImage.height,
        ),
      );
      final shade = (1 - curl * (.12 + .14 * (u / pageWidth))).clamp(.68, 1.0);
      final channel = (255 * shade).round();
      shades.add(Color.fromARGB(255, channel, channel, channel));
    }

    for (var row = 0; row <= rows; row++) {
      final v = size.height * row / rows;
      for (var column = 0; column <= columns; column++) {
        addVertex(pageWidth * column / columns, v);
      }
    }

    int vertex(int row, int column) => row * (columns + 1) + column;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final topLeft = vertex(row, column);
        final topRight = vertex(row, column + 1);
        final bottomLeft = vertex(row + 1, column);
        final bottomRight = vertex(row + 1, column + 1);
        void addTriangle(int a, int b, int c) {
          final ab = positions[b] - positions[a];
          final ac = positions[c] - positions[a];
          final facing = (ab.dx * ac.dy - ab.dy * ac.dx) * direction;
          (facing >= 0 ? frontIndices : backIndices).addAll([a, b, c]);
        }

        addTriangle(topLeft, topRight, bottomRight);
        addTriangle(topLeft, bottomRight, bottomLeft);
      }
    }

    final edge = Path();
    for (var row = 0; row <= rows; row++) {
      final point = project(pageWidth, size.height * row / rows);
      if (row == 0) {
        edge.moveTo(point.dx, point.dy);
      } else {
        edge.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      edge,
      Paint()
        ..color = Colors.black.withValues(alpha: .24 * curl)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12 * curl
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * curl),
    );

    void drawFace(ui.Image image, List<Offset> textures, List<int> indices) {
      if (indices.isEmpty) return;
      final vertices = ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        textureCoordinates: textures,
        colors: shades,
        indices: indices,
      );
      final shader = ui.ImageShader(
        image,
        ui.TileMode.clamp,
        ui.TileMode.clamp,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.medium,
      );
      canvas.drawVertices(
        vertices,
        ui.BlendMode.modulate,
        Paint()..shader = shader,
      );
      vertices.dispose();
      shader.dispose();
    }

    // The curled outer part is nearer the viewer and can expose the reverse
    // while the inner part still shows the front. Avoid a whole-page face swap.
    drawFace(frontImage, frontTextures, frontIndices);
    drawFace(backImage, backTextures, backIndices);
    if (curl > .03) {
      canvas.drawPath(
        edge,
        Paint()
          ..color = Colors.white.withValues(alpha: .52 * curl)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WarpedPagePainter oldDelegate) =>
      oldDelegate.frontImage != frontImage ||
      oldDelegate.backImage != backImage ||
      oldDelegate.progress != progress ||
      oldDelegate.fromRight != fromRight ||
      oldDelegate.pageWidth != pageWidth ||
      oldDelegate.spineWidth != spineWidth;
}

class _CornerHintPainter extends CustomPainter {
  const _CornerHintPainter({
    required this.isRight,
    required this.top,
    required this.color,
  });

  final bool isRight;
  final bool top;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final x = isRight ? size.width : 0.0;
    final y = top ? 0.0 : size.height;
    final innerX = isRight ? x - size.width * .68 : x + size.width * .68;
    final innerY = top ? size.height * .68 : y - size.height * .68;
    path
      ..moveTo(x, y)
      ..lineTo(innerX, y)
      ..quadraticBezierTo(
        isRight ? x - size.width * .18 : x + size.width * .18,
        top ? y + size.height * .18 : y - size.height * .18,
        x,
        innerY,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: isRight ? Alignment.topLeft : Alignment.topRight,
          end: isRight ? Alignment.bottomRight : Alignment.bottomLeft,
          colors: [Colors.white.withValues(alpha: .72), color],
        ).createShader(Offset.zero & size)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
  }

  @override
  bool shouldRepaint(covariant _CornerHintPainter oldDelegate) =>
      oldDelegate.isRight != isRight ||
      oldDelegate.top != top ||
      oldDelegate.color != color;
}
