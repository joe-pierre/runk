import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_scaffold_key_provider.dart';
import '../../../core/theme/app_color_tokens.dart';
import '../domain/video_bookmark.dart';
import 'bookmark_card.dart';
import 'bookmark_context_menu.dart';
import 'bookmark_list_provider.dart';
import 'bookmark_search_provider.dart';
import 'bookmark_selection_controller.dart';
import 'bookmark_tag_filter_provider.dart';
import 'bulk_selection_toolbar.dart';
import 'clipboard_suggestion_banner.dart';
import 'manual_add_dialog.dart';
import 'my_eyes_only_access.dart';
import 'open_bookmark_action.dart';

/// Sélection multiple de cet écran (Tâche 26, voir DECISIONS.md) — seule
/// instance existante depuis la Tâche 30, voir [BookmarkSelectionScope].
const _selectionScope = BookmarkSelectionScope.home;

/// Tokens de couleur actifs, ou [AppColorTokens.dark] si aucun thème Runk
/// n'est enregistré (mêmes raisons qu'en `bookmark_card.dart`) — utilisé
/// pour teinter le fond circulaire de l'icône de sélection multiple (Tâche
/// 34, voir DECISIONS.md).
AppColorTokens _colorTokens(BuildContext context) =>
    Theme.of(context).extension<AppColorTokens>() ?? AppColorTokens.dark;

