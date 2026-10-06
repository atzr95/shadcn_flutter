import 'dart:math' as math;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';

import '../../../shadcn_flutter.dart';

enum CheckboxState implements Comparable<CheckboxState> {
  checked,
  unchecked,
  indeterminate;

  @override
  int compareTo(CheckboxState other) {
    return index.compareTo(other.index);
  }
}

class Checkbox extends StatefulWidget {
  final CheckboxState state;
  final ValueChanged<CheckboxState>? onChanged;
  final Widget? leading;
  final Widget? trailing;
  final bool tristate;

  const Checkbox({
    super.key,
    required this.state,
    required this.onChanged,
    this.leading,
    this.trailing,
    this.tristate = false,
  });

  @override
  _CheckboxState createState() => _CheckboxState();
}

class _CheckboxState extends State<Checkbox> with FormValueSupplier {
  final bool _focusing = false;
  bool _shouldAnimate = false;

  void _changeTo(CheckboxState state) {
    if (widget.onChanged != null) {
      widget.onChanged!(state);
    }
  }

  void _tap() {
    if (widget.tristate) {
      switch (widget.state) {
        case CheckboxState.checked:
          _changeTo(CheckboxState.unchecked);
          break;
        case CheckboxState.unchecked:
          _changeTo(CheckboxState.checked);
          break;
        case CheckboxState.indeterminate:
          _changeTo(CheckboxState.checked);
          break;
      }
    } else {
      _changeTo(
        widget.state == CheckboxState.checked
            ? CheckboxState.unchecked
            : CheckboxState.checked,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reportNewFormValue(widget.state, (value) {
      if (widget.onChanged != null) {
        widget.onChanged!(value);
      }
    });
  }

  @override
  void didUpdateWidget(covariant Checkbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      reportNewFormValue(widget.state, (value) {
        _changeTo(value);
      });
      _shouldAnimate = true;
    }
  }

  @override
  Widget build(BuildContext context) =>
      _MinTapArea(child: _buildCheckbox(context));

  Widget _buildCheckbox(BuildContext context) {
    final theme = Theme.of(context);
    return Clickable(
      enabled: widget.onChanged != null,
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      onPressed: widget.onChanged != null ? _tap : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.leading != null) widget.leading!.small().medium(),
          SizedBox(width: theme.scaling * 8),
          AnimatedContainer(
            duration: kDefaultDuration,
            width: theme.scaling * 16,
            height: theme.scaling * 16,
            decoration: BoxDecoration(
              color: widget.state == CheckboxState.checked
                  ? theme.colorScheme.primary
                  : theme.colorScheme.primary.withOpacity(0),
              borderRadius: BorderRadius.circular(theme.radiusSm),
              border: Border.all(
                color: _focusing
                    ? theme.colorScheme.ring
                    : widget.state == CheckboxState.checked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.mutedForeground,
                width: (_focusing ? 2 : 1) * theme.scaling,
              ),
            ),
            child: widget.state == CheckboxState.checked
                ? Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      child: SizedBox(
                        width: theme.scaling * 9,
                        height: theme.scaling * 6.5,
                        child: AnimatedValueBuilder(
                          value: 1.0,
                          initialValue: _shouldAnimate ? 0.0 : null,
                          duration: const Duration(milliseconds: 300),
                          curve: const IntervalDuration(
                            start: Duration(milliseconds: 175),
                            duration: Duration(milliseconds: 300),
                          ),
                          builder: (context, value, child) {
                            return CustomPaint(
                              painter: AnimatedCheckPainter(
                                progress: value,
                                color: theme.colorScheme.primaryForeground,
                                strokeWidth: theme.scaling * 1,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: widget.state == CheckboxState.indeterminate
                          ? theme.scaling * 8
                          : 0,
                      height: widget.state == CheckboxState.indeterminate
                          ? theme.scaling * 8
                          : 0,
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(theme.radiusXs),
                      ),
                    ),
                  ),
          ),
          SizedBox(width: theme.scaling * 8),
          if (widget.trailing != null) widget.trailing!.small().medium(),
        ],
      ),
    );
  }
}

const double _kMinTapSize = 44;

// Widens the child's tap target to at least 44x44 (centered) without changing
// its layout size. Taps still only arrive inside the parent's bounds.
// Twin of the one in switch.dart (separate library, so it cannot be shared).
class _MinTapArea extends SingleChildRenderObjectWidget {
  const _MinTapArea({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMinTapArea();
}

class _RenderMinTapArea extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      return super.hitTest(result, position: position);
    }
    final area = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: math.max(size.width, _kMinTapSize),
      height: math.max(size.height, _kMinTapSize),
    );
    if (size.isEmpty || !area.contains(position) || _siblingTakes(position)) {
      return false;
    }
    // Move the near miss onto the closest point inside the box.
    return super.hitTest(
      result,
      position: Offset(
        position.dx.clamp(0.0, size.width - precisionErrorTolerance),
        position.dy.clamp(0.0, size.height - precisionErrorTolerance),
      ),
    );
  }

  // True when a sibling drawn under [position] takes the hit itself, so the
  // wider area never steals a tap from a neighbour's own box.
  // ponytail: direct siblings only; a near miss in an empty gap between two
  // widened targets goes to the later one in paint order.
  bool _siblingTakes(Offset position) {
    final self = parentData;
    if (self is! BoxParentData) return false;
    final point = position + self.offset;
    var taken = false;
    parent?.visitChildren((child) {
      if (taken || child == this || child is! RenderBox) return;
      final data = child.parentData;
      if (data is BoxParentData && (data.offset & child.size).contains(point)) {
        taken =
            child.hitTest(BoxHitTestResult(), position: point - data.offset);
      }
    });
    return taken;
  }
}

class AnimatedCheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  AnimatedCheckPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    Offset firstStrokeStart = Offset(0, size.height * 0.5);
    Offset firstStrokeEnd = Offset(size.width * 0.35, size.height);
    Offset secondStrokeStart = firstStrokeEnd;
    Offset secondStrokeEnd = Offset(size.width, 0);
    double firstStrokeLength =
        (firstStrokeEnd - firstStrokeStart).distanceSquared;
    double secondStrokeLength =
        (secondStrokeEnd - secondStrokeStart).distanceSquared;
    double totalLength = firstStrokeLength + secondStrokeLength;

    double normalizedFirstStrokeLength = firstStrokeLength / totalLength;
    double normalizedSecondStrokeLength = secondStrokeLength / totalLength;

    double firstStrokeProgress =
        progress.clamp(0.0, normalizedFirstStrokeLength) /
            normalizedFirstStrokeLength;
    double secondStrokeProgress = (progress - normalizedFirstStrokeLength)
            .clamp(0.0, normalizedSecondStrokeLength) /
        normalizedSecondStrokeLength;
    if (firstStrokeProgress <= 0) {
      return;
    }
    Offset currentPoint =
        Offset.lerp(firstStrokeStart, firstStrokeEnd, firstStrokeProgress)!;
    path.moveTo(firstStrokeStart.dx, firstStrokeStart.dy);
    path.lineTo(currentPoint.dx, currentPoint.dy);
    if (secondStrokeProgress <= 0) {
      canvas.drawPath(path, paint);
      return;
    }
    Offset secondPoint = Offset.lerp(
      secondStrokeStart,
      secondStrokeEnd,
      secondStrokeProgress,
    )!;
    path.lineTo(secondPoint.dx, secondPoint.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant AnimatedCheckPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
