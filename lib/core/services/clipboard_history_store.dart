import 'package:shared_preferences/shared_preferences.dart';

/// Persiste localement les liens déjà proposés (acceptés ou ignorés) par la
/// suggestion clipboard, pour ne jamais reproposer un même lien deux fois
/// (voir SPEC.md section 4 règle 7).
///
/// Stockage `SharedPreferences` uniquement, jamais synchronisé vers
/// Supabase : c'est un état d'interface propre à cet appareil, pas une
/// donnée métier (voir TASK_PROMPTS.md Tâche 6.5, contraintes, et
/// DECISIONS.md, entrée "Tâche 6.5 — Historique clipboard via
/// SharedPreferences").
class ClipboardHistoryStore {
  ClipboardHistoryStore(this._preferences);

  final SharedPreferences _preferences;

  static const _seenUrlsKey = 'clipboard_seen_urls';

  /// Vrai si [url] a déjà été proposée (puis acceptée ou ignorée) par le
  /// passé.
  Future<bool> hasBeenSeen(String url) async {
    return _preferences.getStringList(_seenUrlsKey)?.contains(url) ?? false;
  }

  /// Marque [url] comme déjà vue, pour qu'elle ne soit plus jamais
  /// reproposée par [ClipboardService]. Sans effet si [url] est déjà
  /// marquée.
  Future<void> markAsSeen(String url) async {
    final seenUrls = _preferences.getStringList(_seenUrlsKey) ?? <String>[];
    if (seenUrls.contains(url)) return;
    await _preferences.setStringList(_seenUrlsKey, [...seenUrls, url]);
  }
}
