import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(myApp());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('Set Random'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Set Random'));
    await tester.tap(find.text('Clear'));
    await tester.pump();

    expect(find.text('0'), findsOneWidget);
  });
}
