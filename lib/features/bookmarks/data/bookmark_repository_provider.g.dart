// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ouvre l'unique instance [Isar] de l'application, dans le répertoire de
/// documents.
///
/// Vit ici plutôt que dans `core/` : les schémas ouverts (`BookmarkEntitySchema`,
/// `TagEntitySchema`) sont propres à des features, et `core/` ne doit jamais
/// dépendre d'une `feature/` (voir DECISIONS.md, entrée Tâche 4). `keepAlive:
/// true` car l'instance doit rester ouverte pour toute la durée de vie de
/// l'app.
///
/// Historiquement propre à la feature bookmarks (seule collection Isar
/// existante, voir DECISIONS.md entrée Tâche 6), cette instance est devenue
/// partagée avec la feature tags depuis la Tâche 15 : `TagRepository` a
/// besoin de modifier `TagEntity` et `BookmarkEntity` dans une **même**
/// transaction Isar (Isar interdit les transactions imbriquées, donc les
/// deux collections doivent appartenir à la même instance ouverte par un
/// seul `Isar.open`). Reste dans `features/bookmarks/data/` plutôt que
/// déplacé vers un nouveau composant partagé : déplacer l'ouverture
/// elle-même sans en avoir un troisième consommateur réel serait anticiper
/// une factorisation non justifiée (même raisonnement que DECISIONS.md,
/// entrée Tâche 6.5) — voir DECISIONS.md, entrée « Tâche 15 » pour le détail
/// de cette dépendance croisée `bookmarks/data` ↔ `tags/data`.

@ProviderFor(bookmarkIsar)
final bookmarkIsarProvider = BookmarkIsarProvider._();

/// Ouvre l'unique instance [Isar] de l'application, dans le répertoire de
/// documents.
///
/// Vit ici plutôt que dans `core/` : les schémas ouverts (`BookmarkEntitySchema`,
/// `TagEntitySchema`) sont propres à des features, et `core/` ne doit jamais
/// dépendre d'une `feature/` (voir DECISIONS.md, entrée Tâche 4). `keepAlive:
/// true` car l'instance doit rester ouverte pour toute la durée de vie de
/// l'app.
///
/// Historiquement propre à la feature bookmarks (seule collection Isar
/// existante, voir DECISIONS.md entrée Tâche 6), cette instance est devenue
/// partagée avec la feature tags depuis la Tâche 15 : `TagRepository` a
/// besoin de modifier `TagEntity` et `BookmarkEntity` dans une **même**
/// transaction Isar (Isar interdit les transactions imbriquées, donc les
/// deux collections doivent appartenir à la même instance ouverte par un
/// seul `Isar.open`). Reste dans `features/bookmarks/data/` plutôt que
/// déplacé vers un nouveau composant partagé : déplacer l'ouverture
/// elle-même sans en avoir un troisième consommateur réel serait anticiper
/// une factorisation non justifiée (même raisonnement que DECISIONS.md,
/// entrée Tâche 6.5) — voir DECISIONS.md, entrée « Tâche 15 » pour le détail
/// de cette dépendance croisée `bookmarks/data` ↔ `tags/data`.

final class BookmarkIsarProvider
    extends $FunctionalProvider<AsyncValue<Isar>, Isar, FutureOr<Isar>>
    with $FutureModifier<Isar>, $FutureProvider<Isar> {
  /// Ouvre l'unique instance [Isar] de l'application, dans le répertoire de
  /// documents.
  ///
  /// Vit ici plutôt que dans `core/` : les schémas ouverts (`BookmarkEntitySchema`,
  /// `TagEntitySchema`) sont propres à des features, et `core/` ne doit jamais
  /// dépendre d'une `feature/` (voir DECISIONS.md, entrée Tâche 4). `keepAlive:
  /// true` car l'instance doit rester ouverte pour toute la durée de vie de
  /// l'app.
  ///
  /// Historiquement propre à la feature bookmarks (seule collection Isar
  /// existante, voir DECISIONS.md entrée Tâche 6), cette instance est devenue
  /// partagée avec la feature tags depuis la Tâche 15 : `TagRepository` a
  /// besoin de modifier `TagEntity` et `BookmarkEntity` dans une **même**
  /// transaction Isar (Isar interdit les transactions imbriquées, donc les
  /// deux collections doivent appartenir à la même instance ouverte par un
  /// seul `Isar.open`). Reste dans `features/bookmarks/data/` plutôt que
  /// déplacé vers un nouveau composant partagé : déplacer l'ouverture
  /// elle-même sans en avoir un troisième consommateur réel serait anticiper
  /// une factorisation non justifiée (même raisonnement que DECISIONS.md,
  /// entrée Tâche 6.5) — voir DECISIONS.md, entrée « Tâche 15 » pour le détail
  /// de cette dépendance croisée `bookmarks/data` ↔ `tags/data`.
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

String _$bookmarkIsarHash() => r'bb6420de44ff978fffa8ca5ab5b6830d3c6d1b47';

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
