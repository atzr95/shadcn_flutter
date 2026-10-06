import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Widget _app(Widget child) {
  return ShadcnApp(
    theme: ThemeData(colorScheme: ColorSchemes.darkZinc(), radius: 0.5),
    home: Scaffold(child: Center(child: child)),
  );
}

void main() {
  testWidgets('MultiSelect reports popup changes to its Form', (tester) async {
    const key = FormKey<List<String>>('tags');
    final controller = FormController();
    addTearDown(controller.dispose);
    var value = <String>[];

    await tester.pumpWidget(_app(
      Form(
        controller: controller,
        child: FormEntry<List<String>>(
          key: key,
          child: StatefulBuilder(
            builder: (context, setState) => MultiSelect<String>(
              value: value,
              popoverContext: context,
              itemBuilder: (context, item) => Text(item),
              onChanged: (v) => setState(() => value = v),
              children: const [
                SelectItemButton(value: 'a', child: Text('Apple')),
                SelectItemButton(value: 'b', child: Text('Banana')),
              ],
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(MultiSelect<String>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byWidgetPredicate(
        (w) => w is SelectItemButton<String> && w.value == 'b'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(value, ['b']);
    expect(controller.values[key], ['b']);
  });
}
