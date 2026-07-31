import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bookmark_tag_filter_provider.g.dart';

/// Tag actuellement sélectionné pour filtrer `HomeScreen`, ou `null` si
/// aucun filtre n'est actif (voir SPEC.md section 11 — écran Tags : "tap sur
/// un tag filtre HomeScreen").
///
/// État de présentation partagé entre `TagsScreen` (qui le fixe) et
/// `HomeScreen` (qui le lit pour filtrer sa liste) — ni l'un ni l'autre
/// écran ne recalcule lui-même la liste filtrée à partir d'une source
/// différente, `HomeScreen` continue de réutiliser [bookmarkListProvider]
/// tel quel.
@riverpod
class BookmarkTagFilter extends _$BookmarkTagFilter {
  @override
  String? build() => null;

  /// Active le filtre sur [tag].
  void select(String tag) => state = tag;

  /// Retire le filtre actif.
  void clear() => state = null;
}
