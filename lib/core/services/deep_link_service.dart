import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../models/video_source.dart';

/// Rouvre une vidéo sauvegardée dans son application source, avec repli
/// automatique vers le navigateur (voir SPEC.md section 4 règle 5).
///
/// **Schémas natifs non officiels.** Les schémas utilisés ici
/// (`instagram://`, `snssdk1233://` pour TikTok, `fb://`, `vnd.youtube://`)
/// ne sont documentés par aucune des plateformes cibles : ce sont des
/// conventions observées, susceptibles de changer ou de cesser de
/// fonctionner sans préavis à la discrétion de l'éditeur de chaque app.
/// Pour TikTok, cette convention attend en plus un identifiant numérique
/// précis extrait du chemin de l'URL (voir `_nativeUriFor`) plutôt qu'une
/// simple reconstruction hôte/chemin — si cet identifiant est introuvable,
/// aucun schéma natif n'est tenté. Threads et X/Twitter n'ont, à la
/// connaissance de ce projet, aucun schéma natif tenté — le repli navigateur
/// y est donc systématique. Threads n'a jamais eu de schéma connu ; X/Twitter
/// en avait un (`twitter://status?id=<id>`, voir Tâche 32) mais celui-ci a
/// été abandonné (Tâche 36) après vérification manuelle en usage réel :
/// il rouvre l'app sur son accueil plutôt que sur le post visé, X n'ayant
/// jamais officiellement documenté ni garanti ce schéma depuis 2016 — les
/// liens `https://x.com/...` bénéficient au contraire des Universal Links
/// (iOS) / App Links (Android), associés officiellement au domaine `x.com`,
/// nettement plus fiables pour ouvrir un post précis. Voir
/// `BUGS_AND_ROADMAP.md` ("Les schémas de deep link natifs... peuvent
/// changer sans préavis") pour le suivi de cette fragilité dans le temps.
///
/// Le repli navigateur (`url_launcher`, `LaunchMode.externalApplication`)
/// n'est jamais optionnel : il s'exécute systématiquement si le schéma
/// natif est absent, non géré par aucune app installée, ou échoue pour
/// toute autre raison. Aucune exception ne remonte jamais à l'appelant.
class DeepLinkService {
  /// Crée le service. [launchUrl] et [canLaunchUrl] sont injectables pour
  /// les tests (simuler la présence/absence d'une app installée sans appel
  /// de plateforme réel) ; par défaut, les fonctions correspondantes de
  /// `package:url_launcher` sont utilisées.
  DeepLinkService({
    Future<bool> Function(Uri url, {url_launcher.LaunchMode mode})? launchUrl,
    Future<bool> Function(Uri url)? canLaunchUrl,
  }) : _launchUrl = launchUrl ?? url_launcher.launchUrl,
       _canLaunchUrl = canLaunchUrl ?? url_launcher.canLaunchUrl;

  final Future<bool> Function(Uri url, {url_launcher.LaunchMode mode})
  _launchUrl;
  final Future<bool> Function(Uri url) _canLaunchUrl;

  /// Ouvre [url] (une vidéo de plateforme [source]) dans son app d'origine
  /// si un schéma natif est connu et qu'une app le gère, sinon dans le
  /// navigateur. Retourne `true` si l'ouverture a réussi par l'un ou
  /// l'autre moyen, `false` seulement dans le cas extrême où aucun des deux
  /// n'y parvient (ex: aucun navigateur disponible sur l'appareil) — ce
  /// n'est jamais un plantage, juste un signal exploitable par l'appelant.
  Future<bool> openInSource(String url, VideoSource source) async {
    final nativeUri = _nativeUriFor(url, source);
    if (nativeUri != null) {
      try {
        if (await _canLaunchUrl(nativeUri) &&
            await _launchUrl(
              nativeUri,
              mode: url_launcher.LaunchMode.externalApplication,
            )) {
          return true;
        }
      } catch (error) {
        debugPrint(
          'DeepLinkService: échec du schéma natif $nativeUri, repli navigateur ($error)',
        );
      }
    }

    try {
      return await _launchUrl(
        Uri.parse(url),
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } catch (error) {
      debugPrint('DeepLinkService: échec du repli navigateur pour $url ($error)');
      return false;
    }
  }

  /// Id numérique en fin de chemin après `/video/` (TikTok).
  static final RegExp _tiktokVideoIdPattern = RegExp(r'/video/(\d+)');

  /// Construit l'URI du schéma natif de [source] pour [url], ou `null` si
  /// aucun schéma natif n'est tenté pour cette plateforme (Threads, X/Twitter
  /// — voir doc de classe —, ou source [VideoSource.unknown]), ou si
  /// l'identifiant précis attendu par le schéma (TikTok) est introuvable
  /// dans [url] — dans ce cas, [openInSource] passe directement au repli
  /// navigateur.
  Uri? _nativeUriFor(String url, VideoSource source) {
    final original = Uri.tryParse(url);
    if (original == null) return null;

    // Reconstruit le chemin d'origine (hôte + chemin + requête) sous le
    // schéma natif de la plateforme — convention observée, non garantie par
    // aucune des plateformes (voir doc de classe).
    String rebuild(String scheme) {
      final query = original.hasQuery ? '?${original.query}' : '';
      return '$scheme://${original.host}${original.path}$query';
    }

    switch (source) {
      case VideoSource.instagram:
        return Uri.tryParse(rebuild('instagram'));
      case VideoSource.tiktok:
        // Schéma tiers attendant l'id numérique de la vidéo, pas une simple
        // reconstruction hôte/chemin (voir doc de classe).
        final id = _tiktokVideoIdPattern.firstMatch(original.path)?.group(1);
        if (id == null) return null;
        return Uri.tryParse('snssdk1233://aweme/detail/$id?refer=web');
      case VideoSource.facebook:
        // Schéma spécifique documenté par des tiers pour ouvrir une URL
        // Facebook arbitraire (pas de simple reconstruction hôte/chemin).
        return Uri.tryParse('fb://facewebmodal/f?href=$url');
      case VideoSource.youtube:
        return Uri.tryParse(rebuild('vnd.youtube'));
      case VideoSource.threads:
      case VideoSource.twitter:
      case VideoSource.website:
      case VideoSource.unknown:
        // Threads : aucun schéma natif connu. X/Twitter : schéma
        // `twitter://` abandonné (Tâche 36, voir doc de classe) au profit
        // du repli direct vers le lien https, plus fiable via les Universal
        // Links/App Links associées à x.com. Site générique (Tâche 38) :
        // aucun schéma natif possible par nature, un site web quelconque
        // n'a pas d'app associée.
        return null;
    }
  }
}
