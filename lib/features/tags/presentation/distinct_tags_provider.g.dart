// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'distinct_tags_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Expose la liste des tags distincts utilisés par tous les bookmarks, triés
/// par ordre alphabétique (voir SPEC.md section 11 — écran Tags).
///
/// Dérivé de [bookmarkListProvider] : ne fait aucun accès propre à
/// `BookmarkRepository`, pour ne jamais dupliquer la source de vérité des
/// bookmarks (voir CONVENTIONS.md section Partials / Frontend).

@ProviderFor(distinctTags)
final distinctTagsProvider = DistinctTagsProvider._();

/// Expose la liste des tags distincts utilisés par tous les bookmarks, triés
/// par ordre alphabétique (voir SPEC.md section 11 — écran Tags).
///
/// Dérivé de [bookmarkListProvider] : ne fait aucun accès propre à
/// `BookmarkRepository`, pour ne jamais dupliquer la source de vérité des
/// bookmarks (voir CONVENTIONS.md section Partials / Frontend).

final class DistinctTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Expose la liste des tags distincts utilisés par tous les bookmarks, triés
  /// par ordre alphabétique (voir SPEC.md section 11 — écran Tags).
  ///
  /// Dérivé de [bookmarkListProvider] : ne fait aucun accès propre à
  /// `BookmarkRepository`, pour ne jamais dupliquer la source de vérité des
  /// bookmarks (voir CONVENTIONS.md section Partials / Frontend).
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

String _$distinctTagsHash() => r'78e448f360ee80e7a4c7f62153a6d687cfb48ff4';
