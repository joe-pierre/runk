import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../utils/url_text_extractor.dart';

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
      final candidateUrl = UrlTextExtractor.extractBestUrl(sharedFile.path);
      if (candidateUrl != null) {
        _sharedUrlController.add(candidateUrl);
      }
    }
  }

  /// Libère les ressources du service (abonnement au flux natif et
  /// contrôleur de flux). À appeler lors de la destruction du widget racine
  /// qui possède ce service.
  void dispose() {
    _mediaStreamSubscription?.cancel();
    _sharedUrlController.close();
  }
}
