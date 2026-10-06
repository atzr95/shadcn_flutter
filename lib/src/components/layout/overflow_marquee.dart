import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class OverflowMarquee extends StatefulWidget {
  final Widget child;
  final Axis direction;
  final Duration duration;
  final double step;
  final Duration delayDuration;
  final double fadePortion;
  final Curve curve;

  const OverflowMarquee({
    super.key,
    required this.child,
    this.direction = Axis.horizontal,
    this.duration = const Duration(seconds: 1),
    this.delayDuration = const Duration(milliseconds: 500),
    this.step = 100, // note: the speed of the marquee depends on this value
    // speed = (sizeDiff / step) * duration
    this.fadePortion = 25,
    this.curve = Curves.linear,
  });

  @override
  State<OverflowMarquee> createState() => _OverflowMarqueeState();
}

class _OverflowMarqueeState extends State<OverflowMarquee>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  // Ticker time. The render object listens and only repaints, so nothing
  // rebuilds or relayouts per frame.
  final ValueNotifier<Duration> _elapsed = ValueNotifier(Duration.zero);

  @override
  void initState() {
    super.initState();
    // Started and stopped by the render object: it runs only while the
    // child overflows.
    _ticker = createTicker((elapsed) => _elapsed.value = elapsed);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    return ClipRect(
      child: _OverflowMarqueeLayout(
        direction: widget.direction,
        fadePortion: widget.fadePortion,
        duration: widget.duration,
        delayDuration: widget.delayDuration,
        ticker: _ticker,
        elapsed: _elapsed,
        step: widget.step,
        textDirection: textDirection,
        child: widget.child,
      ),
    );
  }
}

class _OverflowMarqueeLayout extends SingleChildRenderObjectWidget {
  final Axis direction;
  final double fadePortion;
  final Duration duration;
  final Duration delayDuration;
  final Ticker ticker;
  final ValueNotifier<Duration> elapsed;
  final double step;
  final TextDirection textDirection;

