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
}
