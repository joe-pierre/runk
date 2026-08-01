import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/bookmark_repository_provider.dart';
import '../domain/video_bookmark.dart';
import 'bookmark_list_provider.dart';

/// Écran de sélection multiple permettant d'ajouter des bookmarks à "My
/// Eyes Only" (Tâche 24, voir DECISIONS.md) : liste à cases à cocher des
/// bookmarks actuellement visibles (`isHidden == false`), avec un bouton
/// "Masquer la sélection" qui les fait basculer en `isHidden: true`.
///
/// Dérivé de [bookmarkListProvider] et filtré côté client, même pattern que
/// `MyEyesOnlyScreen` (voir sa doc de classe) — aucun nouvel accès direct à
/// Isar/Supabase, uniquement `bookmarkRepositoryProvider`. Accessible
/// uniquement via le bouton "+" de `MyEyesOnlyScreen`, jamais depuis
/// `HomeScreen` (dont le "+" ouvre `ManualAddDialog`, un flux distinct).
class AddToMyEyesOnlyScreen extends ConsumerStatefulWidget {
  const AddToMyEyesOnlyScreen({super.key});

  @override
  ConsumerState<AddToMyEyesOnlyScreen> createState() =>
      _AddToMyEyesOnlyScreenState();
}

class _AddToMyEyesOnlyScreenState extends ConsumerState<AddToMyEyesOnlyScreen> {
  final _selectedIds = <String>{};

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
      body: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
      floatingActionButton: _selectedIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _hideSelection(selectable),
              icon: const Icon(Icons.visibility_off_outlined),
              label: const Text('Masquer la sélection'),
            ),
    );
  }
}
