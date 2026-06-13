# Credit Scoring Wave

Backend FastAPI pour l'analyse de relevés Wave et le calcul de score de crédit.

## Structure

- `app/main.py` : point d'entrée FastAPI
- `app/api/v1/routes/upload.py` : route POST `/upload-statement`
- `app/api/v1/routes/scoring.py` : route GET `/score/{user_id}`
- `app/core/config.py` : configuration et variables d'environnement
- `app/core/security.py` : protection par clé API
- `app/services/` : extraction PDF, parsing et scoring
- `app/models/` : schémas métier
- `app/schemas/` : schémas Pydantic request / response
- `tests/` : tests unitaires

## Installation

```bash
python -m pip install -r requirements.txt
```

## Lancement

```bash
uvicorn app.main:app --reload
```

## API

- `POST /api/v1/upload-statement` : téléversement d'un PDF de relevé
- `GET /api/v1/score/{user_id}` : récupération d'un score fictif

## Configuration

Copiez `.env` et adaptez la clé API :

```env
API_KEY=changeme
UPLOAD_DIR=uploads
```
