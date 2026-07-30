import receive_sharing_intent

/// Vue de la Share Extension iOS (`RunkShareExtension`), affichée par le système
/// quand l'utilisateur partage un lien vidéo depuis Instagram/TikTok/etc. vers Runk.
///
/// Toute la logique (extraction de l'URL partagée, écriture dans le conteneur
/// `UserDefaults(suiteName:)` de l'App Group `group.com.senluxtech.runk`, puis
/// redirection vers l'app hôte) est déjà implémentée par `RSIShareViewController`,
/// fournie par le package `receive_sharing_intent`. Cette classe ne fait que
/// personnaliser l'UI système pour rester cohérente avec le reste de Runk
/// (voir CONVENTIONS.md — textes utilisateur en français).
///
/// Aucune logique de validation d'URL ici : elle reste centralisée dans
/// `ShareIntentService` côté Dart (voir TASK_PROMPTS.md Tâche 3), qui reçoit
/// cette donnée via `receive_sharing_intent` sans distinction Android/iOS.
class ShareViewController: RSIShareViewController {

    /// Personnalise le libellé du bouton de validation de la feuille de partage
    /// système ("Post" par défaut) pour rester en français.
    override func presentationAnimationDidFinish() {
        super.presentationAnimationDidFinish()
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = "Ajouter"
    }
}
