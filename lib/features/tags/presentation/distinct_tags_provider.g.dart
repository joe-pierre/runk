// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'distinct_tags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Expose la liste fusionnée des tags distincts, triés par ordre
/// alphabétique insensible à la casse (voir SPEC.md section 11 — écran
/// Tags).
///
/// Fusionne deux sources (voir DECISIONS.md, entrée « Tâche 15 ») :
/// - les tags **dérivés** de [bookmarkListProvider] (portés par au moins un
///   bookmark, comme avant la Tâche 15) ;
/// - les tags **gérés** via `TagRepository` (un `TagEntity` peut exister
///   sans aucun bookmark associé).
///
/// Déduplication insensible à la casse (cohérent avec `TagInputField`,
/// DECISIONS.md entrée « Tâche 13 ») ; en cas de collision, la casse
/// affichée est celle du tag **géré** quand il existe pour ce nom normalisé
/// (décision actée en Phase A de la Tâche 15) — un tag purement dérivé sans
/// `TagEntity` correspondant garde sa casse telle que tapée dans un
/// bookmark. Ne fait aucun accès propre à Isar : délègue entièrement à
/// [bookmarkListProvider] et [tagRepositoryProvider] (voir CONVENTIONS.md
/// section Partials / Frontend).

@ProviderFor(distinctTags)
final distinctTagsProvider = DistinctTagsProvider._();

/// Expose la liste fusionnée des tags distincts, triés par ordre
/// alphabétique insensible à la casse (voir SPEC.md section 11 — écran
/// Tags).
///
/// Fusionne deux sources (voir DECISIONS.md, entrée « Tâche 15 ») :
/// - les tags **dérivés** de [bookmarkListProvider] (portés par au moins un
///   bookmark, comme avant la Tâche 15) ;
/// - les tags **gérés** via `TagRepository` (un `TagEntity` peut exister
///   sans aucun bookmark associé).
///
/// Déduplication insensible à la casse (cohérent avec `TagInputField`,
/// DECISIONS.md entrée « Tâche 13 ») ; en cas de collision, la casse
/// affichée est celle du tag **géré** quand il existe pour ce nom normalisé
/// (décision actée en Phase A de la Tâche 15) — un tag purement dérivé sans
/// `TagEntity` correspondant garde sa casse telle que tapée dans un
/// bookmark. Ne fait aucun accès propre à Isar : délègue entièrement à
/// [bookmarkListProvider] et [tagRepositoryProvider] (voir CONVENTIONS.md
/// section Partials / Frontend).

final class DistinctTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Expose la liste fusionnée des tags distincts, triés par ordre
  /// alphabétique insensible à la casse (voir SPEC.md section 11 — écran
  /// Tags).
  ///
  /// Fusionne deux sources (voir DECISIONS.md, entrée « Tâche 15 ») :
  /// - les tags **dérivés** de [bookmarkListProvider] (portés par au moins un
  ///   bookmark, comme avant la Tâche 15) ;
  /// - les tags **gérés** via `TagRepository` (un `TagEntity` peut exister
  ///   sans aucun bookmark associé).
  ///
  /// Déduplication insensible à la casse (cohérent avec `TagInputField`,
  /// DECISIONS.md entrée « Tâche 13 ») ; en cas de collision, la casse
  /// affichée est celle du tag **géré** quand il existe pour ce nom normalisé
  /// (décision actée en Phase A de la Tâche 15) — un tag purement dérivé sans
  /// `TagEntity` correspondant garde sa casse telle que tapée dans un
  /// bookmark. Ne fait aucun accès propre à Isar : délègue entièrement à
  /// [bookmarkListProvider] et [tagRepositoryProvider] (voir CONVENTIONS.md
  /// section Partials / Frontend).
  DistinctTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'distinctTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$distinctTagsHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return distinctTags(ref);
  }
}

String _$distinctTagsHash() => r'f343e4f2a35ecc6eccd11bdf95a476d51ee36d12';
