import '../models/video_source.dart';

/// Détecte la [VideoSource] d'une URL à partir de son domaine.
///
/// Fonction pure et testable : aucune dépendance à Flutter ni à un état
/// global. Point d'extension principal pour ajouter une nouvelle plateforme
/// (voir SPEC.md section 8) — seule cette classe doit être modifiée pour
/// reconnaître un nouveau domaine.
class SourceDetector {
  /// Retourne la [VideoSource] correspondant au domaine de [url], ou
  /// [VideoSource.unknown] si l'URL est malformée ou ne correspond à aucune
  /// plateforme supportée.
  static VideoSource detect(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return VideoSource.unknown;

    final host = uri.host.toLowerCase();

    if (_matchesDomain(host, const ['youtube.com', 'youtu.be'])) {
      return VideoSource.youtube;
    }
    if (_matchesDomain(host, const ['tiktok.com'])) {
      return VideoSource.tiktok;
    }
    if (_matchesDomain(host, const ['instagram.com'])) {
      return VideoSource.instagram;
    }
    if (_matchesDomain(host, const ['facebook.com', 'fb.watch'])) {
      return VideoSource.facebook;
    }
    if (_matchesDomain(host, const ['twitter.com', 'x.com'])) {
      return VideoSource.twitter;
    }
    if (_matchesDomain(host, const ['threads.net'])) {
      return VideoSource.threads;
    }
    return VideoSource.unknown;
  }

  /// Vrai si [host] correspond exactement à l'un des [domains], ou à l'un de
  /// leurs sous-domaines (ex: `www.youtube.com` correspond à `youtube.com`).
  static bool _matchesDomain(String host, List<String> domains) {
    return domains.any(
      (domain) => host == domain || host.endsWith('.$domain'),
    );
  }
}
