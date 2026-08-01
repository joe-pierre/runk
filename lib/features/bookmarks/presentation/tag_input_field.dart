import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tags/presentation/distinct_tags_provider.dart';

/// Champ de saisie de tags avec autocomplétion sur les tags déjà utilisés
/// ailleurs (voir SPEC.md section 11 — `AddBookmarkSheet`).
///
/// Composant contrôlé : [tags] contient la liste déjà validée (affichée sous
/// forme de [Chip]s, retirables), [onTagsChanged] est appelé à chaque ajout
/// ou suppression. Les suggestions proviennent uniquement de
/// [distinctTagsProvider] (voir CONVENTIONS.md section Partials / Frontend —
/// aucun accès direct à Isar depuis `presentation/`), filtrées par préfixe
/// insensible à la casse sur le texte en cours de saisie, et affichées sous
/// le champ plutôt que dans un `Autocomplete` plein écran qui masquerait le
/// reste de la modale.
///
/// Un tag tapé manuellement peut être validé de deux façons, toutes deux
/// purement locales à cette liste en attente (aucune persistance tant que
/// `AddBookmarkSheet` n'a pas sauvegardé le bookmark, voir Tâche 14) :
/// via le clavier (`onSubmitted`), ou via le bouton "+" explicite à côté du
/// champ — distinct du tap sur une suggestion existante (Tâche 13).
class TagInputField extends ConsumerStatefulWidget {
  /// Crée le champ pour la liste [tags] actuellement sélectionnée.
  /// [onTagsChanged] est appelé avec la nouvelle liste à chaque changement.
  const TagInputField({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  /// Tags déjà ajoutés par l'utilisateur pour ce bookmark.
  final List<String> tags;

  /// Appelé avec la liste mise à jour à chaque ajout ou suppression de tag.
  final ValueChanged<List<String>> onTagsChanged;

  @override
  ConsumerState<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends ConsumerState<TagInputField> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Ajoute [rawTag] (après nettoyage) à la liste, sauf s'il est vide ou déjà
  /// présent (comparaison insensible à la casse, pour éviter qu'une
  /// suggestion reprise depuis `distinctTagsProvider` avec une casse
  /// différente ne crée un doublon visuel).
  void _addTag(String rawTag) {
    final tag = rawTag.trim();
    if (tag.isEmpty) return;
    final alreadyPresent = widget.tags.any(
      (existing) => existing.toLowerCase() == tag.toLowerCase(),
    );
    if (alreadyPresent) {
      _clearInput();
      return;
    }
    widget.onTagsChanged([...widget.tags, tag]);
    _clearInput();
  }

  void _removeTag(String tag) {
    widget.onTagsChanged(widget.tags.where((t) => t != tag).toList());
  }

  void _clearInput() {
    _controller.clear();
    setState(() => _query = '');
  }

  List<String> _filterSuggestions(List<String> distinctTags) {
    if (_query.isEmpty) return const [];
    final lowerQuery = _query.toLowerCase();
    return distinctTags
        .where((tag) => tag.toLowerCase().startsWith(lowerQuery))
        .where(
          (tag) => !widget.tags.any(
            (existing) => existing.toLowerCase() == tag.toLowerCase(),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final distinctTagsAsync = ref.watch(distinctTagsProvider);
    final suggestions = _filterSuggestions(distinctTagsAsync.value ?? const []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final tag in widget.tags)
                  Chip(
                    label: Text(tag),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onDeleted: () => _removeTag(tag),
                  ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  helperText: 'Tapez puis validez pour ajouter un tag',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Ajouter ce tag',
              onPressed: () => _addTag(_controller.text),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxHeight: 160),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(suggestion),
                  onTap: () => _addTag(suggestion),
                );
              },
            ),
          ),
      ],
    );
  }
}
