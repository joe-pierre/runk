import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/clipboard_service.dart';
import '../../../core/services/clipboard_service_provider.dart';
import 'share_intent_processing_provider.dart';

part 'clipboard_suggestion_provider.g.dart';

/// Expose à `ClipboardSuggestionBanner` l'URL actuellement suggérée par le
/// presse-papier, ou `null` si aucune suggestion active.
///
/// Applique la priorité Share Intent > clipboard (SPEC.md section 13) : une
/// URL détectée pendant qu'un Share Intent est en cours de traitement
/// (`shareIntentProcessingProvider`) n'est jamais affichée. Elle n'est pas
/// perdue pour autant — comme elle n'est marquée "vue" que sur action
/// explicite de l'utilisateur ([markAsSeen]), elle sera reproposée au
/// prochain retour au premier plan si le presse-papier contient toujours ce
/// lien.
@riverpod
class ClipboardSuggestion extends _$ClipboardSuggestion {
  StreamSubscription<String>? _subscription;

  @override
  String? build() {
    ref.onDispose(() => _subscription?.cancel());
    final serviceAsync = ref.watch(clipboardServiceProvider);
    serviceAsync.whenData(_listenTo);
    return null;
  }

  void _listenTo(ClipboardService service) {
    if (_subscription != null) return;
    _subscription = service.suggestedUrlStream.listen(_onUrlDetected);
  }

  void _onUrlDetected(String url) {
    if (ref.read(shareIntentProcessingProvider)) return;
    state = url;
  }

  /// Marque [url] comme vue (jamais reproposée, voir SPEC.md section 4
  /// règle 7) et referme la bannière. Appelé de façon identique pour
  /// "Ajouter" et pour "Ignorer" — seule l'action déclenchée par le banner
  /// diffère (ouverture ou non d'`AddBookmarkSheet`), pas le traitement de
  /// l'historique.
  Future<void> markAsSeen(String url) async {
    final service = await ref.read(clipboardServiceProvider.future);
    await service.markAsSeen(url);
    state = null;
  }
}
