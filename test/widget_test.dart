import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lucidwheels/theme/app_theme.dart';
import 'package:lucidwheels/widgets/common/custom_button.dart';

void main() {
  testWidgets('CustomButton renders label and reacts to taps', (
    WidgetTester tester,
  ) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: Scaffold(
          body: Center(
            child: CustomButton(
              label: 'Start Monitoring',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                tapCount++;
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('Start Monitoring'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.tap(find.byType(CustomButton));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('CustomButton shows a progress indicator while loading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: const Scaffold(
          body: Center(
            child: CustomButton(
              label: 'Saving',
              isLoading: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Saving'), findsNothing);
  });
}
