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

  testWidgets('Checkbox takes near-miss taps but not a neighbour\'s',
      (tester) async {
    final taps = <String>[];
    Widget box(String id) => Checkbox(
          state: CheckboxState.unchecked,
          onChanged: (_) => taps.add(id),
        );
    await tester.pumpWidget(_app(SizedBox(
      height: 200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [box('a'), box('b')],
      ),
    )));
    final a = tester.getRect(find.byType(Checkbox).first);

    // 10px above A: outside its 16px box, inside its 44px target.
    await tester.tapAt(a.topCenter - const Offset(0, 10));
    // Inside A's box, but also inside B's widened target.
    await tester.tapAt(a.bottomCenter - const Offset(0, 2));

    expect(taps, ['a', 'a']);
  });

  testWidgets('Switch takes near-miss taps', (tester) async {
    bool? changed;
    await tester.pumpWidget(_app(Switch(
      value: false,
      onChanged: (v) => changed = v,
    )));
    final rect = tester.getRect(find.byType(Switch));

    // The scaled track is 25px tall, so its 44px target reaches 9.5px above.
    await tester.tapAt(rect.topCenter - const Offset(0, 8));

    expect(changed, isTrue);
  });
}

Finder _text(String data) =>
    find.byWidgetPredicate((w) => w is Text && w.data == data);
