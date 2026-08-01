// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Instance unique de [TagRepository], construite à partir de l'instance
/// [Isar] partagée avec les bookmarks ([bookmarkIsarProvider] — voir sa doc
/// de classe pour le détail de ce partage, DECISIONS.md entrée « Tâche 15 »).
///
/// Seul point d'accès exposé à la couche présentation — aucun widget ni
/// provider de présentation ne doit construire directement
/// `TagLocalDatasource` ou accéder à Isar (voir CONVENTIONS.md section
/// Réponses API).

@ProviderFor(tagRepository)
final tagRepositoryProvider = TagRepositoryProvider._();

/// Instance unique de [TagRepository], construite à partir de l'instance
/// [Isar] partagée avec les bookmarks ([bookmarkIsarProvider] — voir sa doc
/// de classe pour le détail de ce partage, DECISIONS.md entrée « Tâche 15 »).
///
/// Seul point d'accès exposé à la couche présentation — aucun widget ni
/// provider de présentation ne doit construire directement
/// `TagLocalDatasource` ou accéder à Isar (voir CONVENTIONS.md section
/// Réponses API).

final class TagRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<TagRepository>,
          TagRepository,
          FutureOr<TagRepository>
        >
    with $FutureModifier<TagRepository>, $FutureProvider<TagRepository> {
  /// Instance unique de [TagRepository], construite à partir de l'instance
  /// [Isar] partagée avec les bookmarks ([bookmarkIsarProvider] — voir sa doc
  /// de classe pour le détail de ce partage, DECISIONS.md entrée « Tâche 15 »).
  ///
  /// Seul point d'accès exposé à la couche présentation — aucun widget ni
  /// provider de présentation ne doit construire directement
  /// `TagLocalDatasource` ou accéder à Isar (voir CONVENTIONS.md section
  /// Réponses API).
  TagRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<TagRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TagRepository> create(Ref ref) {
    return tagRepository(ref);
  }
}

String _$tagRepositoryHash() => r'e8286421bc1707f48f1e08ddfe47ef72726843cc';
