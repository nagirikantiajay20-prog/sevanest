// "Your choices so far" summary cells (ChoicesTicket / ChoicesGrid) must not cut their values with
// an ellipsis at larger text sizes, wrap instead of overflowing, and stay tappable.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/choices_ticket.dart';
import 'package:sevanest_customer/features/service_discovery/presentation/widgets/discover_chrome.dart';

import '../../helpers/real_fonts.dart';

TicketCell _cell(String caption, String name, {VoidCallback? onChange}) =>
    TicketCell(
      caption: caption,
      name: name,
      icon: Icons.place_outlined,
      semanticLabel: '$caption $name',
      onChange: onChange ?? () {},
      changeKey: Key('cell_$caption'),
    );

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  required double width,
  required double scale,
}) async {
  t.view
    ..physicalSize = Size(width * 3, 2400)
    ..devicePixelRatio = 3;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(() {
    t.view.reset();
    t.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await t.pumpWidget(
    MaterialApp(
      home: DiscoverClock(
        clock: ValueNotifier<double>(0),
        child: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    ),
  );
}

/// Names that were cut with an ellipsis.
List<String> _clipped(WidgetTester t, Iterable<String> names) => [
  for (final n in names)
    if (t.renderObject<RenderParagraph>(find.text(n)).didExceedMaxLines) n,
];

void main() {
  setUpAll(loadRealFonts);
  const names = ['Cook', 'Part-time', 'Madhapur'];
  const longNames = [
    'Elderly Care Helper',
    'Weekdays only',
    'Madhapur Hyderabad',
  ];

  for (final width in [320.0, 360.0, 393.0, 430.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets(
        'ticket ${width.toInt()} wide at ${scale}x: no cut values, no overflow',
        (t) async {
          await _pump(
            t,
            ChoicesTicket(
              cells: [
                _cell('SERVICE', names[0]),
                _cell('TYPE', names[1]),
                _cell('AREA', names[2]),
              ],
            ),
            width: width,
            scale: scale,
          );
          expect(t.takeException(), isNull);
          expect(_clipped(t, names), isEmpty);
        },
      );

      testWidgets(
        'ticket ${width.toInt()} wide at ${scale}x: long labels wrap, whole text kept',
        (t) async {
          await _pump(
            t,
            ChoicesTicket(
              cells: [
                _cell('SERVICE', longNames[0]),
                _cell('TYPE', longNames[1]),
                _cell('AREA', longNames[2]),
              ],
            ),
            width: width,
            scale: scale,
          );
          expect(t.takeException(), isNull);
          for (final n in longNames) {
            expect(find.text(n), findsOneWidget);
          }
          // Wrapped onto a second line at most; never an ellipsis.
          expect(_clipped(t, longNames), isEmpty);
        },
      );
    }

    testWidgets('grid ${width.toInt()} wide at 1.3x: four cells, none cut', (
      t,
    ) async {
      await _pump(
        t,
        ChoicesGrid(
          cells: [
            _cell('SERVICE', 'Cook'),
            _cell('TYPE', 'Part-time'),
            _cell('AREA', 'Madhapur'),
            _cell('TIMING', 'Weekdays 6 AM – 10 AM'),
          ],
        ),
        width: width,
        scale: 1.3,
      );
      expect(t.takeException(), isNull);
      expect(
        _clipped(t, ['Cook', 'Part-time', 'Madhapur', 'Weekdays 6 AM – 10 AM']),
        isEmpty,
      );
    });
  }

  testWidgets('a cell is still tappable at 1.3x and >= 44 dp tall', (t) async {
    var taps = 0;
    await _pump(
      t,
      ChoicesTicket(cells: [_cell('AREA', 'Madhapur', onChange: () => taps++)]),
      width: 360,
      scale: 1.3,
    );
    expect(
      t.getSize(find.byKey(const Key('cell_AREA'))).height,
      greaterThanOrEqualTo(44),
    );
    await t.tap(find.byKey(const Key('cell_AREA')));
    expect(taps, 1);
  });
}
