import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/app_scaffold_key_provider.dart';
import '../../../core/theme/app_input_decorations.dart';
import '../../bookmarks/presentation/bookmark_list_provider.dart';
import '../../bookmarks/presentation/bookmark_tag_filter_provider.dart';
import '../data/tag_repository_provider.dart';
import 'distinct_tags_provider.dart';
import 'tag_action_dialogs.dart';

/// Action disponible sur un tag depuis son menu contextuel (voir
/// [TagsScreen]).
enum _TagAction { rename, delete }

/// Écran de navigation par tag (voir SPEC.md section 11), étendu depuis la
/// Tâche 15 à la gestion indépendante des tags (voir DECISIONS.md, entrée
/// « Tâche 15 » et sa révision) : créer un tag sans bookmark associé
/// (`FloatingActionButton` "+", cohérent avec `HomeScreen`), le renommer ou
/// le supprimer (menu contextuel par tag).
///
/// Liste tous les tags fusionnés ([distinctTagsProvider]) ; un tap sur un
/// tag active [bookmarkTagFilterProvider] puis retourne sur l'onglet Home,
/// qui affiche alors les bookmarks filtrés en réutilisant `BookmarkCard` tel
/// quel — cet écran ne duplique aucun affichage de bookmark (voir
/// contrainte de la Tâche 9). Toute mutation passe exclusivement par
/// `TagRepository` (voir CONVENTIONS.md section Réponses API).
///
/// Un champ de filtre local (Tâche 33) réduit la liste affichée par
/// correspondance de sous-chaîne, insensible à la casse, sur les tags déjà
/// résolus par [distinctTagsProvider] — aucune requête Isar ni provider
/// supplémentaire, à ne pas confondre avec `bookmarkSearchProvider`
/// (recherche full-text des bookmarks sur `HomeScreen`, Tâche 30).
class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  final _filterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filterController.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _filterController.removeListener(_onFilterChanged);
    _filterController.dispose();
    super.dispose();
  }

  void _onFilterChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tagsAsync = ref.watch(distinctTagsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () =>
              ref.read(appScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        title: const Text('Tags'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Ajouter un tag',
        onPressed: () => _createTag(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _filterController,
              decoration: searchFieldDecoration(hint: 'Filtrer les tags...'),
            ),
          ),
          Expanded(
            child: tagsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Impossible de charger les tags.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              data: (tags) {
                if (tags.isEmpty) {
                  return Center(
                    child: Text(
                      'Ajoutez des tags à vos bookmarks pour les retrouver '
                      'ici.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                final query = _filterController.text.trim();
                final filteredTags = query.isEmpty
                    ? tags
                    : tags
                          .where(
                            (tag) => tag.toLowerCase().contains(
                              query.toLowerCase(),
                            ),
                          )
                          .toList();

                if (filteredTags.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucun tag ne correspond à "$query".',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTags.length,
                  itemBuilder: (context, index) {
                    final tag = filteredTags[index];
                    return ListTile(
                      leading: const Icon(Icons.label_outline),
                      title: Text(tag),
                      onTap: () => _filterHomeByTag(context, tag),
                      trailing: PopupMenuButton<_TagAction>(
                        tooltip: 'Actions sur ce tag',
                        onSelected: (action) => switch (action) {
                          _TagAction.rename => _renameTag(context, tag),
                          _TagAction.delete => _deleteTag(context, tag),
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _TagAction.rename,
                            child: Text('Renommer'),
                          ),
                          PopupMenuItem(
                            value: _TagAction.delete,
                            child: Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _filterHomeByTag(BuildContext context, String tag) {
    ref.read(bookmarkTagFilterProvider.notifier).select(tag);
    context.go('/');
  }

  Future<void> _createTag(BuildContext context) async {
    final name = await promptForTagName(context, title: 'Ajouter un tag');
    if (name == null || name.trim().isEmpty) return;

    final tagRepository = await ref.read(tagRepositoryProvider.future);
    await tagRepository.createTag(name);
    await _refreshTagSources();
  }

  Future<void> _renameTag(BuildContext context, String currentName) async {
    final newName = await promptForTagName(
      context,
      title: 'Renommer le tag',
      initialValue: currentName,
    );
    if (newName == null || newName.trim().isEmpty) return;

    final tagRepository = await ref.read(tagRepositoryProvider.future);
    await tagRepository.renameTag(currentName, newName);
    await _refreshTagSources();
  }

  Future<void> _deleteTag(BuildContext context, String tag) async {
    final tagRepository = await ref.read(tagRepositoryProvider.future);
    final impactedCount = await tagRepository.countBookmarksForTag(tag);

    if (!context.mounted) return;
    final confirmed = await confirmTagDeletion(
      context,
      tag: tag,
      impactedCount: impactedCount,
    );
    if (confirmed != true) return;

    await tagRepository.deleteTag(tag);
    await _refreshTagSources();
  }

  /// Recharge les deux sources affectées par une mutation de tag : la liste
  /// fusionnée elle-même, et les bookmarks (dont les `tags` affichés par
  /// `BookmarkCard` ont pu changer suite à un renommage/suppression en
  /// cascade, voir DECISIONS.md « Tâche 15 »).
  Future<void> _refreshTagSources() async {
    ref.invalidate(distinctTagsProvider);
    await ref.read(bookmarkListProvider.notifier).refresh();
  }
}
