import 'dart:math';

import 'package:shadcn_flutter/shadcn_flutter.dart';

class Pagination extends StatelessWidget {
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  /// The maximum number of pages to show in the pagination.
  final int maxPages;
  final bool showSkipToFirstPage;
  final bool showSkipToLastPage;
  final bool hidePreviousOnFirstPage;
  final bool hideNextOnLastPage;
  final bool showLabel;
  final bool dense;

  const Pagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    this.maxPages = 3,
    this.showSkipToFirstPage = true,
    this.showSkipToLastPage = true,
    this.hidePreviousOnFirstPage = false,
    this.hideNextOnLastPage = false,
    this.showLabel = true,
    this.dense = false,
  });

  bool get hasPrevious => page > 1;
  bool get hasNext => page < totalPages;

  /// The page numbers shown as buttons: [firstShownPage]..[lastShownPage].
  Iterable<int> get pages => Iterable.generate(
      lastShownPage - firstShownPage + 1, (index) => firstShownPage + index);

  /// Start of the window of up to [maxPages] buttons around [page], shifted
  /// to stay inside 1..[totalPages]. [pages], [lastShownPage] and the "more"
  /// buttons all derive from it, so they always agree (also for an even
  /// [maxPages]).
  int get firstShownPage {
    final int maxFirst = max(1, totalPages - maxPages + 1);
    return (page - maxPages ~/ 2).clamp(1, maxFirst);
  }

  int get lastShownPage => min(totalPages, firstShownPage + maxPages - 1);

  bool get hasMorePreviousPages => firstShownPage > 1;
  bool get hasMoreNextPages => lastShownPage < totalPages;

  Widget _buildPreviousLabel(ShadcnLocalizations localizations, IconData icon) {
    if (showLabel) {
      return GhostButton(
        onPressed: hasPrevious ? () => onPageChanged(page - 1) : null,
        leading: Icon(icon).iconXSmall(),
        child: Text(localizations.buttonPrevious),
      );
    }
    return GhostButton(
      onPressed: hasPrevious ? () => onPageChanged(page - 1) : null,
      child: Icon(icon).iconXSmall(),
    );
  }

  Widget _buildNextLabel(ShadcnLocalizations localizations, IconData icon) {
    if (showLabel) {
      return GhostButton(
        onPressed: hasNext ? () => onPageChanged(page + 1) : null,
        trailing: Icon(icon).iconXSmall(),
        child: Text(localizations.buttonNext),
      );
    }
    return GhostButton(
      onPressed: hasNext ? () => onPageChanged(page + 1) : null,
      child: Icon(icon).iconXSmall(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    ShadcnLocalizations localizations = ShadcnLocalizations.of(context);
    // The Row mirrors in RTL, so "previous" sits on the right and its chevron
    // must point right (and "next" left).
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final previousIcon = rtl ? RadixIcons.chevronRight : RadixIcons.chevronLeft;
    final nextIcon = rtl ? RadixIcons.chevronLeft : RadixIcons.chevronRight;
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!hidePreviousOnFirstPage || hasPrevious)
            _buildPreviousLabel(localizations, previousIcon),
          if (hasMorePreviousPages) ...[
            if (showSkipToFirstPage && firstShownPage - 1 > 1)
              GhostButton(
                onPressed: () => onPageChanged(1),
                density: dense ? ButtonDensity.dense : ButtonDensity.normal,
                child: const Text('1'),
              ),
            GhostButton(
              onPressed: () => onPageChanged(firstShownPage - 1),
              density: dense ? ButtonDensity.dense : ButtonDensity.normal,
              child: const MoreDots(),
            ),
          ],
          for (final p in pages)
            if (p == page)
              OutlineButton(
                onPressed: () => onPageChanged(p),
                density: dense ? ButtonDensity.dense : ButtonDensity.normal,
                child: Text('$p'),
              )
            else
              GhostButton(
                onPressed: () => onPageChanged(p),
                density: dense ? ButtonDensity.dense : ButtonDensity.normal,
                child: Text('$p'),
              ),
          if (hasMoreNextPages) ...[
            GhostButton(
              onPressed: () => onPageChanged(lastShownPage + 1),
              density: dense ? ButtonDensity.dense : ButtonDensity.normal,
              child: const MoreDots(),
            ),
            if (showSkipToLastPage && lastShownPage + 1 < totalPages)
              GhostButton(
                onPressed: () => onPageChanged(totalPages),
                density: dense ? ButtonDensity.dense : ButtonDensity.normal,
                child: Text('$totalPages'),
              ),
          ],
          if (!hideNextOnLastPage || hasNext)
            _buildNextLabel(localizations, nextIcon),
        ],
      ).gap(4 * scaling),
    );
  }
}
