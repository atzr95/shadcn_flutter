import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter/material.dart' as material;

class AlertDialog extends StatefulWidget {
  final Widget? leading;
  final Widget? trailing;
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final double? surfaceBlur;
  final double? surfaceOpacity;
  final Color? barrierColor;
  final EdgeInsetsGeometry? padding;
  final bool isFullscreen;
  final bool dismissKeyboardOnTapOutside;

  const AlertDialog({
    super.key,
    this.leading,
    this.title,
    this.content,
    this.actions,
    this.trailing,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.barrierColor,
    this.padding,
    this.dismissKeyboardOnTapOutside = true,
  }) : isFullscreen = false;

  const AlertDialog.fullscreen({
    super.key,
    this.leading,
    this.title,
    this.content,
    this.actions,
    this.trailing,
    this.surfaceBlur,
    this.surfaceOpacity,
    this.barrierColor,
    this.padding,
    this.dismissKeyboardOnTapOutside = true,
  }) : isFullscreen = true;

  @override
  _AlertDialogState createState() => _AlertDialogState();
}

class _AlertDialogState extends State<AlertDialog> {
  void _unfocus() {
    FocusScope.of(context).unfocus();
  }

  Widget _buildBody(BuildContext context, double scaling) {
    final hasActions = widget.actions != null && widget.actions!.isNotEmpty;
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.leading != null)
          widget.leading!.iconXLarge().iconMutedForeground(),
        if (widget.title != null || widget.content != null)
          Flexible(
            child: Column(
              mainAxisSize:
                  widget.isFullscreen ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null)
                  widget.title!.large().semiBold().foreground(),
                if (widget.content != null)
                  Flexible(
                    child: widget.content!.small().muted(),
                  ),
              ],
            ).gap(8 * scaling),
          ),
        if (widget.trailing != null)
          widget.trailing!.iconXLarge().iconMutedForeground(),
      ],
    ).gap(16 * scaling);
    if (!widget.isFullscreen) {
      return _DialogBody(
        gap: 16 * scaling,
        children: [
          header,
          // No alignment: the bar keeps its own width so the card can
          // shrink-wrap; _DialogBody puts it at the end. Buttons that do not
          // fit wrap into an end-aligned column (narrow phones).
          if (hasActions)
            OverflowBar(
              spacing: 8 * scaling,
              overflowSpacing: 8 * scaling,
              overflowAlignment: OverflowBarAlignment.end,
              children: widget.actions!,
            ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(child: header),
        if (hasActions)
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 16 * scaling,
              right: 16 * scaling,
              left: 16 * scaling,
            ),
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8 * scaling,
              overflowSpacing: 8 * scaling,
              overflowAlignment: OverflowBarAlignment.end,
              children: widget.actions!,
            ),
          ),
      ],
    ).gap(16 * scaling);
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var scaling = themeData.scaling;
    // Fullscreen stays edge to edge. A card dialog keeps 16px off the screen
    // edges and clear of the status bar, notch and home indicator. The side
    // gap is a max width, not insetPadding, because insetPadding sits inside
    // a caller's own width limit (e.g. .constrained(maxWidth: 500)) and would
    // shrink it. The dialog is centered on the screen, so the wider side
    // padding counts twice.
    final pad = MediaQuery.paddingOf(context);
    final maxWidth = math.max(
        0.0,
        MediaQuery.sizeOf(context).width -
            2 * math.max(pad.left, pad.right) -
            32 * scaling);
    // A fullscreen dialog's background runs behind the keyboard (iOS 26's
    // keyboard has rounded top corners that showed the dark barrier); only
    // its content stops at the keyboard, via the container padding below.
    final keyboard =
        widget.isFullscreen ? MediaQuery.viewInsetsOf(context).bottom : 0.0;

    Widget dialog = material.Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: widget.isFullscreen
          ? EdgeInsets.zero
          : EdgeInsets.only(
              top: pad.top + 16 * scaling, bottom: pad.bottom + 16 * scaling),
      // A card shrink-wraps its content (see _DialogBody); callers set their
      // own width with e.g. .constrained(maxWidth: 800). minWidth 280 is
      // material's default, restated because passing constraints replaces it.
      constraints: widget.isFullscreen
          ? null
          : BoxConstraints(
              minWidth: math.min(280.0, maxWidth), maxWidth: maxWidth),
      child: ModalContainer(
        borderRadius:
            widget.isFullscreen ? BorderRadius.zero : themeData.borderRadiusXxl,
        barrierColor:
            widget.barrierColor ?? Colors.black.withValues(alpha: 0.8),
        surfaceClip: ModalContainer.shouldClipSurface(
            widget.surfaceOpacity ?? themeData.surfaceOpacity),
        child: GestureDetector(
          onTap: widget.dismissKeyboardOnTapOutside ? _unfocus : null,
          behavior: HitTestBehavior.translucent,
          child: OutlinedContainer(
            backgroundColor: themeData.colorScheme.popover,
            borderRadius: widget.isFullscreen
                ? BorderRadius.zero
                : themeData.borderRadiusXxl,
            borderWidth: widget.isFullscreen ? 0 : 1 * scaling,
            borderColor: themeData.colorScheme.muted,
            padding: widget.isFullscreen
                ? EdgeInsets.only(bottom: keyboard)
                : widget.padding ?? EdgeInsets.all(24 * scaling),
            surfaceBlur: widget.surfaceBlur ?? themeData.surfaceBlur,
            surfaceOpacity: widget.surfaceOpacity ?? themeData.surfaceOpacity,
            child: _buildBody(context, scaling),
          ),
        ),
      ),
    );
    if (!widget.isFullscreen) return dialog;
    // Without the inset, material.Dialog stops shrinking itself above the
    // keyboard; the padding above keeps the content clear of it.
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: dialog,
    );
  }
}

