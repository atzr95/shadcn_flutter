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

  testWidgets('single Calendar keeps the selected day when it is tapped again',
      (tester) async {
    final date = DateTime(2024, 5, 10);
    CalendarValue? changed;
    await tester.pumpWidget(_app(Calendar(
      view: CalendarView(2024, 5),
      value: CalendarValue.single(date),
      selectionMode: CalendarSelectionMode.single,
      onChanged: (v) => changed = v,
    )));

    await tester.tap(_text('10'));

    expect(changed, CalendarValue.single(date));
  });

  testWidgets('MonthCalendar keeps a month with a mid-month minimum enabled',
      (tester) async {
    final min = DateTime(2024, 5, 15);
    final tapped = <int>[];
    await tester.pumpWidget(_app(MonthCalendar(
      value: CalendarView(2024, 5),
      onChanged: (view) => tapped.add(view.month),
      stateBuilder: (date) =>
          date.isBefore(min) ? DateState.disabled : DateState.enabled,
    )));

    await tester.tap(_text('Apr'), warnIfMissed: false);
    await tester.tap(_text('May'));

    expect(tapped, [5]);
  });
}

Finder _text(String data) =>
    find.byWidgetPredicate((w) => w is Text && w.data == data);
