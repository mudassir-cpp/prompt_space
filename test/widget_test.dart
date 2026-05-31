import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prompt_space/app_theme.dart';
import 'package:prompt_space/screens/home_page.dart';

void main() {
  testWidgets('renders the redesigned app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const HomePage(forceDemo: true),
      ),
    );
    await tester.pump();

    expect(find.text('Prompt Space'), findsOneWidget);
    expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
  });
}
