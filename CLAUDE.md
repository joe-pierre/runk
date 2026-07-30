# CLAUDE.md — Contexte et prompt d'amorçage

## Contexte du projet

**Runk** est une application mobile Flutter permettant de sauvegarder et catégoriser des vidéos trouvées sur YouTube, Instagram, TikTok, Facebook, X (Twitter) et Threads. L'utilisateur partage un lien vidéo depuis n'importe laquelle de ces apps vers Runk, qui récupère automatiquement la miniature et le titre, permet d'ajouter des tags, puis affiche la vidéo dans une liste unifiée. Un tap sur la vignette rouvre la vidéo directement dans son app d'origine.

Stack : Flutter, Riverpod, GoRouter, Isar (local, offline-first), Supabase (Auth + Postgres + Storage). Détail complet dans `SPEC.md`.

## Prompt d'amorçage (à exécuter au début de chaque session)

Au début de chaque session, lis dans cet ordre :
1. `SPEC.md` — spécifications fonctionnelles et techniques
2. `CONVENTIONS.md` — règles de codage
3. `TODO.md` — état d'avancement des tâches
4. `DECISIONS.md` — décisions techniques et bugs résolus
5. `CODE_SNAPSHOT.md` — snapshot du code actuel

Puis résume en 5 points :
- Ce que fait le projet
- La stack technique utilisée
- L'état d'avancement actuel
- Les conventions importantes à respecter
- Les décisions clés déjà prises

Ensuite, consulte `TASK_PROMPTS.md` pour l'instruction détaillée de la prochaine tâche non cochée dans `TODO.md`, et ne commence le développement qu'après avoir confirmé la compréhension de son critère d'acceptation.

À la fin de chaque tâche :
- Mets à jour `DECISIONS.md` si une décision technique a été prise ou un bug résolu
- Mets à jour `TODO.md` pour cocher les tâches accomplies et ajouter les suivantes
- Mets à jour `BUGS_AND_ROADMAP.md` si un bug a été corrigé ou une idée identifiée

---

## Formats des fichiers Markdown modifiables

### Format `TODO.md`

````markdown
# TODO

## Phase X — Nom de la phase
- [ ] Tâche à faire
- [x] Tâche accomplie
````

### Format `DECISIONS.md`

````markdown
## [RÉSOLU|CHOIX] Titre de la décision

**Contexte :** ...
**Symptôme / Problème :** ...
**Cause / Alternatives :** ...
**Fix / Décision :** ...
**Leçon :** ...
**Statut :** ✅ Résolu | 🔵 Choix assumé
````

### Format `BUGS_AND_ROADMAP.md`

````markdown
# BUGS CORRIGÉS
- **[Date]** Description du bug corrigé — cause identifiée — fichier(s) concerné(s)

# ROADMAP (idées / améliorations futures)
- Idée ou amélioration à envisager
````

## Rappel des règles de qualité non négociables

Voir le détail complet dans `CONVENTIONS.md`, mais les points suivants s'appliquent à **toute** tâche sans exception :
- Aucun "god file" — un fichier, une responsabilité.
- Séparation stricte présentation / domaine / données.
- Nommage explicite, aucune abréviation ambiguë.
- Documentation `///` sur chaque classe et fonction publique.
- Aucune clé secrète en dur dans le code.
