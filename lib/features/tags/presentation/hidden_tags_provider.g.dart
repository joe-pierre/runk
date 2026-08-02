// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hidden_tags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Expose les noms des tags masqués (`TagEntity.isHidden == true`, Tâche 25,
/// voir DECISIONS.md), triés par ordre alphabétique insensible à la casse —
/// symétrique de `distinctTagsProvider`, qui les exclut au contraire.
///
/// Consommé uniquement par `MyEyesOnlyScreen`
/// (`features/bookmarks/presentation/`, via `HiddenTagListTile`) : jamais
/// par `TagsScreen` ni aucun écran de navigation normale — le masquage de
/// tag ne doit jamais y apparaître (voir DECISIONS.md, entrée « Tâche 25 »).
/// Ne fait aucun accès propre à Isar : délègue entièrement à
/// [tagRepositoryProvider] (voir CONVENTIONS.md section Partials / Frontend).

@ProviderFor(hiddenTags)
final hiddenTagsProvider = HiddenTagsProvider._();

/// Expose les noms des tags masqués (`TagEntity.isHidden == true`, Tâche 25,
/// voir DECISIONS.md), triés par ordre alphabétique insensible à la casse —
/// symétrique de `distinctTagsProvider`, qui les exclut au contraire.
///
/// Consommé uniquement par `MyEyesOnlyScreen`
/// (`features/bookmarks/presentation/`, via `HiddenTagListTile`) : jamais
/// par `TagsScreen` ni aucun écran de navigation normale — le masquage de
/// tag ne doit jamais y apparaître (voir DECISIONS.md, entrée « Tâche 25 »).
/// Ne fait aucun accès propre à Isar : délègue entièrement à
/// [tagRepositoryProvider] (voir CONVENTIONS.md section Partials / Frontend).

final class HiddenTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Expose les noms des tags masqués (`TagEntity.isHidden == true`, Tâche 25,
  /// voir DECISIONS.md), triés par ordre alphabétique insensible à la casse —
  /// symétrique de `distinctTagsProvider`, qui les exclut au contraire.
  ///
  /// Consommé uniquement par `MyEyesOnlyScreen`
  /// (`features/bookmarks/presentation/`, via `HiddenTagListTile`) : jamais
  /// par `TagsScreen` ni aucun écran de navigation normale — le masquage de
  /// tag ne doit jamais y apparaître (voir DECISIONS.md, entrée « Tâche 25 »).
  /// Ne fait aucun accès propre à Isar : délègue entièrement à
  /// [tagRepositoryProvider] (voir CONVENTIONS.md section Partials / Frontend).
  HiddenTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hiddenTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hiddenTagsHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return hiddenTags(ref);
  }
}

String _$hiddenTagsHash() => r'30b34dd7c5504ef5ff1431ce5d93d8a8f84f1429';
