import '../models/video_source.dart';
import 'source_detector.dart';

/// Extrait la meilleure URL `http`/`https` exploitable au sein d'un texte
/// libre (ex: texte de partage ou contenu du presse-papier entourant le lien
/// réel de texte promotionnel).
///
/// Fonction pure et testable : aucune dépendance à Flutter, à Isar ni à un
/// provider Riverpod (comparable à [SourceDetector]). Factorise une logique
/// initialement dupliquée entre `ShareIntentService` (Tâche 16) et
/// `ClipboardService` (Tâche 18) — voir DECISIONS.md.
class UrlTextExtractor {
  /// Repère toute sous-chaîne ressemblant à une URL `http`/`https` au sein
  /// d'un texte libre (ex: TikTok Lite entoure le lien de texte
  /// promotionnel).
  static final RegExp _urlPattern = RegExp(r'https?://\S+');

  /// Ponctuation finale parasite fréquemment collée à une URL extraite d'un
  /// texte libre (point de fin de phrase, parenthèse fermante, etc.), retirée
  /// avant validation.
  static const Set<String> _trailingPunctuation = {
    '.',
    ',',
    ';',
    ':',
    '!',
    '?',
    ')',
    ']',
    '}',
    '"',
    "'",
  };

  /// Extrait, depuis [text], la meilleure URL `http`/`https` exploitable, ou
  /// `null` si aucune URL valide n'y est trouvée. Une chaîne déjà
  /// entièrement constituée d'une URL nue (cas YouTube/Instagram) est
  /// retournée telle quelle.
  ///
  /// Quand plusieurs URLs sont présentes dans le même texte (ex: TikTok
  /// Lite, qui ajoute un second lien promotionnel non pertinent après le
  /// lien réel), celle dont [SourceDetector.detect] reconnaît une
  /// plateforme est préférée à la première trouvée dans l'ordre du texte —
  /// pour ne pas dépendre de la position du lien pertinent. Si aucune URL
  /// trouvée ne correspond à une plateforme reconnue, la première URL
  /// valide du texte est conservée malgré tout (cet utilitaire ne connaît
  /// volontairement aucune liste de plateformes en dur, voir SPEC.md
  /// section 8).
  static String? extractBestUrl(String text) {
    final candidates = _urlPattern
        .allMatches(text)
        .map((match) => _stripTrailingPunctuation(match.group(0)!))
        .where(_isValidUrl)
        .toList();

    if (candidates.isEmpty) return null;

    return candidates.firstWhere(
      (url) => SourceDetector.detect(url) != VideoSource.unknown,
      orElse: () => candidates.first,
    );
  }

  /// Retire toute ponctuation finale parasite (voir [_trailingPunctuation])
  /// collée à une URL extraite d'un texte libre.
  static String _stripTrailingPunctuation(String url) {
    var result = url;
    while (result.isNotEmpty &&
        _trailingPunctuation.contains(result[result.length - 1])) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// Valide qu'une chaîne est bien une URL exploitable : schéma `http` ou
  /// `https` obligatoire et hôte non vide.
  static bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
