import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke renders a placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    expect(find.byType(SizedBox), findsOneWidget);
  });
}