/// Écran d'accueil : liste chronologique (date de création décroissante) de
/// tous les bookmarks non supprimés et non masqués (voir SPEC.md section
/// 11) — un bookmark `isHidden: true` (voir Tâche 22, DECISIONS.md)
/// disparaît immédiatement de cette liste, sans être supprimé.
///
/// Purement présentationnel : lit [bookmarkListProvider]/[bookmarkSearchProvider]
/// et affiche l'état correspondant (chargement, erreur, liste), ne décide
/// jamais lui-même comment récupérer, trier ou rechercher les bookmarks (voir
/// CONVENTIONS.md section Partials / Frontend). Affiche
/// `ClipboardSuggestionBanner` en haut de l'écran (voir SPEC.md section 11) —
/// celle-ci ne prend aucune place tant qu'aucune suggestion n'est active. Un
/// tap sur une carte délègue la réouverture à `DeepLinkService.openInSource`
/// (voir SPEC.md section 4 règle 5) — l'écran ne décide lui-même d'aucun
/// schéma natif ni fallback, il se contente de transmettre le résultat à
/// l'utilisateur.
///
/// **Barre de recherche intégrée (Tâche 30, voir DECISIONS.md) :** depuis la
/// suppression de `SearchScreen`, la recherche full-text (titre + tags) se
/// fait directement ici, via un champ placé dans le `bottom:` du
/// `SliverAppBar` — masqué/réaffiché avec le titre "Runk" au scroll
/// (`floating: true, snap: true`, natif, sans logique de détection de
/// direction custom). Tant que le champ est vide, le comportement est
/// strictement celui d'avant la Tâche 30 : [bookmarkListProvider], filtré par
/// [bookmarkTagFilterProvider] si actif. Dès qu'une requête non vide est
/// saisie, la liste bascule sur [bookmarkSearchProvider] (recherche purement
/// locale, aucun appel réseau, voir contrainte de la Tâche 9) et le chip de
/// filtre par tag est masqué — les deux filtres ne se combinent jamais,
/// reprise à l'identique du comportement de l'ancien `SearchScreen` (voir
/// DECISIONS.md, entrée « Tâche 30 »).
///
/// Le bouton flottant "+" ouvre `ManualAddDialog`, troisième voie d'entrée
/// d'un bookmark équivalente au Share Intent et à la suggestion clipboard
/// (voir SPEC.md section 11).
///
/// Un appui long sur une carte délègue à `showBookmarkContextMenu` (Tâche
/// 21) l'ouverture du menu contextuel (modifier les tags / supprimer) —
/// geste distinct du tap simple, sans interférence (voir `BookmarkCard`).
///
/// Un appui long sur le titre "Runk" de l'`AppBar` délègue à
/// `openMyEyesOnly` (Tâche 22, voir DECISIONS.md) l'ouverture de la section
/// de bookmarks masqués, protégée par un code — point d'entrée
/// volontairement discret, sans onglet dédié dans `AppShell`.
///
/// **Mode sélection multiple (Tâche 26, voir DECISIONS.md) :** une icône
/// dédiée de l'`AppBar` active/désactive le mode (voir
/// `BookmarkSelectionController`, instance propre à cet écran via
/// [_selectionScope]) ; une fois actif, chaque `BookmarkCard` affiche une
/// case à cocher et `BulkSelectionToolbar` apparaît en bas dès qu'au moins
/// un bookmark est coché. Aucune action de masquage n'y est jamais exposée
/// (voir `BulkSelectionToolbar`). Icône déclencheuse sur fond circulaire
/// discret teinté via [AppColorTokens.tagBackground]/`.tagText` (Tâche 34,
/// voir DECISIONS.md) — même traitement visuel actif/inactif, seule
/// l'icône (`Icons.checklist`/`Icons.close`) change. Une case "Tout
/// sélectionner" (Tâche 35, voir DECISIONS.md) apparaît au-dessus de la
/// liste tant que le mode est actif : elle porte uniquement sur la liste
/// actuellement affichée (après filtre par tag ou recherche en cours,
/// jamais l'ensemble des bookmarks en base), cochée si et seulement si
/// cette liste entière est déjà sélectionnée.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filtre [allBookmarks] pour la liste normale (requête de recherche
  /// vide) : masque les bookmarks masqués (`isHidden`), puis applique
  /// [tagFilter] s'il est actif — comportement inchangé depuis avant la
  /// Tâche 30.
  List<VideoBookmark> _visibleBookmarks(
    List<VideoBookmark> allBookmarks,
    String? tagFilter,
  ) {
    final visible = allBookmarks
        .where((bookmark) => !bookmark.isHidden)
        .toList();
    if (tagFilter == null) return visible;
    return visible
        .where((bookmark) => bookmark.tags.contains(tagFilter))
        .toList();
  }

  /// Message affiché quand la liste à afficher est vide, selon le mode
  /// actif — reprend à l'identique les messages respectifs de `HomeScreen`
  /// et de l'ancien `SearchScreen` (voir DECISIONS.md, entrée « Tâche 30 »).
  String _emptyMessage({
    required bool isSearching,
    required String query,
    required String? tagFilter,
  }) {
    if (isSearching) return 'Aucun résultat pour "$query".';
    return tagFilter == null
        ? 'Partagez une vidéo vers Runk pour commencer.'
        : 'Aucun bookmark avec ce tag.';
  }

  @override
  Widget build(BuildContext context) {
    final tagFilter = ref.watch(bookmarkTagFilterProvider);
    final selection = ref.watch(
      bookmarkSelectionControllerProvider(_selectionScope),
    );
    final selectionNotifier = ref.read(
      bookmarkSelectionControllerProvider(_selectionScope).notifier,
    );

    final trimmedQuery = _searchController.text.trim();
    final isSearching = trimmedQuery.isNotEmpty;
    final bookmarksAsync = isSearching
        ? ref.watch(bookmarkSearchProvider(trimmedQuery))
        : ref.watch(bookmarkListProvider);

    // Liste actuellement affichée à l'écran (après filtre par tag ou
    // recherche en cours), une fois les données chargées — portée exacte de
    // la case "Tout sélectionner" (Tâche 35, voir DECISIONS.md) : jamais
    // l'ensemble des bookmarks en base au-delà de ce qui est déjà chargé.
    // `null` tant que les données ne sont pas encore disponibles (chargement
    // ou erreur) : la case reste alors masquée, faute de liste sur laquelle
    // agir.
    final currentBookmarks = bookmarksAsync.maybeWhen(
      data: (results) =>
          isSearching ? results : _visibleBookmarks(results, tagFilter),
      orElse: () => null,
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(bookmarkListProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () =>
                    ref.read(appScaffoldKeyProvider).currentState?.openDrawer(),
              ),
              title: GestureDetector(
                onLongPress: () => openMyEyesOnly(context, ref),
                child: const Text('Runk'),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _colorTokens(context).tagBackground,
                    ),
                    child: IconButton(
                      icon: Icon(
                        selection.isSelectionModeActive
                            ? Icons.close
                            : Icons.checklist,
                        color: _colorTokens(context).tagText,
                      ),
                      tooltip: selection.isSelectionModeActive
                          ? 'Annuler la sélection'
                          : 'Sélectionner des bookmarks',
                      onPressed: selectionNotifier.toggleSelectionMode,
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Rechercher par titre ou tag',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: ClipboardSuggestionBanner()),
            if (!isSearching && tagFilter != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text('Filtré par : $tagFilter'),
                      onDeleted: () =>
                          ref.read(bookmarkTagFilterProvider.notifier).clear(),
                    ),
                  ),
                ),
              ),
            if (selection.isSelectionModeActive && currentBookmarks != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CheckboxListTile(
                    value:
                        currentBookmarks.isNotEmpty &&
                        selection.selectedIds.length ==
                            currentBookmarks.length,
                    onChanged: (checked) => (checked ?? false)
                        ? selectionNotifier.selectAll(
                            currentBookmarks.map((b) => b.id).toList(),
                          )
                        : selectionNotifier.deselectAll(),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                    title: const Text('Tout sélectionner'),
                  ),
                ),
              ),
            bookmarksAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    isSearching
                        ? 'Impossible d\'effectuer la recherche.'
                        : 'Impossible de charger vos bookmarks.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              data: (results) {
                final bookmarks = currentBookmarks!;
                if (bookmarks.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _emptyMessage(
                          isSearching: isSearching,
                          query: trimmedQuery,
                          tagFilter: tagFilter,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }
                return SliverList.builder(
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        index == 0 ? 12 : 0,
                        12,
                        8,
                      ),
                      child: BookmarkCard(
                        bookmark: bookmark,
                        onTap: () => openBookmark(context, ref, bookmark),
                        onLongPress: () =>
                            showBookmarkContextMenu(context, ref, bookmark),
                        selectionMode: selection.isSelectionModeActive,
                        isSelected: selection.selectedIds.contains(
                          bookmark.id,
                        ),
                        onToggleSelection: (_) =>
                            selectionNotifier.toggleSelected(bookmark.id),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ManualAddDialog.show(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: selection.selectedIds.isEmpty
          ? null
          : const BulkSelectionToolbar(scope: _selectionScope),
    );
  }
}
