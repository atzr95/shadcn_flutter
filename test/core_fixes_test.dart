import 'package:flutter/cupertino.dart' as c;
import 'package:flutter/material.dart' as m;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
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
