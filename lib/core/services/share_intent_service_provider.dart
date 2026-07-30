import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'share_intent_service.dart';

part 'share_intent_service_provider.g.dart';

/// Instance unique de [ShareIntentService] pour toute l'application.
///
/// `keepAlive: true` : le service doit rester actif (et son flux écouté)
/// pendant toute la durée de vie de l'app, jamais recréé entre deux écrans.
/// Libéré via [ShareIntentService.dispose] si le provider est un jour
/// invalidé (ne devrait pas arriver en usage normal).
@Riverpod(keepAlive: true)
ShareIntentService shareIntentService(Ref ref) {
  final service = ShareIntentService();
  ref.onDispose(service.dispose);
  return service;
}
