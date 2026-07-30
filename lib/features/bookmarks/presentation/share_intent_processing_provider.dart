import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_intent_processing_provider.g.dart';

/// Vrai tant qu'une URL reçue via Share Intent est en cours de traitement
/// par `ShareIntentGate` (modale `AddBookmarkSheet` ouverte ou URL en
/// attente dans sa file, voir SPEC.md section 13).
///
/// Mis à jour uniquement par `ShareIntentGate`. Consulté par la logique de
/// suggestion clipboard (`ClipboardSuggestion`) pour respecter la priorité
/// Share Intent (action explicite) > suggestion clipboard (action passive)
/// documentée en SPEC.md section 13.
///
/// Vit dans `features/bookmarks/presentation/` plutôt que dans
/// `core/services/share_intent_service.dart` : ce dernier n'expose aucun
/// état de file d'attente (celle-ci vit dans `ShareIntentGate`, voir
/// TASK_PROMPTS.md Tâche 6.5), et la consigne de la tâche interdit
/// explicitement de le modifier — voir DECISIONS.md, entrée "Tâche 6.5".
@riverpod
class ShareIntentProcessing extends _$ShareIntentProcessing {
  @override
  bool build() => false;

  /// Bascule l'état — appelé par `ShareIntentGate` juste avant et juste
  /// après le traitement de sa file d'attente.
  void set(bool value) => state = value;
}
