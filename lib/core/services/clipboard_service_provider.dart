import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'clipboard_history_store.dart';
import 'clipboard_service.dart';

part 'clipboard_service_provider.g.dart';

/// Instance unique de [ClipboardHistoryStore], appuyée sur l'instance
/// partagée de `SharedPreferences` de l'appareil.
///
/// `keepAlive: true` : l'historique des liens vus doit rester cohérent
/// pendant toute la durée de vie de l'app.
@Riverpod(keepAlive: true)
Future<ClipboardHistoryStore> clipboardHistoryStore(Ref ref) async {
  final preferences = await SharedPreferences.getInstance();
  return ClipboardHistoryStore(preferences);
}

/// Instance unique de [ClipboardService] pour toute l'application.
///
/// `keepAlive: true` : comme `shareIntentServiceProvider`, l'observation du
/// cycle de vie doit rester active pendant toute la durée de vie de l'app,
/// jamais recréée entre deux écrans. Libérée via [ClipboardService.dispose]
/// si le provider est un jour invalidé (ne devrait pas arriver en usage
/// normal).
@Riverpod(keepAlive: true)
Future<ClipboardService> clipboardService(Ref ref) async {
  final historyStore = await ref.watch(clipboardHistoryStoreProvider.future);
  final service = ClipboardService(historyStore);
  service.initialize();
  ref.onDispose(service.dispose);
  return service;
}
