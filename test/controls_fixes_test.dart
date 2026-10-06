import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Widget _app(Widget child, {TargetPlatform? platform}) => ShadcnApp(
      theme: ThemeData(
        colorScheme: ColorSchemes.lightZinc(),
        radius: 0.5,
        platform: platform,
      ),
      home: Center(child: child),
    );

void main() {
  testWidgets('Clickable: disabled gets no press, and disabling mid-press '
      'clears pressed/hovered', (tester) async {
    final states = WidgetStatesController();
    addTearDown(states.dispose);
    final enabled = ValueNotifier(true);
    addTearDown(enabled.dispose);
    var downs = 0;
    await tester.pumpWidget(_app(
      ValueListenableBuilder<bool>(
        valueListenable: enabled,
        builder: (context, value, _) => Clickable(
          statesController: states,
          enabled: value,
          onPressed: () {},
          onTapDown: (_) => downs++,
          child: const SizedBox(width: 40, height: 40),
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
  });
}
