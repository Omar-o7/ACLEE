import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calsnap/core/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme.dark builds a usable ThemeData', (WidgetTester tester) async {
    final theme = AppTheme.dark(arabic: false);

    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: const Scaffold(body: Text('CalSnap')),
    ));

    expect(find.text('CalSnap'), findsOneWidget);
  });
}
