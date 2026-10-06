import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Widget _app(Widget child) {
  return ShadcnApp(
    theme: ThemeData(colorScheme: ColorSchemes.lightZinc(), radius: 0.5),
    home: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 400, child: child),
    ),
  );
}

void main() {
  testWidgets('horizontal stepper is as tall as the current step only',
      (tester) async {
    final controller = StepperController();
    await tester.pumpWidget(_app(Stepper(
      controller: controller,
      steps: [
        Step(
          title: const Text('Short'),
          contentBuilder: (context) => const SizedBox(height: 100),
        ),
        Step(
          title: const Text('Tall'),
          contentBuilder: (context) => const SizedBox(height: 300),
        ),
      ],
    )));
    final short = tester.getSize(find.byType(Stepper)).height;

    controller.jumpToStep(1);
    await tester.pump();
    final tall = tester.getSize(find.byType(Stepper)).height;

    // IndexedStack made both heights equal to the tallest step.
    expect(tall - short, 200);
  });

  group('Pagination window', () {
    Pagination pagination(int page, int totalPages, int maxPages) =>
        Pagination(
          page: page,
          totalPages: totalPages,
          maxPages: maxPages,
          onPageChanged: (_) {},
        );

    test('even maxPages: "more" buttons start right after the window', () {
      final middle = pagination(5, 10, 4);
      expect(middle.pages, [3, 4, 5, 6]);
      expect(middle.lastShownPage, 6); // was 7: "…" jumped to 8, skipping 7

      final nearEnd = pagination(8, 10, 4);
      expect(nearEnd.pages, [6, 7, 8, 9]);
      expect(nearEnd.hasMoreNextPages, isTrue); // was false: 10 unreachable
    });

    test('odd maxPages: middle unchanged, edges agree with pages', () {
      final middle = pagination(5, 10, 3);
      expect(middle.pages, [4, 5, 6]);
      expect([middle.firstShownPage, middle.lastShownPage], [4, 6]);

      final first = pagination(1, 10, 3);
      expect(first.pages, [1, 2, 3]);
      expect(first.lastShownPage, 3); // was 2, though 3 is shown
    });

    test('maxPages 1 shows only the current page', () {
      for (var page = 1; page <= 7; page++) {
        final p = pagination(page, 7, 1);
        expect(p.pages, [page]);
        expect([p.firstShownPage, p.lastShownPage], [page, page]);
      }
    });
  });
}
