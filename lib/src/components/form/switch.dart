import 'dart:math' as math;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/src/components/layout/focus_outline.dart';

import '../../../shadcn_flutter.dart';

const kSwitchDuration = Duration(milliseconds: 100);

class Switch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? leading;
  final Widget? trailing;

  const Switch({
    super.key,
    required this.value,
    required this.onChanged,
    this.leading,
    this.trailing,
  });

  @override
  State<Switch> createState() => _SwitchState();
}

class _SwitchState extends State<Switch> with FormValueSupplier {
  bool _focusing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reportNewFormValue(widget.value, (value) {
      if (widget.onChanged != null) {
        widget.onChanged!(value);
      }
    });
  }

  @override
  void didUpdateWidget(covariant Switch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      reportNewFormValue(widget.value, (value) {
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      _MinTapArea(child: _buildSwitch(context));

  Widget _buildSwitch(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    return FocusOutline(
      focused: _focusing,
      borderRadius: BorderRadius.circular(theme.radiusXl),
      align: 3 * scaling,
      width: 2 * scaling,
      child: GestureDetector(
        // Opaque: the whole box (gaps and track corners too) takes the tap.
        behavior: HitTestBehavior.opaque,
        // Null when disabled, so the row around a disabled Switch gets taps.
        onTap: widget.onChanged == null
            ? null
            : () => widget.onChanged!(!widget.value),
        child: FocusableActionDetector(
          enabled: widget.onChanged != null,
          onShowFocusHighlight: (value) {
            setState(() {
              _focusing = value;
            });
          },
          actions: {
            ActivateIntent: CallbackAction(
              onInvoke: (Intent intent) {
                widget.onChanged?.call(!widget.value);
                return true;
              },
            ),
          },
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          mouseCursor: SystemMouseCursors.click,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.leading != null) widget.leading!,
              if (widget.leading != null) SizedBox(width: 8 * scaling),
              AnimatedContainer(
                duration: kSwitchDuration,
                width: (32 + 4) * scaling,
                height: (16 + 4) * scaling,
                padding: EdgeInsets.all(2 * scaling),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(theme.radiusXl),
                  color: widget.onChanged == null
                      ? theme.colorScheme.muted
                      : widget.value
                          ? theme.colorScheme.primary
                          : theme.colorScheme.border,
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: kSwitchDuration,
                      curve: Curves.easeInOut,
                      left: widget.value ? 16 * scaling : 0,
                      top: 0,
                      bottom: 0,
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(theme.radiusLg),
                            color: theme.colorScheme.background,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null) SizedBox(width: 8 * scaling),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

const double _kMinTapSize = 44;

// Widens the child's tap target to at least 44x44 (centered) without changing
// its layout size. Taps still only arrive inside the parent's bounds.
// Twin of the one in checkbox.dart (separate library, so it cannot be shared).
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
