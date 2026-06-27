import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stroapp_sms_admin/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(StroappSmsAdminApp(
      initialLocale: const Locale('ar'),
      initialThemeMode: ThemeMode.light,
    ));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
