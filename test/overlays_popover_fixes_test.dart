import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _app(Widget home) => ShadcnApp(
      theme: ThemeData(colorScheme: ColorSchemes.darkZinc(), radius: 0.5),
      home: home,
    );

void main() {
  testWidgets('back closes a modal popover, not the dialog under it',
      (tester) async {
    _phone(tester);
    late BuildContext pageContext;
    late BuildContext anchorContext;
    await tester.pumpWidget(_app(Builder(builder: (context) {
      pageContext = context;
      return const SizedBox();
    })));
    showDialog(
      context: pageContext,
      builder: (_) => Builder(builder: (context) {
        anchorContext = context;
        return const SizedBox(key: Key('dialog'), width: 100, height: 40);
      }),
    );
    await tester.pumpAndSettle();
    showPopover(
      context: anchorContext,
      alignment: Alignment.topCenter,
      handler: const PopoverOverlayHandler(),
      builder: (_) => const SizedBox(key: Key('popup'), width: 50, height: 50),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('popup')), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('popup')), findsNothing);
    expect(find.byKey(const Key('dialog')), findsOneWidget);

    // With the popover gone, back pops the dialog as usual.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dialog')), findsNothing);
  });

  testWidgets('popover flips above the keyboard', (tester) async {
    _phone(tester);
    tester.view.padding = const FakeViewPadding(top: 50, bottom: 34);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    late BuildContext anchorContext;
    await tester.pumpWidget(_app(Stack(children: [
      Positioned(
        top: 360,
        left: 150,
        child: Builder(builder: (context) {
          anchorContext = context;
          return const SizedBox(width: 100, height: 40);
        }),
      ),
    ])));
    showPopover(
      context: anchorContext,
      alignment: Alignment.topCenter,
      handler: const PopoverOverlayHandler(),
      builder: (_) =>
          const SizedBox(key: Key('popup'), width: 100, height: 200),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Below the anchor it would sit at 400..600, behind the keyboard (500+).
    final rect = tester.getRect(find.byKey(const Key('popup')));
    expect(rect.bottom, lessThanOrEqualTo(500));
    expect(rect.top, greaterThanOrEqualTo(50));
  });

  // Opens a card AlertDialog limited to 500 wide by the caller, the way the
  // app's BaseDialog does, and returns the card rect and theme scaling.
  Future<(Rect, double)> showCard(WidgetTester tester) async {
    late BuildContext pageContext;
    late BuildContext dialogContext;
    await tester.pumpWidget(_app(Builder(builder: (context) {
      pageContext = context;
      return const SizedBox();
    })));
    showDialog(
      context: pageContext,
      builder: (context) {
        dialogContext = context;
        return const AlertDialog(
          title: Text('t'),
          content: SizedBox(width: 600, height: 40),
        ).constrained(maxWidth: 500);
      },
    );
    await tester.pumpAndSettle();
    return (
      tester.getRect(find.byType(ModalContainer)),
      Theme.of(dialogContext).scaling,
    );
  }

  testWidgets('card AlertDialog keeps the caller width on desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final (rect, _) = await showCard(tester);
    expect(rect.width, 500);
  });

  testWidgets('short card AlertDialog: title at the start, actions at the end',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late BuildContext pageContext;
    late BuildContext dialogContext;
    await tester.pumpWidget(_app(Builder(builder: (context) {
      pageContext = context;
      return const SizedBox();
    })));
    showDialog(
      context: pageContext,
      builder: (context) {
        dialogContext = context;
        return const AlertDialog(
          title: SizedBox(key: Key('title'), width: 50, height: 20),
          actions: [SizedBox(key: Key('action'), width: 60, height: 30)],
        );
      },
    );
    await tester.pumpAndSettle();
    final scaling = Theme.of(dialogContext).scaling;
    final card = tester.getRect(find.byType(ModalContainer));
    final title = tester.getRect(find.byKey(const Key('title')));
    final action = tester.getRect(find.byKey(const Key('action')));
    expect(card.width, closeTo(512 * scaling, 0.01));
    // 24px padding plus the 1px border on each side; 1px slack for pixel snap.
    expect(title.left, closeTo(card.left + 25 * scaling, 1));
    expect(action.right, closeTo(card.right - 25 * scaling, 1));
  });

  testWidgets('card AlertDialog keeps equal side gaps on a phone',
      (tester) async {
    _phone(tester);
    tester.view.padding = const FakeViewPadding(top: 50, bottom: 34);
    final (rect, scaling) = await showCard(tester);
    expect(rect.width, closeTo(400 - 32 * scaling, 0.01));
    expect(rect.left, closeTo(400 - rect.right, 0.01));
    expect(rect.top, greaterThanOrEqualTo(50 + 16 * scaling));
  });

  testWidgets('a moving anchor re-lays out without rebuilding content',
      (tester) async {
    _phone(tester);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    late BuildContext anchorContext;
    var builds = 0;
    await tester.pumpWidget(_app(SingleChildScrollView(
      controller: scroll,
      child: Column(children: [
        const SizedBox(height: 100),
        Builder(builder: (context) {
          anchorContext = context;
          return const SizedBox(width: 100, height: 40);
        }),
        const SizedBox(height: 2000),
      ]),
    )));
    showPopover(
      context: anchorContext,
      alignment: Alignment.topCenter,
      modal: false,
      handler: const PopoverOverlayHandler(),
      builder: (_) {
        builds++;
        return const SizedBox(key: Key('popup'), width: 100, height: 100);
      },
    );
    await tester.pump(const Duration(milliseconds: 500));
    final before = tester.getRect(find.byKey(const Key('popup')));
    final buildsBefore = builds;

    scroll.jumpTo(30);
    await tester.pump();
    await tester.pump();

    final after = tester.getRect(find.byKey(const Key('popup')));
    expect(after.top, closeTo(before.top - 30, 0.01));
    expect(builds, buildsBefore);
  });
}
