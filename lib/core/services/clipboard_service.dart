import 'dart:async';

import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter/widgets.dart';

import '../models/video_source.dart';
import '../utils/source_detector.dart';
import 'clipboard_history_store.dart';

/// Détecte un lien vidéo copié dans le presse-papier et le propose à
/// l'utilisateur, sans jamais créer de bookmark automatiquement (voir
/// SPEC.md section 4 règle 7).
///
/// Observe le cycle de vie de l'application via [WidgetsBindingObserver] :
/// la lecture du presse-papier n'a lieu **que** sur la transition vers
/// [AppLifecycleState.resumed], jamais en tâche de fond, jamais via un
/// timer périodique. Réutilise [SourceDetector] pour valider le contenu ;
/// ignore silencieusement toute chaîne qui n'est pas une URL vidéo reconnue.
///
/// Limitation documentée (voir SPEC.md section 9 et DECISIONS.md, entrée
/// "Tâche 6.5") : sur iOS, l'API native `UIPasteboard.detectPatterns`
/// (iOS 16+), qui permettrait de vérifier la présence d'une URL sans
/// déclencher la bannière système "Runk a collé depuis...", n'est pas
/// exposée par `package:flutter/services.dart` — l'exploiter demanderait un
/// canal de plateforme Swift custom, non réalisable dans cet environnement
/// de développement sans Xcode (même limitation que la Share Extension de
/// la Tâche 3). La lecture standard (`Clipboard.getData`) est donc utilisée
/// sur toutes les versions d'iOS ; la bannière système qui en résulte est
/// une limitation de plateforme acceptée, pas un choix de conception à
/// corriger côté app (voir SPEC.md section 9, dernier paragraphe).
class ClipboardService with WidgetsBindingObserver {
  ClipboardService(this._historyStore);

  final ClipboardHistoryStore _historyStore;

  final StreamController<String> _suggestedUrlController =
      StreamController<String>.broadcast();

  /// Flux des URLs vidéo valides détectées dans le presse-papier au retour
  /// au premier plan, jamais déjà proposées ni ignorées par le passé.
  Stream<String> get suggestedUrlStream => _suggestedUrlController.stream;

  /// Démarre l'observation du cycle de vie de l'application. À appeler une
  /// seule fois, tôt dans la vie de l'app (voir
  /// `clipboard_service_provider.dart`).
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Arrête l'observation du cycle de vie et libère le flux de suggestions.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _suggestedUrlController.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkClipboard());
    }
  }

  Future<void> _checkClipboard() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    final candidate = clipboardData?.text?.trim();
    if (candidate == null || candidate.isEmpty) return;
    if (!_isValidUrl(candidate)) return;
    if (SourceDetector.detect(candidate) == VideoSource.unknown) return;
    if (await _historyStore.hasBeenSeen(candidate)) return;

    _suggestedUrlController.add(candidate);
  }

  /// Valide qu'une chaîne lue du presse-papier est bien une URL exploitable
  /// : schéma `http`/`https` obligatoire et hôte non vide. Mêmes règles que
  /// `ShareIntentService._isValidUrl`, dupliquées volontairement ici plutôt
  /// que factorisées : deux occurrences courtes ne justifient pas encore un
  /// utilitaire partagé (voir BUGS_AND_ROADMAP.md si une 3e apparaît).
  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Marque [url] comme vue dans l'historique, pour qu'elle ne soit plus
  /// jamais reproposée — appelé aussi bien après un "Ajouter" explicite
  /// qu'après un "Ignorer" (voir SPEC.md section 4 règle 7).
  Future<void> markAsSeen(String url) => _historyStore.markAsSeen(url);
}
