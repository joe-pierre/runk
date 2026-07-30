import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

import '../models/video_source.dart';

/// Rouvre une vidéo sauvegardée dans son application source, avec repli
/// automatique vers le navigateur (voir SPEC.md section 4 règle 5).
///
/// **Schémas natifs non officiels.** Les schémas utilisés ici
/// (`instagram://`, `snssdk1233://` pour TikTok, `fb://`, `twitter://`,
/// `vnd.youtube://`) ne sont documentés par aucune des plateformes cibles :
/// ce sont des conventions observées, susceptibles de changer ou de cesser
/// de fonctionner sans préavis à la discrétion de l'éditeur de chaque app.
/// Threads n'a, à la connaissance de ce projet, aucun schéma connu — le
/// repli navigateur y est donc systématique. Voir `BUGS_AND_ROADMAP.md`
/// ("Les schémas de deep link natifs... peuvent changer sans préavis") pour
/// le suivi de cette fragilité dans le temps.
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

  /// Construit l'URI du schéma natif de [source] pour [url], ou `null` si
  /// aucun schéma n'est connu pour cette plateforme (Threads, ou source
  /// [VideoSource.unknown]) — dans ce cas, [openInSource] passe directement
  /// au repli navigateur.
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
        return Uri.tryParse(rebuild('snssdk1233'));
      case VideoSource.twitter:
        return Uri.tryParse(rebuild('twitter'));
      case VideoSource.facebook:
        // Schéma spécifique documenté par des tiers pour ouvrir une URL
        // Facebook arbitraire (pas de simple reconstruction hôte/chemin).
        return Uri.tryParse('fb://facewebmodal/f?href=$url');
      case VideoSource.youtube:
        return Uri.tryParse(rebuild('vnd.youtube'));
      case VideoSource.threads:
      case VideoSource.unknown:
        return null;
    }
  }
}
