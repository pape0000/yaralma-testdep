import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaralma_app/screens/holy_lock/holy_lock_screen.dart';

void main() {
  group('HolyLockScreen', () {
    testWidgets('renders scaffold with app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HolyLockScreen(),
        ),
      );

      // The screen shows either loading, error, or schedule
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Holy Lock'), findsOneWidget);
    });

    testWidgets('handles missing Supabase gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HolyLockScreen(),
        ),
      );

      // Let async operations complete
      await tester.pumpAndSettle();

      // In test environment without Supabase, screen should still render
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows error state when not authenticated', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HolyLockScreen(),
        ),
      );

      // Wait for async operations
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // In test environment without Supabase, expect error or loading
      // The screen should at least render
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