  const _OverflowMarqueeLayout({
    required this.direction,
    this.fadePortion = 25,
    required this.duration,
    required this.delayDuration,
    required this.ticker,
    required this.elapsed,
    required this.step,
    required this.textDirection,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderOverflowMarqueeLayout(
      null,
      direction: direction,
      fadePortion: fadePortion,
      duration: duration,
      delayDuration: delayDuration,
      ticker: ticker,
      step: step,
      elapsed: elapsed,
      textDirection: textDirection,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _RenderOverflowMarqueeLayout renderObject) {
    bool hasChanged = false;
    if (renderObject.direction != direction) {
      renderObject.direction = direction;
      hasChanged = true;
    }
    if (renderObject.fadePortion != fadePortion) {
      renderObject.fadePortion = fadePortion;
      hasChanged = true;
    }
    if (renderObject.duration != duration) {
      renderObject.duration = duration;
      hasChanged = true;
    }
    if (renderObject.delayDuration != delayDuration) {
      renderObject.delayDuration = delayDuration;
      hasChanged = true;
    }
    // most likely this will never change
    if (renderObject.ticker != ticker) {
      renderObject.ticker = ticker;
      hasChanged = true;
    }
    if (renderObject.step != step) {
      renderObject.step = step;
      hasChanged = true;
    }
    if (renderObject.textDirection != textDirection) {
      renderObject.textDirection = textDirection;
      hasChanged = true;
    }
    if (hasChanged) {
      renderObject.markNeedsLayout();
    }
  }
}

class _RenderOverflowMarqueeLayout extends RenderShiftedBox {
  Axis direction;
  double fadePortion;
  Duration duration;
  Duration delayDuration;
  Ticker ticker;
  // Same notifier for the whole life of the State, so it is never swapped.
  final ValueNotifier<Duration> elapsed;
  double step;
  TextDirection textDirection;

  _RenderOverflowMarqueeLayout(
    super.child, {
    required this.direction,
    required this.fadePortion,
    required this.duration,
    required this.delayDuration,
    required this.ticker,
    required this.elapsed,
    required this.step,
    required this.textDirection,
  });

  // How far the child overflows along [direction]; <= 0 when it fits.
  double _sizeDiff = 0;
  // Whether the edges fade, which needs a ShaderMaskLayer.
  bool _fades = false;
  double _paintedProgress = 0;
  Shader? _shader;
  Object? _shaderKey;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    elapsed.addListener(_onTick);
  }

  @override
  void detach() {
    elapsed.removeListener(_onTick);
    super.detach();
  }

  // Only the scroll position moves, so a repaint is enough. Skipped while
  // the marquee rests at either end.
  void _onTick() {
    if (offsetProgress != _paintedProgress) {
      markNeedsPaint();
    }
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (direction == Axis.horizontal) {
      return super.computeMaxIntrinsicHeight(double.infinity);
    }
    return super.computeMaxIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (direction == Axis.vertical) {
      return super.computeMaxIntrinsicWidth(double.infinity);
    }
    return super.computeMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (direction == Axis.horizontal) {
      return super.computeMinIntrinsicHeight(double.infinity);
    }
    return super.computeMinIntrinsicHeight(width);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (direction == Axis.vertical) {
      return super.computeMinIntrinsicWidth(double.infinity);
    }
    return super.computeMinIntrinsicWidth(height);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child;
    if (child != null) {
      // Same as performLayout: the child is measured unbounded along the
      // scroll axis, then this box is clamped to the incoming constraints.
      return constraints.constrain(
        child.getDryLayout(_childConstraints(constraints)),
      );
    }
    return constraints.biggest;
  }

  BoxConstraints _childConstraints(BoxConstraints constraints) =>
      direction == Axis.horizontal
          ? constraints.copyWith(maxWidth: double.infinity)
          : constraints.copyWith(maxHeight: double.infinity);

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  @override
  bool get alwaysNeedsCompositing => _fades;

  double get offsetProgress {
    if (_sizeDiff <= 0) return 0;
    double durationInMicros = duration.inMicroseconds * (_sizeDiff / step);
    int delayDurationInMicros = delayDuration.inMicroseconds;
    double elapsedInMicros = elapsed.value.inMicroseconds.toDouble();
    // includes the reverse
    double overalCycleDuration = delayDurationInMicros +
        durationInMicros +
        delayDurationInMicros +
        durationInMicros;
    elapsedInMicros = elapsedInMicros % overalCycleDuration;
    // >= so the exact end of the forward pass does not snap back to 0.
    bool reverse = elapsedInMicros >= delayDurationInMicros + durationInMicros;
    double cycleElapsedInMicros =
        elapsedInMicros % (delayDurationInMicros + durationInMicros);
    if (cycleElapsedInMicros < delayDurationInMicros) {
      return reverse ? 1 : 0;
    } else if (cycleElapsedInMicros <
        delayDurationInMicros + durationInMicros) {
      double progress =
          (cycleElapsedInMicros - delayDurationInMicros) / durationInMicros;
      return reverse ? 1 - progress : progress;
    } else {
      return reverse ? 0 : 1;
    }
  }

  // How much an edge is faded (0..1) once [scrolled] pixels are hidden past it.
  double _fadeAmount(double scrolled) =>
      (scrolled / fadePortion).clamp(0.0, 1.0);

  // Alpha mask that fades the edge(s) where content is hidden. Mid-scroll both
  // edges are fully faded, so the cached shader is reused on most frames.
  Shader _alphaShader(double progress) {
    final start = _fadeAmount(_sizeDiff * progress);
    final end = _fadeAmount(_sizeDiff * (1 - progress));
    final key = (start, end, size, direction, textDirection, fadePortion);
    if (key == _shaderKey) return _shader!;
    final horizontal = direction == Axis.horizontal;
    // At most half each side, so the stops stay in order on narrow boxes.
    final portion =
        (fadePortion / (horizontal ? size.width : size.height)).clamp(0.0, 0.5);
    _shaderKey = key;
    return _shader = LinearGradient(
      begin: horizontal
          ? AlignmentDirectional.centerStart.resolve(textDirection)
          : Alignment.topCenter,
      end: horizontal
          ? AlignmentDirectional.centerEnd.resolve(textDirection)
          : Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 1 - start),
        Colors.white,
        Colors.white,
        Colors.white.withValues(alpha: 1 - end),
      ],
      stops: [0.0, portion, 1.0 - portion, 1.0],
    ).createShader(Offset.zero & size);
  }

  // Scrolls the child to [progress]. In RTL it starts right-aligned (showing
  // the start of the text) and scrolls the other way.
  void _positionChild(double progress) {
    final parentData = child!.parentData as BoxParentData;
    if (direction == Axis.vertical) {
      parentData.offset = Offset(0, -_sizeDiff * progress);
    } else if (textDirection == TextDirection.rtl) {
      parentData.offset = Offset(-_sizeDiff * (1 - progress), 0);
    } else {
      parentData.offset = Offset(-_sizeDiff * progress, 0);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    final progress = _paintedProgress = offsetProgress;
    // Set here (not in layout) because ticks only repaint; hit testing and
    // paint transforms read this offset.
    _positionChild(progress);
    if (!_fades) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    assert(needsCompositing);
    layer ??= ShaderMaskLayer();
    layer!
      ..shader = _alphaShader(progress)
      ..maskRect = (offset & size).inflate(1)
      ..blendMode = BlendMode.modulate;
    context.pushLayer(layer!, super.paint, offset);
    assert(() {
      layer!.debugCreator = debugCreator;
      return true;
    }());
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child != null) {
      child.layout(_childConstraints(constraints), parentUsesSize: true);
      size = constraints.constrain(child.size);
      _sizeDiff = direction == Axis.horizontal
          ? child.size.width - size.width
          : child.size.height - size.height;
    } else {
      size = constraints.biggest;
      _sizeDiff = 0;
    }
    if (_sizeDiff > 0) {
      if (!ticker.isActive) {
        // Restart from the beginning, not where it last stopped.
        elapsed.value = Duration.zero;
        ticker.start();
      }
    } else if (ticker.isActive) {
      ticker.stop();
    }
    final fades = _sizeDiff > 0 && fadePortion > 0;
    if (fades != _fades) {
      _fades = fades;
      markNeedsCompositingBitsUpdate();
    }
  }
}
