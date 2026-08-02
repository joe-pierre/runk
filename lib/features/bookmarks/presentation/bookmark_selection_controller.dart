import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bookmark_selection_controller.g.dart';

/// Écran propriétaire d'une instance de [BookmarkSelectionController]
/// (Tâche 26, voir DECISIONS.md) — distingue `HomeScreen` et `SearchScreen`
/// pour que chacun ait sa propre sélection : sortir de l'un ne doit jamais
/// affecter la sélection de l'autre.
enum BookmarkSelectionScope { home, search }

/// État de la sélection multiple d'un écran donné : identifiants sélectionnés
/// et activation du mode sélection.
class BookmarkSelectionState {
  /// Crée un état de sélection, vide et inactif par défaut.
  const BookmarkSelectionState({
    this.selectedIds = const {},
    this.isSelectionModeActive = false,
  });

  /// Identifiants des bookmarks actuellement cochés.
  final Set<String> selectedIds;

  /// Vrai si le mode sélection multiple est actif sur cet écran.
  final bool isSelectionModeActive;

  /// Retourne une copie de cet état, en remplaçant uniquement les champs
  /// fournis.
  BookmarkSelectionState copyWith({
    Set<String>? selectedIds,
    bool? isSelectionModeActive,
  }) {
    return BookmarkSelectionState(
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionModeActive:
          isSelectionModeActive ?? this.isSelectionModeActive,
    );
  }
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
@riverpod
class BookmarkSelectionController extends _$BookmarkSelectionController {
  @override
  BookmarkSelectionState build(BookmarkSelectionScope scope) {
    return const BookmarkSelectionState();
  }

  /// Active le mode sélection multiple, ou le désactive et vide la
  /// sélection s'il était déjà actif — c'est ce même comportement qui est
  /// utilisé aussi bien pour l'icône d'activation de l'`AppBar` que pour
  /// quitter automatiquement le mode après une action groupée réussie (voir
  /// `bulk_selection_toolbar.dart`).
  void toggleSelectionMode() {
    state = state.isSelectionModeActive
        ? const BookmarkSelectionState()
        : state.copyWith(isSelectionModeActive: true);
  }

  /// Bascule la sélection de l'identifiant [id].
  void toggleSelected(String id) {
    final updatedIds = Set<String>.of(state.selectedIds);
    if (!updatedIds.remove(id)) {
      updatedIds.add(id);
    }
    state = state.copyWith(selectedIds: updatedIds);
  }

  /// Vide la sélection courante, sans désactiver le mode sélection.
  void clearSelection() {
    state = state.copyWith(selectedIds: const {});
  }
}
