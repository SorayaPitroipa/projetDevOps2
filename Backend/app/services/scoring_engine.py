import json
import joblib
from pathlib import Path
from typing import List, Optional

import pandas as pd
from app.data.feature_engineering import extract_features_from_transactions
from app.models.transaction import Transaction

MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "scoring_model.pkl"
SCORE_STORE_PATH = Path(__file__).resolve().parents[1] / "data" / "score_history.json"
FEATURE_COLUMNS = [
    'revenu_moyen',
    'revenu_median',
    'revenu_std',
    'revenu_moyen_mensuel',
    'ratio_depenses',
    'score_depenses',
    'ratio_epargne',
    'solde_net',
    'duree_retention_moyenne',
    'regularite_revenus',
    'nb_mois_actifs',
    'freq_transactions_mois',
    'nb_entrees',
    'nb_sorties',
]


def _load_model():
    if MODEL_PATH.exists():
        return joblib.load(MODEL_PATH)
    return None


def _predict_from_model(features: dict) -> Optional[int]:
    model = _load_model()
    if model is None:
        return None

    values = [features.get(name, 0.0) for name in FEATURE_COLUMNS]
    try:
        df = pd.DataFrame([values], columns=FEATURE_COLUMNS)
        prediction = model.predict(df)[0]
        return int(max(300, min(850, round(prediction))))
    except Exception:
        return None


def infer_profile(features: dict) -> str:
    revenu_moyen_mensuel = features.get('revenu_moyen_mensuel', 0.0)
    ratio_epargne = features.get('ratio_epargne', 0.0)
    revenu_total = features.get('revenu_total', 0.0)

    if revenu_total < 50000 or revenu_moyen_mensuel < 20000:
        return 'petit'
    if revenu_moyen_mensuel < 100000 or ratio_epargne < 0.20:
        return 'moyen'
    return 'haut'


def calculate_score(transactions: List[Transaction]) -> int:
    if not transactions:
        return 300

    transaction_dicts = [tx.dict() for tx in transactions]
    features = extract_features_from_transactions(transaction_dicts)
    model_score = _predict_from_model(features)
    if model_score is not None:
        return model_score

    total = sum(tx.montant for tx in transactions)
    average_transaction = abs(total) / len(transactions)
    return int(max(300, min(850, 850 - average_transaction)))


def _load_score_store() -> dict[str, int]:
    try:
        if SCORE_STORE_PATH.exists():
            with SCORE_STORE_PATH.open("r", encoding="utf-8") as f:
                return json.load(f)
    except (json.JSONDecodeError, OSError):
        pass
    return {}


def _save_score_store(store: dict[str, int]) -> None:
    try:
        SCORE_STORE_PATH.parent.mkdir(parents=True, exist_ok=True)
        with SCORE_STORE_PATH.open("w", encoding="utf-8") as f:
            json.dump(store, f, ensure_ascii=False, indent=2)
    except OSError:
        pass


def save_user_score(user_id: str, score: int, profile: str, features: dict) -> None:
    store = _load_score_store()
    store[user_id] = {
        'score': score,
        'profile': profile,
        'features': features,
    }
    _save_score_store(store)


def get_user_score(user_id: str) -> Optional[dict]:
    store = _load_score_store()
    return store.get(user_id)
