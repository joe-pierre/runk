// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clipboard_suggestion_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(ClipboardSuggestion)
final clipboardSuggestionProvider = ClipboardSuggestionProvider._();

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
final class ClipboardSuggestionProvider
    extends $NotifierProvider<ClipboardSuggestion, String?> {
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
  ClipboardSuggestionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clipboardSuggestionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clipboardSuggestionHash();

  @$internal
  @override
  ClipboardSuggestion create() => ClipboardSuggestion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$clipboardSuggestionHash() =>
    r'a74a2502875e8ce24599a6e6626fdb6097163ab1';

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

abstract class _$ClipboardSuggestion extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
