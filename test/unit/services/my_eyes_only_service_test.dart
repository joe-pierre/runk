import 'package:flutter_test/flutter_test.dart';
import 'package:runk/core/services/my_eyes_only_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MyEyesOnlyService', () {
    test('hasPinSet renvoie faux tant qu\'aucun code n\'a été défini', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MyEyesOnlyService(await SharedPreferences.getInstance());

      expect(service.hasPinSet(), isFalse);
    });

    test('setPin rend hasPinSet vrai et verifyPin accepte le bon code', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MyEyesOnlyService(await SharedPreferences.getInstance());

      await service.setPin('1234');

      expect(service.hasPinSet(), isTrue);
      expect(service.verifyPin('1234'), isTrue);
    });

    test('verifyPin refuse un code incorrect', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MyEyesOnlyService(await SharedPreferences.getInstance());

      await service.setPin('1234');

      expect(service.verifyPin('0000'), isFalse);
    });

    test('verifyPin refuse tout code tant qu\'aucun n\'a été défini', () async {
      SharedPreferences.setMockInitialValues({});
      final service = MyEyesOnlyService(await SharedPreferences.getInstance());

      expect(service.verifyPin('1234'), isFalse);
    });

    test(
      'le code en clair n\'est jamais persisté, seul son hash l\'est',
      () async {
        SharedPreferences.setMockInitialValues({});
        final preferences = await SharedPreferences.getInstance();
        final service = MyEyesOnlyService(preferences);

        await service.setPin('1234');

        final storedValue = preferences.getString('my_eyes_only_pin_hash');
        expect(storedValue, isNotNull);
        expect(storedValue, isNot('1234'));
      },
    );

    test(
      'resetPin efface le code enregistré : hasPinSet redevient faux et '
      'verifyPin refuse l\'ancien code',
      () async {
        SharedPreferences.setMockInitialValues({});
        final service = MyEyesOnlyService(await SharedPreferences.getInstance());
        await service.setPin('1234');

        await service.resetPin();

        expect(service.hasPinSet(), isFalse);
        expect(service.verifyPin('1234'), isFalse);
      },
    );
  });
}
