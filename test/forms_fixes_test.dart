import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

const _name = FormKey<String>('name');
const _pick = FormKey<String>('pick');

Widget _app(Widget child) {
  return ShadcnApp(
    theme: ThemeData(colorScheme: ColorSchemes.lightZinc(), radius: 0.5),
    home: Scaffold(child: child),
  );
}

// Stands in for Select/DatePicker: reports a value that may be null.
class _Reporter extends StatefulWidget {
  const _Reporter(this.value);

  final String? value;

  @override
  State<_Reporter> createState() => _ReporterState();
}

class _ReporterState extends State<_Reporter> with FormValueSupplier {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reportNewFormValue<String?>(widget.value, (_) {});
  }

  @override
  void didUpdateWidget(covariant _Reporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      reportNewFormValue<String?>(widget.value, (_) {});
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

String _editableText(WidgetTester tester) {
  return tester.widget<EditableText>(find.byType(EditableText)).controller.text;
}

void main() {
  testWidgets('submitForm blocks onSubmit on a sync InvalidResult',
      (tester) async {
    var submitted = false;
    late BuildContext formContext;
    await tester.pumpWidget(_app(Form(
      onSubmit: (_, __) => submitted = true,
      child: Builder(builder: (context) {
        formContext = context;
        return const FormField<String>(
          key: _name,
          label: Text('Name'),
          validator: NotEmptyValidator(),
          child: TextField(),
        );
      }),
    )));

    final result = formContext.submitForm() as SubmissionResult;
    expect(result.errors.keys, contains(_name));
    expect(submitted, isFalse);
  });

  testWidgets('a field whose first and cleared value is null is validated',
      (tester) async {
    final controller = FormController();
    addTearDown(controller.dispose);
    Widget build(String? value) => _app(Form(
          controller: controller,
          child: FormField<String>(
            key: _pick,
            label: const Text('Pick'),
            validator: const NonNullValidator(),
            child: _Reporter(value),
          ),
        ));

    await tester.pumpWidget(build(null));
    expect(controller.values.containsKey(_pick), isTrue);
    expect(controller.getError(_pick), isA<InvalidResult>());

    await tester.pumpWidget(build('a'));
    expect(controller.values[_pick], 'a');
    expect(controller.getError(_pick), isNull);

    await tester.pumpWidget(build(null));
    expect(controller.values.containsKey(_pick), isTrue);
    expect(controller.values[_pick], isNull);
    expect(controller.getError(_pick), isA<InvalidResult>());
  });

  testWidgets('submit uses the FormEntry validator from the latest build',
      (tester) async {
    late BuildContext formContext;
    Widget build(Validator<String> validator) => _app(Form(
          child: Builder(builder: (context) {
            formContext = context;
            return FormField<String>(
              key: _name,
              label: const Text('Name'),
              validator: validator,
              child: const TextField(initialValue: 'x'),
            );
          }),
        ));

    await tester.pumpWidget(build(const LengthValidator(min: 0)));
    await tester.pumpWidget(build(const LengthValidator(min: 5)));

    final result = formContext.submitForm() as SubmissionResult;
    expect(result.errors.keys, contains(_name));
  });

  testWidgets('onEditingComplete fires once and Done still unfocuses',
      (tester) async {
    var count = 0;
    await tester.pumpWidget(_app(TextField(onEditingComplete: () => count++)));

    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isFalse);
    expect(count, 1);
  });

  testWidgets('dropping an external controller keeps the text',
      (tester) async {
    final external = TextEditingController(text: 'hello');
    addTearDown(external.dispose);

    await tester.pumpWidget(_app(TextField(controller: external)));
    await tester.pumpWidget(_app(const TextField()));

    expect(_editableText(tester), 'hello');
  });

  testWidgets('NumberInput drag stops at min going down and max going up',
      (tester) async {
    await tester.pumpWidget(_app(
      const NumberInput(initialValue: 0, min: 0, allowDecimals: false),
    ));
    await tester.drag(find.byIcon(Icons.arrow_drop_down), const Offset(0, 60));
    await tester.pump();
    expect(_editableText(tester), '0');

    await tester.pumpWidget(_app(
      const NumberInput(
          key: ValueKey('max'),
          initialValue: 10,
          max: 10,
          allowDecimals: false),
    ));
    await tester.drag(find.byIcon(Icons.arrow_drop_up), const Offset(0, -60));
    await tester.pump();
    expect(_editableText(tester), '10');
  });

  testWidgets('validators fall back to English without a delegate',
      (tester) async {
    late BuildContext context;
    await tester.pumpWidget(Builder(builder: (c) {
      context = c;
      return const SizedBox();
    }));

    // int bound: used to throw (null localizations, then int -> double).
    final min = const MinValidator<int>(5)
        .validate(context, 3, FormValidationMode.submitted);
    expect((min as InvalidResult).message, 'Must be greater than or equal to 5');

    // There is no localized "equal to" string; it used to throw.
    final equal = const CompareTo<num>.equal(1)
        .validate(context, 2, FormValidationMode.submitted);
    expect((equal as InvalidResult).message, 'Invalid value');
  });
}
