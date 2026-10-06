import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

const _longText = 'one two three four five six seven eight nine ten eleven';

Widget _app(Widget child) {
  return ShadcnApp(
    theme: ThemeData(colorScheme: ColorSchemes.darkZinc(), radius: 0.5),
    home: Align(alignment: Alignment.topLeft, child: child),
  );
}

RenderTableLayout _table(WidgetTester tester) =>
    tester.renderObject<RenderTableLayout>(find.byType(RawTableLayout));

/// The cell render box placed at [column] of row 0.
RenderBox _cell(RenderTableLayout table, int column) {
  RenderBox? child = table.firstChild;
  while (child != null) {
    final data = child.parentData as TableParentData;
    if (data.row == 0 && data.column == column) return child;
    child = table.childAfter(child);
  }
  throw StateError('no cell at column $column');
}

void main() {
  testWidgets('empty table lays out without throwing', (tester) async {
    await tester.pumpWidget(_app(const Table(rows: [])));
    expect(tester.takeException(), isNull);
    expect(_table(tester).columnWidths, isEmpty);
  });

  testWidgets('flex columns get content width when width is unbounded',
      (tester) async {
    await tester.pumpWidget(_app(const SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(rows: [
        TableRow(cells: [
          TableCell(child: Text('a')),
          TableCell(child: Text('bb')),
          TableCell(child: Text('ccc')),
        ]),
      ]),
    )));
    expect(tester.takeException(), isNull);
    final table = _table(tester);
    expect(table.columnWidths, hasLength(3));
    expect(table.columnWidths, everyElement(greaterThan(0)));
    expect(table.size.width, table.columnWidths.reduce((a, b) => a + b));
  });

  testWidgets('row height is the tallest cell, measured at its column width',
      (tester) async {
    await tester.pumpWidget(_app(const SizedBox(
      width: 200,
      child: Table(rows: [
        TableRow(cells: [
          TableCell(child: Text('a')),
          TableCell(child: Text(_longText)),
        ]),
      ]),
    )));
    final table = _table(tester);
    expect(table.columnWidths, [100, 100]);
    final tall = _cell(table, 1).getMaxIntrinsicHeight(100);
    // the long text must wrap, or this test proves nothing
    expect(tall, greaterThan(_cell(table, 0).getMaxIntrinsicHeight(100)));
    expect(table.rowHeights[0], tall);
    // intrinsic height uses the same column widths as layout
    expect(table.getMaxIntrinsicHeight(200), table.size.height);
  });
}
