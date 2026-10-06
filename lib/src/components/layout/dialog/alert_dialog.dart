import 'dart:math' as math;

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

    return material.Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: widget.isFullscreen
          ? EdgeInsets.zero
          : EdgeInsets.only(
              top: pad.top + 16 * scaling, bottom: pad.bottom + 16 * scaling),
      // A card fills the screen up to 512 like shadcn/ui's AlertDialog
      // (w-full max-w-lg), so the title sits at the start and the buttons at
      // the end. minWidth 280 is material's default, restated because passing
      // constraints replaces it.
      constraints: widget.isFullscreen
          ? null
          : BoxConstraints(
              minWidth: math.min(280.0, maxWidth),
              maxWidth: math.min(512 * scaling, maxWidth)),
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
                ? EdgeInsets.zero
                : widget.padding ?? EdgeInsets.all(24 * scaling),
            surfaceBlur: widget.surfaceBlur ?? themeData.surfaceBlur,
            surfaceOpacity: widget.surfaceOpacity ?? themeData.surfaceOpacity,
            child: Column(
              mainAxisSize:
                  widget.isFullscreen ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leading != null)
                        widget.leading!.iconXLarge().iconMutedForeground(),
                      if (widget.title != null || widget.content != null)
                        Flexible(
                          child: Column(
                            mainAxisSize: widget.isFullscreen
                                ? MainAxisSize.max
                                : MainAxisSize.min,
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
                  ).gap(16 * scaling),
                ),
                if (widget.actions != null && widget.actions!.isNotEmpty)
                  Padding(
                    padding: widget.isFullscreen
                        ? EdgeInsets.only(
                            bottom: MediaQuery.paddingOf(context).bottom +
                                16 * scaling,
                            right: 16 * scaling,
                            left: 16 * scaling,
                          )
                        : EdgeInsets.zero,
                    // Buttons sit at the end; they wrap into an end-aligned
                    // column when they do not fit in one row (narrow phones).
                    child: OverflowBar(
                      alignment: MainAxisAlignment.end,
                      spacing: 8 * scaling,
                      overflowSpacing: 8 * scaling,
                      overflowAlignment: OverflowBarAlignment.end,
                      children: widget.actions!,
                    ),
                  ),
              ],
            ).gap(16 * scaling),
          ),
        ),
      ),
    );
  }
}