/// Lays a card dialog's header above its actions. The card is as wide as the
/// wider of the two (at least the min width), the header sits at the start
/// and the actions at the end, so neither drifts when the other is wider. A
/// Column can only align all children one way; IntrinsicWidth could stretch
/// them but throws on lists and LayoutBuilder content.
class _DialogBody extends MultiChildRenderObjectWidget {
  const _DialogBody({required this.gap, required super.children});

  final double gap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderDialogBody(gap, Directionality.of(context));

  @override
  void updateRenderObject(
      BuildContext context, _RenderDialogBody renderObject) {
    renderObject
      ..gap = gap
      ..textDirection = Directionality.of(context);
  }
}

class _DialogBodyParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderDialogBody extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DialogBodyParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DialogBodyParentData> {
  _RenderDialogBody(this._gap, this._textDirection);

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox? get _actions => childAfter(firstChild!);

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DialogBodyParentData) {
      child.parentData = _DialogBodyParentData();
    }
  }

  @override
  void performLayout() {
    final loose = constraints.loosen();
    final header = firstChild!;
    final actions = _actions;
    var actionsExtent = 0.0;
    if (actions != null) {
      actions.layout(loose, parentUsesSize: true);
      actionsExtent = actions.size.height + _gap;
    }
    // The header yields height to the actions, like Flexible in a Column, so
    // tall content scrolls instead of pushing the buttons off screen.
    header.layout(
      loose.copyWith(
          maxHeight: math.max(0.0, loose.maxHeight - actionsExtent)),
      parentUsesSize: true,
    );
    final width = constraints.constrainWidth(
        math.max(header.size.width, actions?.size.width ?? 0));
    final rtl = _textDirection == TextDirection.rtl;
    (header.parentData! as _DialogBodyParentData).offset =
        Offset(rtl ? width - header.size.width : 0, 0);
    if (actions != null) {
      (actions.parentData! as _DialogBodyParentData).offset = Offset(
          rtl ? 0 : width - actions.size.width, header.size.height + _gap);
    }
    size = constraints.constrain(Size(width, header.size.height + actionsExtent));
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
      firstChild!.getMinIntrinsicWidth(height),
      _actions?.getMinIntrinsicWidth(height) ?? 0);

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
      firstChild!.getMaxIntrinsicWidth(height),
      _actions?.getMaxIntrinsicWidth(height) ?? 0);

  @override
  double computeMinIntrinsicHeight(double width) =>
      firstChild!.getMinIntrinsicHeight(width) +
      (_actions == null ? 0 : _gap + _actions!.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      firstChild!.getMaxIntrinsicHeight(width) +
      (_actions == null ? 0 : _gap + _actions!.getMaxIntrinsicHeight(width));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
