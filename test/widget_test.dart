// Auto-generated for Student Dashboard — paste-ready.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:classmate_app/main.dart';

void main() {
  testWidgets('Student Dashboard has greeting and admin button',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify greeting text exists
    expect(find.textContaining('Hello'), findsOneWidget);

    // Verify Admin button exists with semantic label
    expect(
      find.bySemanticsLabel('Admin Access'),
      findsOneWidget,
    );

    // Verify navigation bar exists
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify search bar exists
    expect(find.byType(TextField), findsOneWidget);

    // Test admin button tap
    await tester.tap(find.bySemanticsLabel('Admin Access'));
    await tester.pumpAndSettle();

    // Should navigate to admin page
    expect(find.text('Admin Dashboard'), findsOneWidget);
  });

  testWidgets('Search bar can be typed into and cleared',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Find the search TextField
    final searchField = find.byType(TextField).first;

    // Type into search field
    await tester.enterText(searchField, 'Physics');
    await tester.pump();

    // Verify text was entered
    expect(find.text('Physics'), findsOneWidget);

    // Clear button should appear
    expect(find.byIcon(Icons.clear), findsOneWidget);

    // Tap clear button
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    // Text should be cleared
    expect(find.text('Physics'), findsNothing);
  });
}
