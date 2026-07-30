import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/metadata/metadata_service_provider.dart';
import '../../../core/services/metadata/video_metadata.dart';
import '../data/bookmark_repository_provider.dart';
import 'bookmark_list_provider.dart';

/// Modale d'ajout d'un bookmark à partir d'une [url] déjà validée (reçue via
/// Share Intent, clipboard, ou saisie manuelle future).
///
/// Récupère automatiquement les métadonnées via [videoMetadataProvider]
/// (donc via `MetadataService`), pré-remplit un titre éditable et un champ
/// de tags, puis sauvegarde via `bookmarkRepositoryProvider` — jamais
/// d'appel direct à Supabase ou Isar depuis ce widget (voir CONVENTIONS.md
/// section Réponses API).
class AddBookmarkSheet extends ConsumerStatefulWidget {
  const AddBookmarkSheet({super.key, required this.url});

  /// URL de la vidéo pour laquelle un bookmark doit être créé.
  final String url;

  /// Affiche la modale au-dessus de l'écran courant pour [url]. Retourne
  /// une fois la modale fermée (sauvegarde effectuée ou annulation) — utilisé
  /// par le widget racine pour enchaîner les partages en attente un par un
  /// (voir SPEC.md section 13).
  static Future<void> show(BuildContext context, {required String url}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddBookmarkSheet(url: url),
    );
  }

  @override
  ConsumerState<AddBookmarkSheet> createState() => _AddBookmarkSheetState();
}

class _AddBookmarkSheetState extends ConsumerState<AddBookmarkSheet> {
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _titleInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  /// Pré-remplit le titre avec celui récupéré automatiquement, une seule
  /// fois (n'écrase jamais une saisie utilisateur déjà en cours).
  void _initializeTitleIfNeeded(VideoMetadata metadata) {
    if (_titleInitialized) return;
    _titleController.text = metadata.title;
    _titleInitialized = true;
  }

  List<String> _parseTags() {
    return _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
  }

  Future<void> _save(VideoMetadata metadata) async {
    setState(() => _isSaving = true);
    try {
      final title = _titleController.text.trim();
      final repository = await ref.read(bookmarkRepositoryProvider.future);
      await repository.createBookmark(
        url: widget.url,
        title: title.isEmpty ? metadata.title : title,
        source: metadata.source,
        thumbnailUrl: metadata.thumbnailUrl,
        isPartial: metadata.isPartial,
        tags: _parseTags(),
      );
      await ref.read(bookmarkListProvider.notifier).refresh();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadataAsync = ref.watch(videoMetadataProvider(widget.url));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: metadataAsync.when(
          loading: () => const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Impossible de récupérer les informations de cette vidéo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          data: (metadata) {
            _initializeTitleIfNeeded(metadata);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MetadataPreview(metadata: metadata),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags',
                    helperText: 'Séparés par des virgules',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isSaving ? null : () => _save(metadata),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: const Text('Enregistrer'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Aperçu de la miniature (ou placeholder si [VideoMetadata.isPartial]) en
/// haut de la modale, propre à l'aperçu avant sauvegarde — distinct du
/// placeholder de `BookmarkCard`, qui affiche un `VideoBookmark` déjà
/// persisté.
class _MetadataPreview extends StatelessWidget {
  const _MetadataPreview({required this.metadata});

  final VideoMetadata metadata;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = metadata.thumbnailUrl;
    const height = 160.0;

    if (metadata.isPartial || thumbnailUrl == null) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.videocam_off_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        thumbnailUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
