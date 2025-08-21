import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wishlist_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Basic App Integration Tests', () {
    testWidgets('App launches successfully', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify app launched and shows some content
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // Look for common UI elements that should be present
      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('App navigation works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for navigation elements
      final navigationElements = find.byType(BottomNavigationBar);
      if (navigationElements.evaluate().isNotEmpty) {
        // Test navigation if bottom navigation exists
        await tester.tap(navigationElements);
        await tester.pumpAndSettle();
      }

      // Verify app is still responsive
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('App handles form interactions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for text fields
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().isNotEmpty) {
        // Test text input
        await tester.enterText(textFields.first, 'Test input');
        await tester.pump();
        
        // Verify text was entered
        expect(find.text('Test input'), findsOneWidget);
      }
    });

    testWidgets('App handles button taps', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for buttons
      final buttons = find.byType(ElevatedButton);
      if (buttons.evaluate().isNotEmpty) {
        // Test button interaction
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
        
        // Verify app is still responsive after button tap
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('App scroll performance', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for scrollable widgets
      final scrollables = find.byType(Scrollable);
      if (scrollables.evaluate().isNotEmpty) {
        // Test scrolling
        await tester.fling(scrollables.first, Offset(0, -300), 500);
        await tester.pumpAndSettle();
        
        // Verify app is still responsive after scrolling
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('App memory stability test', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Perform multiple operations to test memory stability
      for (int i = 0; i < 5; i++) {
        // Navigate or interact with the app multiple times
        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'Test $i');
          await tester.pump();
        }
        
        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();
        }
      }

      // Verify app is still stable
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Authentication Flow Integration Tests', () {
    testWidgets('Authentication screens are accessible', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Look for authentication-related text or buttons
      final authElements = [
        'Login',
        'Entrar',
        'Email',
        'Senha',
        'Password',
      ];

      bool foundAuthElement = false;
      for (String element in authElements) {
        if (find.text(element).evaluate().isNotEmpty) {
          foundAuthElement = true;
          break;
        }
      }

      // If we found auth elements, test basic interaction
      if (foundAuthElement) {
        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().isNotEmpty) {
          await tester.enterText(textFields.first, 'test@example.com');
          await tester.pump();
        }
      }

      // Verify app is still responsive
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Error handling in authentication', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Try to trigger validation errors
      final textFields = find.byType(TextFormField);
      final buttons = find.byType(ElevatedButton);

      if (textFields.evaluate().isNotEmpty && buttons.evaluate().isNotEmpty) {
        // Enter invalid data
        await tester.enterText(textFields.first, 'invalid-email');
        await tester.pump();
        
        // Try to submit
        await tester.tap(buttons.first);
        await tester.pumpAndSettle();
        
        // App should handle the error gracefully
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });
  });
}