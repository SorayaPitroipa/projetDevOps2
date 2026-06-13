from pydantic import BaseModel

class ScoreResult(BaseModel):
    user_id: str
    score: int
    risk_level: str
    profile: str
    revenu_moyen_mensuel: float
    regularite_revenus: float
    ratio_epargne: float
    freq_transactions_mois: float
    capacite_emprunt: float
