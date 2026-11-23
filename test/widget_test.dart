// Smoke tests for Geezus Flutter app.
// These tests verify pure logic only — no Flutter widget pumping,
// since that would require Supabase, SQLite, and sensor initialization.

import 'package:flutter_test/flutter_test.dart';
import 'package:geezus/core/services/gym_store.dart';
import 'package:geezus/features/ai_coach/controllers/ai_coach_controller.dart';

void main() {
  group('GymStore — basic calculations', () {
    setUp(() {
      GymStore.instance.resetForTesting();
    });

    test('totalVolumeKg starts at 0 after reload', () {
      expect(GymStore.instance.totalVolumeKg, equals(0.0));
    });

    test('gymDamage and runDamage start at 0 after reload', () {
      expect(GymStore.instance.gymDamage, equals(0));
      expect(GymStore.instance.runDamage, equals(0));
      expect(GymStore.instance.totalBaseDamage, equals(0));
    });

    test('addRunDistance updates weeklyRunKm and runDamage', () {
      GymStore.instance.addRunDistance(5.0);
      expect(GymStore.instance.weeklyRunKm, equals(5.0));
      expect(GymStore.instance.runDamage, equals(125)); // 5 * 25
    });

    test('addRunDistance ignores zero/negative values', () {
      GymStore.instance.addRunDistance(0.0);
      GymStore.instance.addRunDistance(-3.0);
      expect(GymStore.instance.weeklyRunKm, equals(0.0));
    });
  });

  group('AiCoachController — API key check', () {
    test('isApiKeyConfigured is false when no key is provided', () {
      // In test environment, .env is not loaded and no --dart-define is set
      // so the key should be empty / unconfigured
      final key = AiCoachController.apiKey;
      if (key.isEmpty ||
          key == 'YOUR_GEMINI_API_KEY_HERE' ||
          key.startsWith('YOUR_')) {
        expect(AiCoachController.isApiKeyConfigured, isFalse);
      }
      // If a key IS configured, the check should pass too
      // (this handles CI environments where the key might be injected)
    });
  });
}
