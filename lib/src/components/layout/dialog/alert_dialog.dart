import 'package:shadcn_flutter/shadcn_flutter.dart';

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
  }) : isFullscreen = true;

  @override
  _AlertDialogState createState() => _AlertDialogState();
}

class _AlertDialogState extends State<AlertDialog> {
  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var scaling = themeData.scaling;
    return ModalContainer(
      borderRadius:
          widget.isFullscreen ? BorderRadius.zero : themeData.borderRadiusXxl,
      barrierColor: widget.barrierColor ?? Colors.black.withOpacity(0.8),
      surfaceClip: ModalContainer.shouldClipSurface(
          widget.surfaceOpacity ?? themeData.surfaceOpacity),
      child: OutlinedContainer(
        backgroundColor: themeData.colorScheme.popover,
        borderRadius:
            widget.isFullscreen ? BorderRadius.zero : themeData.borderRadiusXxl,
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
          crossAxisAlignment: CrossAxisAlignment.end,
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
                            widget.title!.large().semiBold(),
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
                        bottom: MediaQuery.of(context).padding.bottom +
                            16 * scaling,
                        right: 16 * scaling,
                        left: 16 * scaling,
                      )
                    : EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: join(widget.actions!, SizedBox(width: 8 * scaling))
                      .toList(),
                ),
              ),
          ],
        ).gap(16 * scaling),
      ),
    );
  }
}
