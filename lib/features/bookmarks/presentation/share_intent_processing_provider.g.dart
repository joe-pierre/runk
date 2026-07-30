// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_intent_processing_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(ShareIntentProcessing)
final shareIntentProcessingProvider = ShareIntentProcessingProvider._();

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
final class ShareIntentProcessingProvider
    extends $NotifierProvider<ShareIntentProcessing, bool> {
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
  ShareIntentProcessingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareIntentProcessingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareIntentProcessingHash();

  @$internal
  @override
  ShareIntentProcessing create() => ShareIntentProcessing();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$shareIntentProcessingHash() =>
    r'ae6d84afe14c2c557e6a678f015557c94bc383cb';

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

abstract class _$ShareIntentProcessing extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
