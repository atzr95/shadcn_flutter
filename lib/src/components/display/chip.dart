import 'package:shadcn_flutter/shadcn_flutter.dart';

class ChipButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const ChipButton({
    super.key,
    required this.child,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Button(
      style: ButtonVariance(
        decoration: (context, states) {
          return const BoxDecoration();
        },
        mouseCursor: (context, states) {
          if (states.contains(WidgetState.disabled)) {
            return SystemMouseCursors.basic;
          }
          return SystemMouseCursors.click;
        },
        padding: (context, states) {
          return EdgeInsets.zero;
        },
        textStyle: (context, states) {
          return const TextStyle();
        },
        iconTheme: (context, states) {
          return theme.iconTheme.xSmall;
        },
        margin: (context, states) {
          return EdgeInsets.zero;
        },
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}

class Chip extends StatelessWidget {
  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final AbstractButtonStyle? style;

  const Chip({
    super.key,
    required this.child,
    this.leading,
    this.trailing,
    this.onPressed,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Button(
      style: (style ?? ButtonVariance.secondary).copyWith(
        mouseCursor: (context, states, value) {
          return onPressed != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic;
        },
        padding: (context, states, value) {
          return EdgeInsets.symmetric(
              horizontal: theme.scaling * 8, vertical: theme.scaling * 4);
        },
      ),
      onPressed: onPressed,
      // Like badges: a chip without onPressed is static, not disabled, so it
      // keeps its normal colors but gets no press, sound or hover feedback.
      enabled: true,
      disableHoverEffect: onPressed == null,
      leading: leading,
      trailing: trailing,
      child: child,
    );
  }
}
