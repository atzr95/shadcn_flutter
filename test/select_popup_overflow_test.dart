import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Widget _selectUnderTest() {
  return Builder(
    builder: (selectContext) => Select<String>(
      overlayHandler: const PopoverOverlayHandler(),
      popupConstraints: const BoxConstraints(maxHeight: 300),
      popoverContext: selectContext,
      itemBuilder: (context, item) => Text(item),
      placeholder: const Text('Select a category'),
      onChanged: (v) {},
      children: const [
        SelectItemButton(value: 'employment', child: Text('💼 Employment')),
        SelectItemButton(value: 'business', child: Text('🏢 Business')),
        SelectItemButton(value: 'retirement', child: Text('🏖 Retirement')),
      ],
    ),
  );
}

Future<void> _openAndCheck(WidgetTester tester) async {
  await tester.tap(find.byType(Select<String>));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  final popupFinder = find.byType(SelectPopup<String>);
  expect(popupFinder, findsOneWidget);
  final rect = tester.getRect(popupFinder);
  final selectRect = tester.getRect(find.byType(Select<String>));
  debugPrint('select rect: $selectRect');
  debugPrint('popup rect: $rect');
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(394));
}

void main() {
  testWidgets('select popup matches a scale-transformed anchor',
      (tester) async {
    tester.view.physicalSize = const Size(394, 858);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Mimics the app's ResponsiveScaledBox(width: 450): content laid out at
    // 450 logical px, scale-transformed down to the 394 px window.
    await tester.pumpWidget(
      ShadcnApp(
        theme: ThemeData(colorScheme: ColorSchemes.darkZinc(), radius: 0.5),
        home: Scaffold(
          child: FittedBox(
            fit: BoxFit.fitWidth,
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 450,
              height: 980,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    const Gap(100),
                    _selectUnderTest(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openAndCheck(tester);
  });

  testWidgets('select popup stays on screen at narrow width', (tester) async {
    tester.view.physicalSize = const Size(394, 858);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ShadcnApp(
        theme: ThemeData(colorScheme: ColorSchemes.darkZinc(), radius: 0.5),
        home: Scaffold(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const Gap(100),
                _selectUnderTest(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openAndCheck(tester);
  });
}
