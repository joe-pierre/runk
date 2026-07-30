// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Expose la liste des bookmarks à la couche présentation, triée par date de
/// création décroissante (tri déjà appliqué par
/// `BookmarkLocalDatasource.getAllActive`, voir SPEC.md section 11).
///
/// Seule façon pour un widget d'obtenir les bookmarks — jamais d'appel
/// direct à `BookmarkRepository` depuis un écran (voir CONVENTIONS.md
/// section Partials / Frontend).

@ProviderFor(BookmarkList)
final bookmarkListProvider = BookmarkListProvider._();

/// Expose la liste des bookmarks à la couche présentation, triée par date de
/// création décroissante (tri déjà appliqué par
/// `BookmarkLocalDatasource.getAllActive`, voir SPEC.md section 11).
///
/// Seule façon pour un widget d'obtenir les bookmarks — jamais d'appel
/// direct à `BookmarkRepository` depuis un écran (voir CONVENTIONS.md
/// section Partials / Frontend).
final class BookmarkListProvider
    extends $AsyncNotifierProvider<BookmarkList, List<VideoBookmark>> {
  /// Expose la liste des bookmarks à la couche présentation, triée par date de
  /// création décroissante (tri déjà appliqué par
  /// `BookmarkLocalDatasource.getAllActive`, voir SPEC.md section 11).
  ///
  /// Seule façon pour un widget d'obtenir les bookmarks — jamais d'appel
  /// direct à `BookmarkRepository` depuis un écran (voir CONVENTIONS.md
  /// section Partials / Frontend).
  BookmarkListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookmarkListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookmarkListHash();

  @$internal
  @override
  BookmarkList create() => BookmarkList();
}

String _$bookmarkListHash() => r'0af8700923197cdba735dfe7d4f57f6132eec5f1';

/// Expose la liste des bookmarks à la couche présentation, triée par date de
/// création décroissante (tri déjà appliqué par
/// `BookmarkLocalDatasource.getAllActive`, voir SPEC.md section 11).
///
/// Seule façon pour un widget d'obtenir les bookmarks — jamais d'appel
/// direct à `BookmarkRepository` depuis un écran (voir CONVENTIONS.md
/// section Partials / Frontend).

abstract class _$BookmarkList extends $AsyncNotifier<List<VideoBookmark>> {
  FutureOr<List<VideoBookmark>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<VideoBookmark>>, List<VideoBookmark>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<VideoBookmark>>, List<VideoBookmark>>,
              AsyncValue<List<VideoBookmark>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
