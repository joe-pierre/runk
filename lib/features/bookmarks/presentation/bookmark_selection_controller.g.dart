// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_selection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Contrôleur de sélection multiple de bookmarks (Tâche 26, voir
/// DECISIONS.md) : une instance distincte par [BookmarkSelectionScope] (voir
/// sa doc) — `HomeScreen` et `SearchScreen` n'ont donc jamais d'état de
/// sélection partagé.
///
/// Ne fait aucun appel à `BookmarkRepository` : ce contrôleur suit
/// uniquement l'état d'interface (identifiants cochés, mode actif ou non).
/// Toute mutation groupée (suppression, ajout de tag) est déclenchée depuis
/// `bulk_selection_toolbar.dart`, qui appelle le repository puis quitte le
/// mode sélection via [toggleSelectionMode].

@ProviderFor(BookmarkSelectionController)
final bookmarkSelectionControllerProvider =
    BookmarkSelectionControllerFamily._();

/// Contrôleur de sélection multiple de bookmarks (Tâche 26, voir
/// DECISIONS.md) : une instance distincte par [BookmarkSelectionScope] (voir
/// sa doc) — `HomeScreen` et `SearchScreen` n'ont donc jamais d'état de
/// sélection partagé.
///
/// Ne fait aucun appel à `BookmarkRepository` : ce contrôleur suit
/// uniquement l'état d'interface (identifiants cochés, mode actif ou non).
/// Toute mutation groupée (suppression, ajout de tag) est déclenchée depuis
/// `bulk_selection_toolbar.dart`, qui appelle le repository puis quitte le
/// mode sélection via [toggleSelectionMode].
final class BookmarkSelectionControllerProvider
    extends
        $NotifierProvider<BookmarkSelectionController, BookmarkSelectionState> {
  /// Contrôleur de sélection multiple de bookmarks (Tâche 26, voir
  /// DECISIONS.md) : une instance distincte par [BookmarkSelectionScope] (voir
  /// sa doc) — `HomeScreen` et `SearchScreen` n'ont donc jamais d'état de
  /// sélection partagé.
  ///
  /// Ne fait aucun appel à `BookmarkRepository` : ce contrôleur suit
  /// uniquement l'état d'interface (identifiants cochés, mode actif ou non).
  /// Toute mutation groupée (suppression, ajout de tag) est déclenchée depuis
  /// `bulk_selection_toolbar.dart`, qui appelle le repository puis quitte le
  /// mode sélection via [toggleSelectionMode].
  BookmarkSelectionControllerProvider._({
    required BookmarkSelectionControllerFamily super.from,
    required BookmarkSelectionScope super.argument,
  }) : super(
         retry: null,
         name: r'bookmarkSelectionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bookmarkSelectionControllerHash();

  @override
  String toString() {
    return r'bookmarkSelectionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BookmarkSelectionController create() => BookmarkSelectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BookmarkSelectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BookmarkSelectionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BookmarkSelectionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bookmarkSelectionControllerHash() =>
    r'ac7913a83dc02c7de606c7b89f97635d2e4fdd25';

/// Contrôleur de sélection multiple de bookmarks (Tâche 26, voir
/// DECISIONS.md) : une instance distincte par [BookmarkSelectionScope] (voir
/// sa doc) — `HomeScreen` et `SearchScreen` n'ont donc jamais d'état de
/// sélection partagé.
///
/// Ne fait aucun appel à `BookmarkRepository` : ce contrôleur suit
/// uniquement l'état d'interface (identifiants cochés, mode actif ou non).
/// Toute mutation groupée (suppression, ajout de tag) est déclenchée depuis
/// `bulk_selection_toolbar.dart`, qui appelle le repository puis quitte le
/// mode sélection via [toggleSelectionMode].

final class BookmarkSelectionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          BookmarkSelectionController,
          BookmarkSelectionState,
          BookmarkSelectionState,
          BookmarkSelectionState,
          BookmarkSelectionScope
        > {
  BookmarkSelectionControllerFamily._()
    : super(
        retry: null,
        name: r'bookmarkSelectionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Contrôleur de sélection multiple de bookmarks (Tâche 26, voir
  /// DECISIONS.md) : une instance distincte par [BookmarkSelectionScope] (voir
  /// sa doc) — `HomeScreen` et `SearchScreen` n'ont donc jamais d'état de
  /// sélection partagé.
  ///
  /// Ne fait aucun appel à `BookmarkRepository` : ce contrôleur suit
  /// uniquement l'état d'interface (identifiants cochés, mode actif ou non).
  /// Toute mutation groupée (suppression, ajout de tag) est déclenchée depuis
  /// `bulk_selection_toolbar.dart`, qui appelle le repository puis quitte le
  /// mode sélection via [toggleSelectionMode].

  BookmarkSelectionControllerProvider call(BookmarkSelectionScope scope) =>
      BookmarkSelectionControllerProvider._(argument: scope, from: this);

  @override
  String toString() => r'bookmarkSelectionControllerProvider';
}

/// Contrôleur de sélection multiple de bookmarks (Tâche 26, voir
/// DECISIONS.md) : une instance distincte par [BookmarkSelectionScope] (voir
/// sa doc) — `HomeScreen` et `SearchScreen` n'ont donc jamais d'état de
/// sélection partagé.
///
/// Ne fait aucun appel à `BookmarkRepository` : ce contrôleur suit
/// uniquement l'état d'interface (identifiants cochés, mode actif ou non).
/// Toute mutation groupée (suppression, ajout de tag) est déclenchée depuis
/// `bulk_selection_toolbar.dart`, qui appelle le repository puis quitte le
/// mode sélection via [toggleSelectionMode].

abstract class _$BookmarkSelectionController
    extends $Notifier<BookmarkSelectionState> {
  late final _$args = ref.$arg as BookmarkSelectionScope;
  BookmarkSelectionScope get scope => _$args;

  BookmarkSelectionState build(BookmarkSelectionScope scope);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<BookmarkSelectionState, BookmarkSelectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BookmarkSelectionState, BookmarkSelectionState>,
              BookmarkSelectionState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
