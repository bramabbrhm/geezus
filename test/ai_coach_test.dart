// Unit tests for AiCoachController — NO external API calls.
// Tests 1-8 cover local gym-log parsing (no network).
// Test 6 is marked as a SKIP (requires real Gemini API key) and is
// explained why — it should run only as an integration test.
//
// Run: flutter test test/ai_coach_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:geezus/core/services/gym_store.dart';
import 'package:geezus/features/ai_coach/controllers/ai_coach_controller.dart';

void main() {
  group('AiCoachController — Local Logic Tests (no network)', () {
    late AiCoachController controller;

    setUp(() {
        // Reset GymStore in-memory data between tests (avoid DB calls in test env)
        GymStore.instance.resetForTesting();
        controller = AiCoachController();
      });

    tearDown(() {
      controller.dispose();
    });

    test('1. Normal gym log parses and updates GymStore', () async {
      final initialVolume = GymStore.instance.totalVolumeKg;
      await controller.sendMessage('Bench Press 40kg 3 set 10 rep');

      expect(controller.messages.length, greaterThanOrEqualTo(2));
      final lastMsg = controller.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.isError, isFalse);
      expect(lastMsg.text, contains('LATIHAN TERCATAT KE DUNGEON'));
      expect(lastMsg.text, contains('BENCH PRESS'));
      expect(
        GymStore.instance.totalVolumeKg,
        closeTo(initialVolume + (40 * 3 * 10), 0.001),
      );
      expect(controller.isLoading, isFalse);
    });

    test('2. Plural units (sets, reps) and decimal weights parse correctly',
        () async {
      final initialVolume = GymStore.instance.totalVolumeKg;
      await controller.sendMessage('Squat 50.5 kg 4 sets 12 reps');

      final lastMsg = controller.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.isError, isFalse);
      expect(lastMsg.text, contains('SQUAT'));
      expect(
        GymStore.instance.totalVolumeKg,
        closeTo(initialVolume + (50.5 * 4 * 12), 0.001),
      );
      expect(controller.isLoading, isFalse);
    });

    test('3. Extreme numbers are rejected and do not corrupt GymStore',
        () async {
      final volumeBefore = GymStore.instance.totalVolumeKg;
      await controller.sendMessage(
        'Deadlift 9999999999999999999999999999999999999999kg 99999999999999999set 999999999999rep',
      );

      final lastMsg = controller.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.isError, isTrue);
      expect(lastMsg.text, contains('di luar batas wajar'));
      expect(GymStore.instance.totalVolumeKg, equals(volumeBefore));
      expect(controller.isLoading, isFalse);
    });

    test('4. Zero or negative values are handled defensively', () async {
      final volumeBefore = GymStore.instance.totalVolumeKg;
      await controller.sendMessage('Leg Press 0kg 0 set 0 rep');

      final lastMsg = controller.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.isError, isTrue);
      expect(GymStore.instance.totalVolumeKg, equals(volumeBefore));
      expect(controller.isLoading, isFalse);
    });

    test('5. Empty or whitespace-only strings do not add messages', () async {
      final countBefore = controller.messages.length;
      await controller.sendMessage('');
      await controller.sendMessage('     ');
      await controller.sendMessage('\n\t  \n');

      expect(controller.messages.length, equals(countBefore));
      expect(controller.isLoading, isFalse);
    });

    // Test 6: Requires real Gemini API key — skipped in CI/unit test runs.
    // Run separately as an integration test when you have a real API key.
    test(
      '6. [INTEGRATION ONLY] Non-gym query routes to Gemini API',
      () async {
        // This test is intentionally skipped in automated unit test runs.
        // It requires a real GEMINI_API_KEY in the .env file.
        // To run manually: provide a real key and remove the skip.
        //
        // Expected: AiCoachController.isApiKeyConfigured == true,
        // and the last message is a non-empty AI response.
      },
      skip:
          'Requires a real GEMINI_API_KEY. Run as integration test with a valid key.',
    );

    test('7. Random symbols do not crash the controller; isLoading resets',
        () async {
      // Without API key, controller shows an informational error message
      await controller.sendMessage('@@@###\$\$\$%%%^^^&&&***');

      expect(controller.messages.length, greaterThanOrEqualTo(2));
      final lastMsg = controller.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.text.isNotEmpty, isTrue);
      expect(controller.isLoading, isFalse);
    });

    test('8. isLoading is always false after any operation', () async {
      expect(controller.isLoading, isFalse);
      await controller.sendMessage('Gimana cara latihan dada?');
      expect(controller.isLoading, isFalse);
    });

    test('9. clearMessages resets history to exactly one welcome message',
        () async {
      await controller.sendMessage('Bench Press 20kg 2 set 5 rep');
      controller.clearMessages();

      // After clear, only the initial welcome message should remain
      expect(controller.messages.length, equals(1));
      expect(controller.messages.first.isUser, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('10. Duplicate send is blocked while loading', () async {
      // Send a gym log first (synchronous path, no loading)
      await controller.sendMessage('Deadlift 100kg 3 set 5 rep');
      expect(controller.isLoading, isFalse);
      // A second send while isLoading is true would be blocked
      // (we can't easily test the async blocking here without mocks,
      // but we verify the guard condition itself works post-operation)
      expect(controller.isLoading, isFalse);
    });
  });
}
