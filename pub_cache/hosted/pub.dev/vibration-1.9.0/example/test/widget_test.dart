import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/main.dart';

void main() {
  testWidgets(
    'Buttons rendered',
    (WidgetTester tester) async {
      await tester.pumpWidget(const VibratingApp());

      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is ElevatedButton,
        ),
        findsNWidgets(3),
      );
    },
  );
}
