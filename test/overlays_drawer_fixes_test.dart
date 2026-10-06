import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Widget _app(Widget home) {
  return ShadcnApp(
    theme: ThemeData(colorScheme: ColorSchemes.darkZinc(), radius: 0.5),
    home: home,
  );
}

// shadcn exports its own pixel-snapping Text, which find.text does not match.
Finder _text(String data) =>
    find.byWidgetPredicate((w) => w is Text && w.data == data);

Future<void> _pump(WidgetTester tester, Widget app) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle(); // localizations load asynchronously
}

// A page with an 'open' button that shows a card dialog (no Scaffold).
// [onAction] runs from a context inside the dialog.
Widget _pageWithCardDialog(void Function(BuildContext) onAction) {
  return Scaffold(
    child: Builder(
      builder: (context) => GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (_) => Center(
            child: SurfaceCard(
              child: Builder(
                builder: (dialogContext) => GestureDetector(
                  onTap: () => onAction(dialogContext),
                  child: const Text('action'),
                ),
              ),
            ),
          ),
        ),
        child: const Text('open'),
      ),
    ),
  );
}

void _useSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('a toast from a dialog shows above the dialog', (tester) async {
    await _pump(tester, _app(_pageWithCardDialog((context) {
      showToast(context: context, builder: (_, __) => const Text('toast'));
    })));
    await tester.tap(_text('open'));
    await tester.pumpAndSettle();
    await tester.tap(_text('action'));
    await tester.pump(const Duration(milliseconds: 600));

    // Lands in ShadcnApp's root layer, above every route (not the page's
    // layer under the dialog, whose capture asserted).
    expect(_text('toast'), findsOneWidget);
    expect(find.ancestor(of: _text('toast'), matching: find.byType(Navigator)),
        findsNothing);
    await tester.pump(const Duration(seconds: 6)); // let the toast expire
    await tester.pumpAndSettle();
  });

  testWidgets('a sheet from a card dialog shows above it; back closes it',
      (tester) async {
    await _pump(tester, _app(_pageWithCardDialog((context) {
      openSheet(
        context: context,
        position: OverlayPosition.bottom,
        builder: (_) => const SizedBox(height: 200, child: Text('sheet')),
      );
    })));
    await tester.tap(_text('open'));
    await tester.pumpAndSettle();
    await tester.tap(_text('action'));
    await tester.pumpAndSettle();
    expect(_text('sheet').hitTestable(), findsOneWidget);

    // Android back closes the sheet, not the dialog under it.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_text('sheet'), findsNothing);
    expect(_text('action').hitTestable(), findsOneWidget);
  });

  testWidgets('popping a card dialog by code closes all its sheets',
      (tester) async {
    late BuildContext dialogContext;
    final results = <String, Object?>{};
    await _pump(tester, _app(_pageWithCardDialog((context) {
      dialogContext = context;
      // Two stacked typed sheets, the lower one not dismissible. The dialog's
      // int result must reach neither.
      openSheet<String>(
        context: context,
        position: OverlayPosition.bottom,
        barrierDismissible: false,
        builder: (sheetContext) => GestureDetector(
          onTap: () => openSheet<String>(
            context: sheetContext,
            position: OverlayPosition.bottom,
            builder: (_) => const SizedBox(height: 100, child: Text('inner')),
          ).then((v) => results['inner'] = v),
          child: const SizedBox(height: 300, child: Text('outer')),
        ),
      ).then((v) => results['outer'] = v);
    })));
    await tester.tap(_text('open'));
    await tester.pumpAndSettle();
    await tester.tap(_text('action'));
    await tester.pumpAndSettle();
    await tester.tap(_text('outer'));
    await tester.pumpAndSettle();
    expect(_text('inner').hitTestable(), findsOneWidget);

    Navigator.pop(dialogContext, 42);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_text('outer'), findsNothing);
    expect(_text('inner'), findsNothing);
    expect(results, {'outer': null, 'inner': null});
    expect(_text('open').hitTestable(), findsOneWidget);
  });

  testWidgets('back while a finger drags a drawer still closes it',
      (tester) async {
    _useSize(tester, const Size(400, 800));
    bool closed = false;
    await _pump(
        tester,
        _app(Scaffold(
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => openDrawer(
                context: context,
                position: OverlayPosition.bottom,
                builder: (_) =>
                    const SizedBox(height: 300, child: Text('drawer')),
              ).then((_) => closed = true),
              child: const Text('open'),
            ),
          ),
        )));
    await tester.tap(_text('open'));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(_text('drawer')));
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, 4)); // past the touch slop
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.binding.handlePopRoute(); // close() starts mid-drag
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -4)); // the finger keeps going
      await tester.pump(const Duration(milliseconds: 100));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(_text('drawer'), findsNothing);
  });

  testWidgets('bottom sheet sits above the keyboard', (tester) async {
    _useSize(tester, const Size(400, 800));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    late EdgeInsets contentInsets;
    await _pump(
        tester,
        _app(Scaffold(
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => openSheet(
                context: context,
                position: OverlayPosition.bottom,
                builder: (_) => Builder(builder: (context) {
                  contentInsets = MediaQuery.viewInsetsOf(context);
                  return const SizedBox(height: 100, child: Text('sheet'));
                }),
              ),
              child: const Text('open'),
            ),
          ),
        )));
    await tester.tap(_text('open'));
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byType(SheetWrapper)).bottom, 500);
    expect(contentInsets.bottom, 0); // not applied twice
  });

  testWidgets('RTL start drawer closes on a short fling toward its edge',
      (tester) async {
    _useSize(tester, const Size(800, 600));
    await _pump(
        tester,
        _app(Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            child: Builder(
              builder: (context) => GestureDetector(
                onTap: () => openDrawer(
                  context: context,
                  position:
                      OverlayPosition.left, // start: the right side in RTL
                  builder: (_) =>
                      const SizedBox(width: 300, child: Text('drawer')),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        )));
    await tester.tap(_text('open'));
    await tester.pumpAndSettle();
    expect(tester.getCenter(_text('drawer')).dx, greaterThan(400));

    // 60px is far from halfway; only the fling (toward the right edge in
    // RTL) can close it.
    await tester.fling(_text('drawer'), const Offset(60, 0), 1500);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360)); // drag-end slide
    await tester.pump(); // no second exit animation: gone right away
    expect(_text('drawer'), findsNothing);
  });

  testWidgets('a double tap during slide-out runs the item once',
      (tester) async {
    int taps = 0;
    await _pump(
        tester,
        _app(Scaffold(
          child: Builder(
            builder: (context) => GestureDetector(
              onTap: () => openSheet(
                context: context,
                position: OverlayPosition.bottom,
                builder: (sheetContext) => GestureDetector(
                  onTap: () {
                    taps++;
                    closeSheet(sheetContext);
                  },
                  child: const SizedBox(height: 100, child: Text('item')),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        )));
    await tester.tap(_text('open'));
    await tester.pumpAndSettle();

    await tester.tap(_text('item'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(_text('item'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(_text('item'), findsNothing);
  });

  group('RefreshTrigger', () {
    // Stages the indicator was built with, in order.
    late List<TriggerStage> stages;
    setUp(() => stages = []);

    Widget list({
      required Future<void> Function() onRefresh,
      Key? key,
      ScrollController? controller,
    }) {
      return _app(Scaffold(
        child: RefreshTrigger(
          key: key,
          onRefresh: onRefresh,
          indicatorBuilder: (context, stage) {
            stages.add(stage.stage);
            return const SizedBox();
          },
          child: ListView.builder(
            controller: controller,
            itemExtent: 50,
            itemCount: 100,
            itemBuilder: (_, i) => Text('row $i'),
          ),
        ),
      ));
    }

    testWidgets('scrolling up mid-list does not refresh; a pull does',
        (tester) async {
      int refreshes = 0;
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await _pump(tester,
          list(controller: controller, onRefresh: () async => refreshes++));

      // A finger drag in small steps, like a real one.
      Future<void> drag(double dy) async {
        final gesture =
            await tester.startGesture(tester.getCenter(find.byType(ListView)));
        for (var i = 0; i < 20; i++) {
          await gesture.moveBy(Offset(0, dy / 20));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pumpAndSettle();
      }

      controller.jumpTo(1000);
      await tester.pump();
      await drag(200); // scroll back up 200px, still mid-list
      expect(refreshes, 0);

      controller.jumpTo(0);
      await tester.pump();
      await drag(400); // a pull at the top
      expect(refreshes, 1);
      await tester.pump(const Duration(seconds: 1)); // "complete" timer
    });

    testWidgets('a failing onRefresh is reported and returns to idle',
        (tester) async {
      final key = GlobalKey<RefreshTriggerState>();
      await _pump(
          tester,
          list(
            key: key,
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 100));
              throw StateError('offline');
            },
          ));

      final done = key.currentState!.refresh();
      await tester.pump();
      expect(stages.last, TriggerStage.refreshing);
      await tester.pump(const Duration(milliseconds: 200));
      await done; // completes normally: the error is reported, not thrown
      expect(tester.takeException(), isA<StateError>());
      expect(stages, isNot(contains(TriggerStage.completed)));
      expect(stages.last, TriggerStage.idle);
    });
  });
}
