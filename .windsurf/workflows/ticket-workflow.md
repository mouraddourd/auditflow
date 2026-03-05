---
description: Workflow pour traiter un ticket GitHub de A à Z
---

# Workflow: Traitement Ticket GitHub

Ce workflow décrit le processus complet pour traiter un ticket GitHub, de la sélection au merge final.

## Vue d'ensemble

```
1. SELECT    → Choisir ticket GitHub
2. BRANCH    → Créer branche auto-nommée
3. DEV       → Développer
4. PRE-CHECK → Lint, tests, build, security
5. PUSH      → Pousser
6. PR        → Créer PR auto-générée
7. REVIEW    → Review code + CI
8. MERGE     → Squash & merge
9. CLEANUP   → Supprimer branche, fermer ticket
```

---

## Étapes détaillées

### 1. SELECT - Choisir un ticket

Lister les tickets ouverts depuis GitHub:

```bash
# Via GitHub CLI
gh issue list --state open --label CRITIQUE,HAUTE,MOYENNE,FAIBLE

# Ou demander à Cascade de lister les tickets
```

**Critères de sélection:**
- Priorité (CRITIQUE > HAUTE > MOYENNE > FAIBLE)
- Dépendances (tickets bloqués par d'autres)
- Assignation (s'assigner le ticket)

**Auto-actions:**
- S'assigner le ticket: `gh issue assign <number> --assignee @me`

---

### 2. BRANCH - Créer la branche

```bash
# Convention: <type>/<description>-<ticket-number>
# Types: feature, fix, refactor, docs, chore

# Exemple pour ticket #3 "Backend Auth JWT"
git checkout master
git pull origin master
git checkout -b feature/backend-auth-jwt-3
```

**Auto-génération du nom:**
- Extraire mots-clés du titre du ticket
- Kebab-case, max 5 mots
- Suffixe: `-<ticket-number>`

---

### 3. DEV - Développer

- Implémenter les changements décrits dans le ticket
- Tester localement
- Suivre les conventions de code du projet

**Commit conventionnel:**
```
<type>(<scope>): <description courte>

- Point 1
- Point 2

Closes #<ticket-number>
```

**Types:** feat, fix, refactor, docs, style, test, chore

---

### 4. PRE-CHECK - Vérifications avant push

**Checklist automatique:**

- [ ] **Build**: `npm run build` ou équivalent
- [ ] **Lint**: Pas d'erreurs de linting
- [ ] **Tests**: Tests unitaires passent
- [ ] **Security**: Pas de secrets en dur (API keys, passwords)
- [ ] **Clean code**: Pas de `console.log`, `print`, `debugger`
- [ ] **Types**: Pas d'erreurs TypeScript
- [ ] **Imports**: Pas d'imports inutilisés

**Si échec:** Corriger avant de continuer.

---

### 5. PUSH - Pousser la branche

```bash
git add .
git commit -m "feat(auth): add JWT authentication endpoints

- Add /auth/register endpoint
- Add /auth/login endpoint with JWT generation
- Add auth middleware for protected routes

Closes #3"

git push origin feature/backend-auth-jwt-3
```

---

### 6. PR - Créer la Pull Request

**Auto-générer le contenu:**

**Titre:** `[<PRIORITÉ>] <Titre court du ticket>`

**Body template:**
```markdown
## Summary
<Résumé du ticket>

## Changes
- **`/endpoint`**: Description
- **Fichier X**: Description

## Files Changed
- `path/to/file.ts` - Description

## Testing
```bash
# Commandes de test
```

## Checklist
- [ ] Code compile
- [ ] Tests passent
- [ ] Pas de secrets
- [ ] Documentation mise à jour

Closes #<ticket-number>
```

**Commande:**
```bash
gh pr create --title "[CRITIQUE] Backend Auth: JWT authentication" --body-file pr-template.md
```

---

### 7. REVIEW - Review de la PR

**Review humaine:**

- [ ] Respecte les conventions de code
- [ ] Pas de régression
- [ ] Sécurité (validation inputs, pas de secrets)
- [ ] Performance acceptable
- [ ] Code lisible et maintenable
- [ ] Tests pertinents

**CI/CD Checks:**

- [ ] Build réussi
- [ ] Tests passent
- [ ] Lint OK
- [ ] Security scan OK

**Si modifications demandées:**
- Corriger sur la même branche
- Push les corrections
- Demander nouvelle review

---

### 8. MERGE - Fusionner

**Méthode recommandée:** Squash and merge

```bash
gh pr merge <pr-number> --squash --delete-branch
```

**Avantages:**
- Historique propre (1 commit = 1 feature)
- Message de commit descriptif
- Branche supprimée automatiquement

---

### 9. CLEANUP - Nettoyage

**Auto-actions post-merge:**

- [ ] Ticket fermé automatiquement (via "Closes #N")
- [ ] Branche distante supprimée
- [ ] Retour sur master: `git checkout master && git pull`
- [ ] Branche locale supprimée: `git branch -d feature/xxx`

**Optionnel:**
- Générer entrée changelog
- Notifier l'équipe
- Mettre à jour la documentation

---

## Checklists par type de ticket

### Feature (feat)

- [ ] Code compile sans erreurs
- [ ] Tests unitaires ajoutés
- [ ] Documentation API mise à jour
- [ ] Pas de breaking changes (ou documentées)

### Bug Fix (fix)

- [ ] Reproduction du bug confirmée
- [ ] Test de régression ajouté
- [ ] Root cause identifiée et corrigée
- [ ] Pas d'effets de bord

### Refactor (refactor)

- [ ] Comportement inchangé
- [ ] Tests existants passent
- [ ] Code plus lisible/maintenable
- [ ] Pas de dégradation de performance

### Documentation (docs)

- [ ] Exemples de code fonctionnels
- [ ] Liens valides
- [ ] Orthographe correcte
- [ ] Screenshots à jour si applicable

---

## Labels de priorité

| Label | Description | SLA |
|-------|-------------|-----|
| CRITIQUE | Bloquant production | < 24h |
| HAUTE | Feature importante | < 3 jours |
| MOYENNE | Feature standard | < 1 semaine |
| FAIBLE | Nice-to-have | Backlog |

---

## Raccourcis Cascade

Demander à Cascade d'exécuter ces étapes:

- "Liste les tickets ouverts" → Étape 1
- "Crée une branche pour le ticket #X" → Étape 2
- "Review le code avant push" → Étape 4
- "Crée une PR pour ce ticket" → Étape 6
- "Review la PR #X" → Étape 7
- "Merge la PR #X" → Étape 8
