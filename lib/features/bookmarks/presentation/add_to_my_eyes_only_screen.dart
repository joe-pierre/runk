import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bookmark_repository_provider.dart';
import '../domain/video_bookmark.dart';
import 'bookmark_list_provider.dart';
import 'hide_tag_list_view.dart';

/// Mode affiché par [AddToMyEyesOnlyScreen] (Tâche 25, voir DECISIONS.md).
enum _Mode { bookmarks, tags }

/// Écran de sélection permettant d'ajouter du contenu à "My Eyes Only"
/// (Tâche 24, étendu Tâche 25 — voir DECISIONS.md) : bascule entre deux
/// modes via un [SegmentedButton] en tête d'écran.
///
/// - **Mode "Bookmarks"** (par défaut) : liste à cases à cocher des
///   bookmarks actuellement visibles (`isHidden == false`), avec un bouton
///   "Masquer la sélection" qui les fait basculer en `isHidden: true`.
///   Dérivé de [bookmarkListProvider] et filtré côté client, même pattern
///   que `MyEyesOnlyScreen` (voir sa doc de classe).
/// - **Mode "Tags"** (Tâche 25) : délègue entièrement à [HideTagListView]
///   (liste des tags visibles, sélection unique — un tap masque
///   immédiatement le tag choisi via `TagRepository.hideTag`).
///
/// Aucun nouvel accès direct à Isar/Supabase, uniquement
/// `bookmarkRepositoryProvider`/`tagRepositoryProvider` (via
/// [HideTagListView]). Accessible uniquement via le bouton "+" de
/// `MyEyesOnlyScreen`, jamais depuis `HomeScreen` (dont le "+" ouvre
/// `ManualAddDialog`, un flux distinct) ni depuis `TagsScreen`.
class AddToMyEyesOnlyScreen extends ConsumerStatefulWidget {
  const AddToMyEyesOnlyScreen({super.key});

  @override
  ConsumerState<AddToMyEyesOnlyScreen> createState() =>
      _AddToMyEyesOnlyScreenState();
}

class _AddToMyEyesOnlyScreenState extends ConsumerState<AddToMyEyesOnlyScreen> {
  final _selectedIds = <String>{};
  _Mode _mode = _Mode.bookmarks;

  /// Masque chaque bookmark coché parmi [selectable] via
  /// `BookmarkRepository.updateBookmark`, rafraîchit [bookmarkListProvider]
  /// puis revient à `MyEyesOnlyScreen`.
  Future<void> _hideSelection(List<VideoBookmark> selectable) async {
    final repository = await ref.read(bookmarkRepositoryProvider.future);
    for (final bookmark in selectable) {
      if (!_selectedIds.contains(bookmark.id)) continue;
      await repository.updateBookmark(bookmark.copyWith(isHidden: true));
    }
    await ref.read(bookmarkListProvider.notifier).refresh();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarkListProvider);
    final selectable =
        bookmarksAsync.value
            ?.where((bookmark) => !bookmark.isHidden)
            .toList() ??
        const <VideoBookmark>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter à My Eyes Only')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<_Mode>(
              segments: const [
                ButtonSegment(
                  value: _Mode.bookmarks,
                  label: Text('Bookmarks'),
                  icon: Icon(Icons.bookmark_outline),
                ),
                ButtonSegment(
                  value: _Mode.tags,
                  label: Text('Tags'),
                  icon: Icon(Icons.label_outline),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
          ),
          Expanded(
            child: _mode == _Mode.tags
                ? const HideTagListView()
                : bookmarksAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        'Impossible de charger vos bookmarks.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    data: (_) {
                      if (selectable.isEmpty) {
                        return Center(
                          child: Text(
                            'Aucun bookmark à masquer.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: selectable.length,
                        itemBuilder: (context, index) {
                          final bookmark = selectable[index];
                          return CheckboxListTile(
                            value: _selectedIds.contains(bookmark.id),
                            title: Text(bookmark.title),
                            subtitle: bookmark.tags.isEmpty
                                ? null
                                : Text(bookmark.tags.join(', ')),
                            onChanged: (checked) => setState(() {
                              if (checked ?? false) {
                                _selectedIds.add(bookmark.id);
                              } else {
                                _selectedIds.remove(bookmark.id);
                              }
                            }),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _mode == _Mode.tags || _selectedIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _hideSelection(selectable),
              icon: const Icon(Icons.visibility_off_outlined),
              label: const Text('Masquer la sélection'),
            ),
    );
  }
}
