import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'my_eyes_only_service.dart';

part 'my_eyes_only_service_provider.g.dart';

/// Instance unique de [MyEyesOnlyService], appuyée sur l'instance partagée
/// de `SharedPreferences` de l'appareil (même pattern que
/// `clipboardHistoryStoreProvider`).
///
/// `keepAlive: true` : le code doit rester vérifiable de façon cohérente
/// pendant toute la durée de vie de l'app.
@Riverpod(keepAlive: true)
Future<MyEyesOnlyService> myEyesOnlyService(Ref ref) async {
  final preferences = await SharedPreferences.getInstance();
  return MyEyesOnlyService(preferences);
}
