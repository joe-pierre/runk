# BUGS CORRIGÉS

*(Aucun bug corrigé à ce jour — projet en phase d'implémentation initiale. Cette section sera mise à jour par Claude Code à la fin de chaque tâche corrective, avec le format : `- **[Date]** Description du bug corrigé — cause identifiée — fichier(s) concerné(s)`.)*

# ROADMAP (idées / améliorations futures)

## Monétisation
- Modèle freemium : gratuit jusqu'à un nombre limité de bookmarks, illimité en payant
- Abonnement mensuel (~2-5$/mois) pour la synchronisation cloud multi-appareils et des fonctionnalités avancées
- Alternative : achat unique de l'application sans palier gratuit

## Fonctionnalités futures
- Supabase Realtime pour synchronisation instantanée multi-appareils (voir `SPEC.md` section 6, non implémenté en V1)
- Export des bookmarks (CSV / JSON) pour sauvegarde personnelle
- Partage d'une collection de bookmarks avec un autre utilisateur Runk (lecture seule)
- Détection de doublons (même URL déjà sauvegardée)
- Suggestions de tags basées sur les tags déjà utilisés par l'utilisateur (autocomplétion)
- Widget d'accueil (Android/iOS) affichant les derniers bookmarks ajoutés
- Version web ou tablette légère, en lecture, s'appuyant sur le même backend Supabase

## Points de vigilance techniques identifiés
- Les schémas de deep link natifs (`instagram://`, `snssdk1233://` pour TikTok, etc.) ne sont pas documentés officiellement par les plateformes et peuvent changer sans préavis — prévoir une vérification périodique (voir `guide.md` section 7.5)
- Le scraping de balises `og:` pour Instagram/Facebook/Threads est fragile par nature : surveiller le taux de `is_partial = true` en production comme indicateur de santé de chaque provider
- Politique de conservation des données à clarifier si une fonctionnalité d'export ou de partage entre utilisateurs est ajoutée (RGPD si expansion vers l'UE)
