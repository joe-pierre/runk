import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_to_my_eyes_only_screen.dart';
import 'bookmark_card.dart';
import 'bookmark_list_provider.dart';
import 'hidden_bookmark_menu_button.dart';
import 'open_bookmark_action.dart';

/// Écran "My Eyes Only" (Tâche 22, voir DECISIONS.md) : liste des bookmarks
/// masqués (`VideoBookmark.isHidden == true`), accessible uniquement après
/// un code correct (voir `openMyEyesOnly` dans `my_eyes_only_access.dart`).
///
/// Dérivé de [bookmarkListProvider] et filtré côté client, exactement comme
/// le fait déjà `HomeScreen` pour le filtre par tag (voir CONVENTIONS.md,
/// contrainte de la Tâche 9) : aucun nouvel accès direct à Isar/Supabase,
/// `BookmarkCard` reste le seul widget d'affichage d'un bookmark.
///
/// Depuis la Tâche 24 (voir DECISIONS.md, ajustement de la Tâche 22), le
/// menu contextuel partagé (`showBookmarkContextMenu`) n'est plus branché
/// ici : il ne doit plus jamais exposer la moindre trace du masquage, dans
/// aucun écran. "Ne plus masquer" et "Supprimer" sont désormais proposés
/// par [HiddenBookmarkMenuButton], une action locale dédiée à cet écran. Le
/// bouton flottant "+" ouvre `AddToMyEyesOnlyScreen`, qui permet de masquer
/// de nouveaux bookmarks par sélection multiple.
class MyEyesOnlyScreen extends ConsumerWidget {
  const MyEyesOnlyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Eyes Only')),
      body: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text(
            'Impossible de charger vos bookmarks.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        data: (allBookmarks) {
          final hiddenBookmarks = allBookmarks
              .where((bookmark) => bookmark.isHidden)
              .toList();
          if (hiddenBookmarks.isEmpty) {
            return Center(
              child: Text(
                'Aucun bookmark masqué.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: hiddenBookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = hiddenBookmarks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: BookmarkCard(
                        bookmark: bookmark,
                        onTap: () => openBookmark(context, ref, bookmark),
                      ),
                    ),
                    HiddenBookmarkMenuButton(bookmark: bookmark),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddToMyEyesOnlyScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
