// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ouvre l'unique instance [Isar] de la feature bookmarks, dans le
/// répertoire de documents de l'application.
///
/// Vit ici plutôt que dans `core/` : le schéma ouvert (`BookmarkEntitySchema`)
/// est propre à cette feature, et `core/` ne doit jamais dépendre d'une
/// `feature/` (voir DECISIONS.md, entrée Tâche 4). `keepAlive: true` car
/// l'instance doit rester ouverte pour toute la durée de vie de l'app.

@ProviderFor(bookmarkIsar)
final bookmarkIsarProvider = BookmarkIsarProvider._();

/// Ouvre l'unique instance [Isar] de la feature bookmarks, dans le
/// répertoire de documents de l'application.
///
/// Vit ici plutôt que dans `core/` : le schéma ouvert (`BookmarkEntitySchema`)
/// est propre à cette feature, et `core/` ne doit jamais dépendre d'une
/// `feature/` (voir DECISIONS.md, entrée Tâche 4). `keepAlive: true` car
/// l'instance doit rester ouverte pour toute la durée de vie de l'app.

final class BookmarkIsarProvider
    extends $FunctionalProvider<AsyncValue<Isar>, Isar, FutureOr<Isar>>
    with $FutureModifier<Isar>, $FutureProvider<Isar> {
  /// Ouvre l'unique instance [Isar] de la feature bookmarks, dans le
  /// répertoire de documents de l'application.
  ///
  /// Vit ici plutôt que dans `core/` : le schéma ouvert (`BookmarkEntitySchema`)
  /// est propre à cette feature, et `core/` ne doit jamais dépendre d'une
  /// `feature/` (voir DECISIONS.md, entrée Tâche 4). `keepAlive: true` car
  /// l'instance doit rester ouverte pour toute la durée de vie de l'app.
  BookmarkIsarProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookmarkIsarProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookmarkIsarHash();

  @$internal
  @override
  $FutureProviderElement<Isar> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Isar> create(Ref ref) {
    return bookmarkIsar(ref);
  }
}

String _$bookmarkIsarHash() => r'a0f907d5c26ddc9a4b0c7ca9008c0e96346e3e6b';

/// Instance unique de [BookmarkRepository], construite à partir de l'Isar
/// local ([bookmarkIsarProvider]) et du client Supabase déjà initialisé par
/// `SupabaseService` (voir `main.dart`).
///
/// Seul point d'accès exposé à la couche présentation — aucun widget ni
/// provider de présentation ne doit construire directement
/// `BookmarkLocalDatasource` ou `BookmarkRemoteDatasource` (voir
/// CONVENTIONS.md section Réponses API).

@ProviderFor(bookmarkRepository)
final bookmarkRepositoryProvider = BookmarkRepositoryProvider._();

/// Instance unique de [BookmarkRepository], construite à partir de l'Isar
/// local ([bookmarkIsarProvider]) et du client Supabase déjà initialisé par
/// `SupabaseService` (voir `main.dart`).
///
/// Seul point d'accès exposé à la couche présentation — aucun widget ni
/// provider de présentation ne doit construire directement
/// `BookmarkLocalDatasource` ou `BookmarkRemoteDatasource` (voir
/// CONVENTIONS.md section Réponses API).

final class BookmarkRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<BookmarkRepository>,
          BookmarkRepository,
          FutureOr<BookmarkRepository>
        >
    with
        $FutureModifier<BookmarkRepository>,
        $FutureProvider<BookmarkRepository> {
  /// Instance unique de [BookmarkRepository], construite à partir de l'Isar
  /// local ([bookmarkIsarProvider]) et du client Supabase déjà initialisé par
  /// `SupabaseService` (voir `main.dart`).
  ///
  /// Seul point d'accès exposé à la couche présentation — aucun widget ni
  /// provider de présentation ne doit construire directement
  /// `BookmarkLocalDatasource` ou `BookmarkRemoteDatasource` (voir
  /// CONVENTIONS.md section Réponses API).
  BookmarkRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bookmarkRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bookmarkRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<BookmarkRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BookmarkRepository> create(Ref ref) {
    return bookmarkRepository(ref);
  }
}

String _$bookmarkRepositoryHash() =>
    r'86438a7fbe04ae3ad503fe810ce9fc1469367d0d';
