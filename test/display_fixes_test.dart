import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  group('Avatar.getInitials', () {
    test('keeps the existing output for normal names', () {
      expect(Avatar.getInitials('John Doe'), 'JD');
      expect(Avatar.getInitials('john'), 'JO');
      expect(Avatar.getInitials('J'), 'J');
      expect(Avatar.getInitials("Conan O'Brien"), 'CO');
    });

    test('uses the first and last words', () {
      expect(Avatar.getInitials('John Michael Doe'), 'JD');
    });

    test('does not crash on empty or odd spacing', () {
      expect(Avatar.getInitials(''), '');
      expect(Avatar.getInitials('   '), '');
      expect(Avatar.getInitials('123 !'), '');
      expect(Avatar.getInitials('Ali '), 'AL');
      expect(Avatar.getInitials('Ali  Bakar'), 'AB');
      expect(Avatar.getInitials(' Ali\tBakar '), 'AB');
    });

    test('works for non-Latin names', () {
      expect(Avatar.getInitials('陈大文'), '陈大');
      expect(Avatar.getInitials('陈 大文'), '陈大');
      expect(Avatar.getInitials('Élodie Durand'), 'ÉD');
      // decomposed É (E + combining accent) stays one character
      expect(Avatar.getInitials('Élodie Durand'), 'ÉD');
    });
  });

  group('Progress.normalizedValue', () {
    test('maps into 0..1 and clamps out-of-range values', () {
      expect(const Progress(progress: 15, min: 10, max: 20).normalizedValue,
          0.5);
      expect(const Progress(progress: 1.5).normalizedValue, 1.0);
      expect(const Progress(progress: -1).normalizedValue, 0.0);
      expect(const Progress().normalizedValue, isNull);
    });
  });

  testWidgets('LinearProgressIndicator does not restart on a plain rebuild',
      (tester) async {
    double value = 0.5;
    StateSetter? setState;
    await tester.pumpWidget(
      ShadcnApp(
        theme: ThemeData(colorScheme: ColorSchemes.darkZinc(), radius: 0.5),
        home: StatefulBuilder(builder: (context, set) {
          setState = set;
          return LinearProgressIndicator(value: value);
        }),
      ),
    );
    await tester.pumpAndSettle();

    setState!(() {});
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    setState!(() => value = 0.8);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
  });
}
