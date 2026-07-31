// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Résultats de recherche full-text (titre + tags) pour la requête [query]
/// (voir SPEC.md section 11 — écran Recherche).
///
/// Délègue entièrement à
/// [BookmarkRepository.searchBookmarks](../data/bookmark_repository.dart),
/// qui n'interroge que l'Isar local — aucun appel réseau direct ici (voir
/// contrainte de la Tâche 9). Une requête vide retourne une liste vide sans
/// solliciter le repository, pour ne pas afficher tous les bookmarks avant
/// toute saisie.

@ProviderFor(bookmarkSearch)
final bookmarkSearchProvider = BookmarkSearchFamily._();

/// Résultats de recherche full-text (titre + tags) pour la requête [query]
/// (voir SPEC.md section 11 — écran Recherche).
///
/// Délègue entièrement à
/// [BookmarkRepository.searchBookmarks](../data/bookmark_repository.dart),
/// qui n'interroge que l'Isar local — aucun appel réseau direct ici (voir
/// contrainte de la Tâche 9). Une requête vide retourne une liste vide sans
/// solliciter le repository, pour ne pas afficher tous les bookmarks avant
/// toute saisie.

final class BookmarkSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VideoBookmark>>,
          List<VideoBookmark>,
          FutureOr<List<VideoBookmark>>
        >
    with
        $FutureModifier<List<VideoBookmark>>,
        $FutureProvider<List<VideoBookmark>> {
  /// Résultats de recherche full-text (titre + tags) pour la requête [query]
  /// (voir SPEC.md section 11 — écran Recherche).
  ///
  /// Délègue entièrement à
  /// [BookmarkRepository.searchBookmarks](../data/bookmark_repository.dart),
  /// qui n'interroge que l'Isar local — aucun appel réseau direct ici (voir
  /// contrainte de la Tâche 9). Une requête vide retourne une liste vide sans
  /// solliciter le repository, pour ne pas afficher tous les bookmarks avant
  /// toute saisie.
  BookmarkSearchProvider._({
    required BookmarkSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bookmarkSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookmarkSearchHash();

  @override
  String toString() {
    return r'bookmarkSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<VideoBookmark>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<VideoBookmark>> create(Ref ref) {
    final argument = this.argument as String;
    return bookmarkSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BookmarkSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookmarkSearchHash() => r'07e11f1645b36b7a3b0a65e24ab1a633f268057f';

/// Résultats de recherche full-text (titre + tags) pour la requête [query]
/// (voir SPEC.md section 11 — écran Recherche).
///
/// Délègue entièrement à
/// [BookmarkRepository.searchBookmarks](../data/bookmark_repository.dart),
/// qui n'interroge que l'Isar local — aucun appel réseau direct ici (voir
/// contrainte de la Tâche 9). Une requête vide retourne une liste vide sans
/// solliciter le repository, pour ne pas afficher tous les bookmarks avant
/// toute saisie.

final class BookmarkSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<VideoBookmark>>, String> {
  BookmarkSearchFamily._()
    : super(
        retry: null,
        name: r'bookmarkSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Résultats de recherche full-text (titre + tags) pour la requête [query]
  /// (voir SPEC.md section 11 — écran Recherche).
  ///
  /// Délègue entièrement à
  /// [BookmarkRepository.searchBookmarks](../data/bookmark_repository.dart),
  /// qui n'interroge que l'Isar local — aucun appel réseau direct ici (voir
  /// contrainte de la Tâche 9). Une requête vide retourne une liste vide sans
  /// solliciter le repository, pour ne pas afficher tous les bookmarks avant
  /// toute saisie.

  BookmarkSearchProvider call(String query) =>
      BookmarkSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'bookmarkSearchProvider';
}
