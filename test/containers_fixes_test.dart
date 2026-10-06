import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Widget _app(Widget home) {
  return ShadcnApp(
    theme: ThemeData(colorScheme: ColorSchemes.darkZinc(), radius: 0.5),
    home: home,
  );
}

// A 100x50 marquee box; the child is [childSize]. Defaults: 1s per 100px,
// 500ms delay at each end.
Widget _marquee({
  required Size childSize,
  Axis direction = Axis.horizontal,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return Directionality(
    textDirection: textDirection,
    child: Center(
      child: SizedBox(
        width: 100,
        height: 50,
        child: OverflowMarquee(
          direction: direction,
          child: SizedBox.fromSize(
            key: const ValueKey('child'),
            size: childSize,
          ),
        ),
      ),
    ),
  );
}

// Child position relative to the marquee box.
Offset _childOffset(WidgetTester tester) {
  return tester.getTopLeft(find.byKey(const ValueKey('child'))) -
      tester.getTopLeft(find.byType(OverflowMarquee));
}

void main() {
  group('OverflowMarquee', () {
    testWidgets('scrolls vertically', (tester) async {
      await tester.pumpWidget(_marquee(
        childSize: const Size(100, 200), // overflows by 150
        direction: Axis.vertical,
      ));
      expect(_childOffset(tester), Offset.zero);
      // 500ms delay + half of the 1.5s scroll.
      await tester.pump(const Duration(milliseconds: 1250));
      expect(_childOffset(tester).dx, 0);
      expect(_childOffset(tester).dy, moreOrLessEquals(-75));
    });

    testWidgets('LTR starts left-aligned and scrolls left', (tester) async {
      await tester.pumpWidget(_marquee(childSize: const Size(300, 50)));
      expect(_childOffset(tester), Offset.zero);
      // 500ms delay + half of the 2s scroll.
      await tester.pump(const Duration(milliseconds: 1500));
      expect(_childOffset(tester).dx, moreOrLessEquals(-100));
    });

    testWidgets('RTL starts right-aligned and scrolls right', (tester) async {
      await tester.pumpWidget(_marquee(
        childSize: const Size(300, 50),
        textDirection: TextDirection.rtl,
      ));
      expect(_childOffset(tester).dx, moreOrLessEquals(-200));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(_childOffset(tester).dx, moreOrLessEquals(-100));
      // Forward pass done, resting at the end before reversing.
      await tester.pump(const Duration(milliseconds: 1100));
      expect(_childOffset(tester).dx, moreOrLessEquals(0));
    });

    testWidgets('child text reaches screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 50,
            child: OverflowMarquee(child: Text('a long marquee label')),
          ),
        ),
      ));
      expect(find.bySemanticsLabel('a long marquee label'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('only fades and ticks while the child overflows',
        (tester) async {
      await tester.pumpWidget(_marquee(childSize: const Size(60, 50)));
      expect(tester.layers.whereType<ShaderMaskLayer>(), isEmpty);
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pumpWidget(_marquee(childSize: const Size(300, 50)));
      expect(tester.layers.whereType<ShaderMaskLayer>(), hasLength(1));
      expect(tester.binding.hasScheduledFrame, isTrue);
    });
  });

  group('Scaffold', () {
    testWidgets('header takes its real (wrapped) height and passes taps',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(
        Scaffold(
          headerBackgroundColor: const Color(0xFFFF0000),
          headers: [
            SizedBox(
              width: 200,
              child: Text('word ' * 40, key: const ValueKey('title')),
            ),
          ],
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox.expand(key: ValueKey('content')),
          ),
        ),
      ));
      final titleHeight =
          tester.getSize(find.byKey(const ValueKey('title'))).height;
      // Wrapped over several lines, not measured as one.
      expect(titleHeight, greaterThan(50));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('content'))).dy,
        titleHeight,
      );
      // Below the header, the page is not covered by the header background.
      await tester.tapAt(const Offset(10, 500));
      expect(taps, 1);
    });

    testWidgets('nested Scaffold pads keyboard insets once', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 100);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(
        const Scaffold(
          child: Scaffold(
            footers: [SizedBox(key: ValueKey('footer'), height: 50)],
            child: SizedBox.expand(key: ValueKey('content')),
          ),
        ),
      ));
      expect(tester.getSize(find.byKey(const ValueKey('content'))).height, 700);
      // The inner footer still hides while the keyboard is open.
      expect(find.byKey(const ValueKey('footer')), findsNothing);
    });

    testWidgets('ScaffoldHeaderPadding takes a child and hit-tests it',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(
        Scaffold(
          floatingHeader: true,
          headers: const [SizedBox(height: 40)],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScaffoldHeaderPadding(
                child: GestureDetector(
                  key: const ValueKey('pad'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                  child: const SizedBox(),
                ),
              ),
            ],
          ),
        ),
      ));
      // Header size is published after the first frame.
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(const ValueKey('pad'))).height, 40);
      await tester.tap(find.byKey(const ValueKey('pad')));
      expect(taps, 1);
    });
  });

  testWidgets('surface blur only behind see-through backgrounds',
      (tester) async {
    Finder blurIn(String key) => find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(BackdropFilter),
        );
    await tester.pumpWidget(_app(
      const Column(
        children: [
          OutlinedContainer(
            key: ValueKey('opaque'),
            surfaceBlur: 10,
            child: SizedBox(width: 10, height: 10),
          ),
          OutlinedContainer(
            key: ValueKey('translucent'),
            surfaceBlur: 10,
            surfaceOpacity: 0.5,
            child: SizedBox(width: 10, height: 10),
          ),
          AppBar(key: ValueKey('opaqueBar'), surfaceBlur: 10),
          AppBar(
            key: ValueKey('translucentBar'),
            surfaceBlur: 10,
            surfaceOpacity: 0.5,
          ),
        ],
      ),
    ));
    expect(blurIn('opaque'), findsNothing);
    expect(blurIn('translucent'), findsOneWidget);
    expect(blurIn('opaqueBar'), findsNothing);
    expect(blurIn('translucentBar'), findsOneWidget);
  });
}
