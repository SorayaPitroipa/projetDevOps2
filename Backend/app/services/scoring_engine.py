import json
import joblib
from pathlib import Path
from typing import List, Optional

import pandas as pd
from app.data.feature_engineering import extract_features_from_transactions
from app.models.transaction import Transaction

SCORE_STORE_PATH = Path(__file__).resolve().parents[1] / "data" / "score_history.json"

def calculate_heuristic_score(features: dict) -> int:
    """Calcul intelligent du score base sur des regles metier"""
    base_score = 500
    
    # +100 pour la capacite d'epargne (10% = 10 pts, jusqu'a 100 max)
    ratio_epargne = features.get("ratio_epargne", 0.0)
    base_score += min(150, int(ratio_epargne * 1000))
    
    # -100 pour irregularite
    regularite = features.get("regularite_revenus", 0.0)
    if regularite > 0.5:
        base_score -= 50
    elif regularite > 0.8:
        base_score -= 100
    else:
        base_score += 50
        
    # +100 pour revenus hauts
    revenu = features.get("revenu_moyen_mensuel", 0.0)
    if revenu > 1000000:
        base_score += 150
    elif revenu > 500000:
        base_score += 100
    elif revenu > 100000:
        base_score += 50
        
    return int(max(300, min(850, base_score)))


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

    transaction_dicts = [tx.model_dump() if hasattr(tx, 'model_dump') else tx.dict() for tx in transactions]
    features = extract_features_from_transactions(transaction_dicts)
    return calculate_heuristic_score(features)


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
    
    # Recalcul de l'emprunt au moment de la sauvegarde pour s'assurer qu'il varie avec le score 
    cap_emp = features.get('capacite_emprunt', 0.0)
    rev = features.get('revenu_moyen_mensuel', 0.0)
    
    # Ajustement standard : on prête en moyenne 33% du revenu sur 12 mois multiplié par le % de credit score
    cap_emp = rev * 0.33 * 12 * (score/850.0)
    features['capacite_emprunt'] = float(cap_emp)
    
    store[user_id] = {
        'score': score,
        'profile': profile,
        'features': features,
    }
    _save_score_store(store)


def get_user_score(user_id: str) -> Optional[dict]:
    store = _load_score_store()
    return store.get(user_id)
