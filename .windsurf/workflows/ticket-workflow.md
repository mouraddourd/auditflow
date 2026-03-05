---
description: Workflow pour traiter un ticket GitHub de A à Z
---

# Workflow: Traitement Ticket GitHub

Ce workflow décrit le processus complet pour traiter un ticket GitHub, de la création de la branche au merge final.

## Prérequis
- Avoir un ticket GitHub assigné avec une description claire
- Être sur la branche `main` ou `master` à jour

## Étapes

### 1. Créer une branche feature
```bash
# Récupérer le numéro du ticket (ex: #3)
# Nommer la branche: feature/<description-courte>-<ticket-number>
git checkout main
git pull origin main
git checkout -b feature/backend-auth-jwt-3
```

### 2. Développer
- Implémenter les changements décrits dans le ticket
- Tester localement
- Commiter avec des messages clairs:
  ```
  feat(auth): add JWT authentication endpoints
  
  - Add /auth/register endpoint
  - Add /auth/login endpoint with JWT generation
  - Add auth middleware for protected routes
  
  Closes #3
  ```

### 3. Pousser et créer la Pull Request
```bash
git push origin feature/backend-auth-jwt-3
```
Puis créer la PR via GitHub avec:
- Titre: `[TICKET-NUMBER] Description courte`
- Body: Référence au ticket, résumé des changements, tests effectués

### 4. Review
- Vérifier que les tests passent (CI)
- Relire le code
- Tester manuellement si nécessaire
- Approuver ou demander des modifications

### 5. Merge
- Squash and merge (recommandé pour garder un historique propre)
- Supprimer la branche après merge
- Fermer le ticket automatiquement (via "Closes #N" dans le commit)

## Checklist avant PR
- [ ] Code compile sans erreurs
- [ ] Tests unitaires passent
- [ ] Pas de `console.log` ou `print` de debug
- [ ] Variables d'environnement documentées
- [ ] Breaking changes documentées

## Checklist Review
- [ ] Respecte les conventions de code
- [ ] Pas de régression
- [ ] Sécurité (pas de secrets en dur, validation des inputs)
- [ ] Performance acceptable
