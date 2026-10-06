import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
// Hover is not exported; Tooltip imports it the same way.
import 'package:shadcn_flutter/src/components/control/hover.dart';

Widget _app(Widget child, {TargetPlatform? platform}) => ShadcnApp(
      theme: ThemeData(
        colorScheme: ColorSchemes.lightZinc(),
        radius: 0.5,
        platform: platform,
      ),
      home: Center(child: child),
    );

void main() {
  testWidgets(
      'Clickable: disabled gets no press, and disabling mid-press '
      'clears pressed/hovered', (tester) async {
    final states = WidgetStatesController();
    addTearDown(states.dispose);
    final enabled = ValueNotifier(true);
    addTearDown(enabled.dispose);
    var downs = 0;
    var parentTaps = 0;
    await tester.pumpWidget(_app(
      GestureDetector(
        onTap: () => parentTaps++,
        child: ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (context, value, _) => Clickable(
            statesController: states,
            enabled: value,
            onPressed: () {},
            onTapDown: (_) => downs++,
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    ));
    final center = tester.getCenter(find.byType(Clickable));

    var gesture = await tester.startGesture(center);
    await tester.pump(kPressTimeout);
    expect(states.value, contains(WidgetState.pressed));
    expect(downs, 1);

    enabled.value = false;
    await tester.pump();
    expect(states.value, isNot(contains(WidgetState.pressed)));
    expect(states.value, isNot(contains(WidgetState.hovered)));
    await gesture.up();
    await tester.pump();

    gesture = await tester.startGesture(center);
    await tester.pump(kPressTimeout);
    expect(states.value, isNot(contains(WidgetState.pressed)));
    expect(downs, 1);
    await gesture.up();
    await tester.pump();
    // A disabled button still absorbs the tap.
    expect(parentTaps, 0);
  });

  testWidgets(
      'ButtonGroup: const children, RTL inner corners, '
      'corners kept after theme change', (tester) async {
    // Theme swapped below a const group, so the group and its overrides are
    // not rebuilt; only the buttons' dependencies change.
    final dark = ValueNotifier(false);
    addTearDown(dark.dispose);
    await tester.pumpWidget(_app(
      ValueListenableBuilder<bool>(
        valueListenable: dark,
        builder: (context, isDark, child) => Theme(
          data: ThemeData(
            colorScheme:
                isDark ? ColorSchemes.darkZinc() : ColorSchemes.lightZinc(),
            radius: 0.5,
          ),
          child: child!,
        ),
        child: const Directionality(
          textDirection: TextDirection.rtl,
          child: ButtonGroup(children: [
            PrimaryButton(key: ValueKey('first'), child: Text('A')),
            PrimaryButton(key: ValueKey('last'), child: Text('B')),
          ]),
        ),
      ),
    ));

    BorderRadius radiusOf(String key) {
      final container = tester.widget<AnimatedContainer>(find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(AnimatedContainer),
      ));
      return (container.decoration! as BoxDecoration).borderRadius!
          as BorderRadius;
    }

    void expectInnerCornersSquare() {
      // RTL: the first child sits on the right, so its left side is inner.
      final first = radiusOf('first');
      expect(first.topLeft, Radius.zero);
      expect(first.bottomLeft, Radius.zero);
      expect(first.topRight, isNot(Radius.zero));
      final last = radiusOf('last');
      expect(last.topRight, Radius.zero);
      expect(last.bottomRight, Radius.zero);
      expect(last.topLeft, isNot(Radius.zero));
    }

    expectInnerCornersSquare();

    dark.value = true;
    await tester.pump();
    expectInnerCornersSquare();
  });

  testWidgets('Hover: touch long press stays shown ~1.5s after release',
      (tester) async {
    final events = <bool>[];
    await tester.pumpWidget(_app(
      Hover(
        // Tooltip passes this short value; the touch hold must not use it.
        showDuration: const Duration(milliseconds: 200),
        onHover: events.add,
        child: const ColoredBox(
          color: Color(0xFF000000),
          child: SizedBox(width: 40, height: 40),
        ),
      ),
      platform: TargetPlatform.android,
    ));

    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(Hover)));
    // First pump starts the ticker clock, the second advances it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(events, [true]);

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    expect(events, [true]);

    await tester.pump(const Duration(milliseconds: 600));
    expect(events, [true, false]);
  });
}
