import 'package:flutter/cupertino.dart' as c;
import 'package:flutter/material.dart' as m;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

int _byte(double channel) => (channel * 255).round();

void main() {
  test('ColorShades channels use the 0..255 range', () {
    const shades = Colors.red;
    final base = shades.shade500;
    expect(shades.alpha, 255);
    expect(shades.red, _byte(base.r));
    expect(shades.green, _byte(base.g));
    expect(shades.blue, _byte(base.b));

    final faded = shades.withValues(alpha: 0.5);
    expect(faded.a, closeTo(0.5, 0.001));
    expect(faded.r, base.r);
    expect(faded.g, base.g);

    // withBlue shifts every shade by the same delta as the base shade.
    final shifted = shades.withBlue(shades.blue + 10);
    expect(_byte(shifted.shade500.b), _byte(base.b) + 10);
    expect(_byte(shifted.shade200.b), _byte(shades.shade200.b) + 10);
  });

  testWidgets('material and cupertino themes follow the active dark theme',
      (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    late BuildContext ctx;
    await tester.pumpWidget(ShadcnApp(
      theme: ThemeData(colorScheme: ColorSchemes.lightZinc(), radius: 0.5),
      darkTheme: ThemeData(colorScheme: ColorSchemes.darkZinc(), radius: 0.5),
      home: Builder(builder: (context) {
        ctx = context;
        return const SizedBox();
      }),
    ));
    expect(m.Theme.of(ctx).brightness, Brightness.dark);
    expect(c.CupertinoTheme.of(ctx).brightness, Brightness.dark);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    await tester.pump();
    expect(m.Theme.of(ctx).brightness, Brightness.light);
    expect(c.CupertinoTheme.of(ctx).brightness, Brightness.light);
  });
}
