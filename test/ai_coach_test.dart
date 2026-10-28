import 'package:flutter_test/flutter_test.dart';
import 'package:geezus/core/services/gym_store.dart';
import 'package:geezus/features/ai_coach/controllers/ai_coach_controller.dart';

void main() {
  group('AiCoachController - Defensive Programming & Timeout Tests', () {
    late AiCoachController controller;

    setUp(() {
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
      expect(GymStore.instance.totalVolumeKg, equals(initialVolume + (40 * 3 * 10)));
      expect(controller.isLoading, isFalse);
    });

    test('2. Case with plural units (sets, reps) and decimal weights', () async {
      final initialVolume = GymStore.instance.totalVolumeKg;
      await controller.sendMessage('Squat 50.5 kg 4 sets 12 reps');

      final lastMsg = controller.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.isError, isFalse);
      expect(lastMsg.text, contains('SQUAT'));
      expect(GymStore.instance.totalVolumeKg, equals(initialVolume + (50.5 * 4 * 12)));
      expect(controller.isLoading, isFalse);
    });

    test('3. Extreme number input does not crash or corrupt GymStore', () async {
      final volumeBefore = GymStore.instance.totalVolumeKg;
      await controller.sendMessage(
        'Deadlift 9999999999999999999999999999999999999999kg 99999999999999999set 999999999999rep',
      );

      final lastMsg = controller.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.isError, isTrue);
      expect(lastMsg.text, contains('di luar batas wajar'));
      // GymStore volume should not change
      expect(GymStore.instance.totalVolumeKg, equals(volumeBefore));
      expect(controller.isLoading, isFalse);
    });

    test('4. Zero or negative values handled defensively', () async {
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

    test('6. Non-gym query successfully routes to Gemini API and receives response', () async {
      expect(AiCoachController.isApiKeyConfigured, isTrue);

      await controller.sendMessage('Halo coach, berikan satu tips singkat untuk lari.');

      expect(controller.messages.length, greaterThanOrEqualTo(2));
      final lastMsg = controller.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.text.isNotEmpty, isTrue);
      expect(controller.isLoading, isFalse);
    });

    test('7. Random symbols and long text without spaces do not crash the controller and resets isLoading', () async {
      await controller.sendMessage('@@@###\$\$\$%%%^^^&&&***');

      expect(controller.messages.length, greaterThanOrEqualTo(2));
      final lastMsg = controller.messages.last;
      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.text.isNotEmpty, isTrue);
      expect(controller.isLoading, isFalse);
    });

    test('8. Automatic state cleanup: isLoading is always false after operations', () async {
      expect(controller.isLoading, isFalse);
      await controller.sendMessage('Gimana cara latihan dada?');
      expect(controller.isLoading, isFalse);
    });
  });
}
