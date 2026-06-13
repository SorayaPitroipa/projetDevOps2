# Credit Scoring Wave - Projet Cloud & DevOps

Ce projet est une application de recommandation de notation de crédit basée sur des extraits de compte bancaire.

L'objectif de ce livrable (n°2) est de valider le déploiement Cloud, l'approche CI/CD et l'architecture logicielle via des conteneurs.

## Architecture

L'application est découpée en micro-services :
1. **Frontend** : Application Angular 16 servie via Nginx.
2. **Backend API** : Application FastAPI pour le traitement ML, la validation Google Auth, et la distribution des scores.
3. **Database** : PostgreSQL (bien que testable en SQLite) pour la persistance locale des recommandations de profil.

*(NB - Écart au plan: Bien que l'application soit testable avec SQLite et initialement développée ainsi pour la simplicité locale, le fichier docker-compose utilise une instance `PostgreSQL` pour satisfaire aux attentes explicites d'extensibilité du Livrable 2.)*

## Lancer le projet en local (Docker Compose)

Assurez-vous d'avoir installé **Docker** et **Docker Compose** sur votre machine. Depuis la racine du projet, lancez :

```bash
docker compose up --build -d
```

1. **Frontend** : Accessible via [http://localhost:4200](http://localhost:4200)
2. **Backend (API)** : Accessible via [http://localhost:8000](http://localhost:8000)
3. **Base de données** : Expose le port PostgreSQL classique `5432`

## Documentation et Rapports

Vous trouverez tous les rapports de planification et de validation liés au livrable dans le dossier `docs/` (le rapport final PDF a été généré localement).

## Pipeline CI/CD

Un pipeline automatisé tourne à chaque `push` via **GitHub Actions**. Il valide les règles suivantes :
- Scans de sécurité : `trufflehog` (recherche de clefs d'API exposées) et `pip-audit` / `Trivy`.
- Lancement de tests unitaire `pytest`.
- Construction des images Docker.
- (Optionnel/Activé) : Redirection vers Amazon ECR si branché.

## Développement technique 

- La capacité d'emprunt a été repensée pour être extraite dynamiquement depuis le Backend ML et calculée avec les revenus plutôt qu'inscrite en dur côté UI.
- L'authentification utilise la vérification de jetons JWT sécurisés via OAuth Google. 
