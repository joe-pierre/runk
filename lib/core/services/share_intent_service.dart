import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../models/video_source.dart';
import '../utils/source_detector.dart';

/// Écoute les intents de partage natifs du système (menu de partage Android
/// et Share Extension iOS) et expose uniquement les URLs valides reçues sous
/// forme d'un flux unique.
///
/// Ce service ne contient aucune logique de présentation (aucune ouverture de
/// modale) : il se contente de capter, valider et republier les liens reçus.
/// La couche présentation qui consomme [sharedUrlStream] décide de la suite
/// (voir SPEC.md section 11 et TASK_PROMPTS.md Tâche 6).
///
/// Réutilisable tel quel sur iOS (Tâche 3) : `receive_sharing_intent` unifie
/// déjà la réception Android/iOS, et la validation d'URL ne dépend d'aucune
/// spécificité de plateforme.
class ShareIntentService {
  final StreamController<String> _sharedUrlController =
      StreamController<String>.broadcast();

  StreamSubscription<List<SharedMediaFile>>? _mediaStreamSubscription;

  /// Repère toute sous-chaîne ressemblant à une URL `http`/`https` au sein
  /// d'un texte libre (ex: TikTok Lite entoure le lien de texte
  /// promotionnel, voir TASK_PROMPTS.md Tâche 16).
  static final RegExp _urlPattern = RegExp(r'https?://\S+');

  /// Ponctuation finale parasite fréquemment collée à une URL partagée dans
  /// un texte libre (point de fin de phrase, parenthèse fermante, etc.),
  /// retirée avant validation.
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

  /// Flux des URLs valides (schéma `http`/`https`) reçues via un partage
  /// natif. Toute chaîne qui n'est pas une URL exploitable est rejetée en
  /// amont et n'atteint jamais ce flux.
  Stream<String> get sharedUrlStream => _sharedUrlController.stream;

  /// Démarre l'écoute : récupère l'éventuel intent de partage ayant lancé
  /// l'application (partage à froid) puis s'abonne au flux des partages
  /// suivants reçus tant que l'application reste en mémoire.
  Future<void> initialize() async {
    final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
    _handleSharedMedia(initialMedia);

    _mediaStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(_handleSharedMedia);
  }

  void _handleSharedMedia(List<SharedMediaFile> sharedFiles) {
    for (final sharedFile in sharedFiles) {
      final candidateUrl = _extractBestUrl(sharedFile.path);
      if (candidateUrl != null) {
        _sharedUrlController.add(candidateUrl);
      }
    }
  }

  /// Extrait, depuis un texte de partage libre, la meilleure URL
  /// `http`/`https` exploitable. Une chaîne déjà entièrement constituée
  /// d'une URL nue (cas YouTube/Instagram) est retournée telle quelle.
  ///
  /// Quand plusieurs URLs sont présentes dans le même texte (ex: TikTok
  /// Lite, qui ajoute un second lien promotionnel non pertinent après le
  /// lien réel), celle dont [SourceDetector.detect] reconnaît une
  /// plateforme est préférée à la première trouvée dans l'ordre du texte —
  /// pour ne pas dépendre de la position du lien pertinent. Si aucune URL
  /// trouvée ne correspond à une plateforme reconnue, la première URL
  /// valide du texte est conservée malgré tout ([ShareIntentService] ne
  /// connaît volontairement aucune liste de plateformes supportées, voir
  /// SPEC.md section 8).
  String? _extractBestUrl(String text) {
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
  String _stripTrailingPunctuation(String url) {
    var result = url;
    while (result.isNotEmpty &&
        _trailingPunctuation.contains(result[result.length - 1])) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// Valide qu'une chaîne reçue est bien une URL exploitable : schéma
  /// `http` ou `https` obligatoire et hôte non vide. Toute autre valeur
  /// (texte libre, schéma non supporté, chaîne malformée) est rejetée
  /// silencieusement, sans exception levée.
  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Libère les ressources du service (abonnement au flux natif et
  /// contrôleur de flux). À appeler lors de la destruction du widget racine
  /// qui possède ce service.
  void dispose() {
    _mediaStreamSubscription?.cancel();
    _sharedUrlController.close();
  }
}
