import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bookmarks/presentation/bookmark_tag_filter_provider.dart';
import 'distinct_tags_provider.dart';

/// Écran de navigation par tag (voir SPEC.md section 11).
///
/// Liste tous les tags distincts utilisés ([distinctTagsProvider]) ; un tap
/// sur un tag active [bookmarkTagFilterProvider] puis retourne sur l'onglet
/// Home, qui affiche alors les bookmarks filtrés en réutilisant `BookmarkCard`
/// tel quel — cet écran ne duplique aucun affichage de bookmark (voir
/// contrainte de la Tâche 9).
class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(distinctTagsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      body: tagsAsync.when(
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
                'Ajoutez des tags à vos bookmarks pour les retrouver ici.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.builder(
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              return ListTile(
                leading: const Icon(Icons.label_outline),
                title: Text(tag),
                onTap: () => _filterHomeByTag(context, ref, tag),
              );
            },
          );
        },
      ),
    );
  }

  void _filterHomeByTag(BuildContext context, WidgetRef ref, String tag) {
    ref.read(bookmarkTagFilterProvider.notifier).select(tag);
    context.go('/');
  }
}
