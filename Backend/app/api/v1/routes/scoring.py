from fastapi import APIRouter, Depends, HTTPException
from app.schemas.scoring import ScoreResult
from app.services.scoring_engine import get_user_score
from app.core.security import get_api_key

router = APIRouter()

@router.get("/score/{user_id}", response_model=ScoreResult, dependencies=[Depends(get_api_key)])
async def get_score(user_id: str):
    score_data = get_user_score(user_id)
    if score_data is None:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable.")

    if isinstance(score_data, int):
        score_data = {
            'score': score_data,
            'profile': 'N/A',
            'features': {},
        }

    features = score_data.get('features', {})
    return ScoreResult(
        user_id=user_id,
        score=score_data['score'],
        risk_level=_determine_risk(score_data['score']),
        profile=score_data.get('profile', 'N/A'),
        revenu_moyen_mensuel=features.get('revenu_moyen_mensuel', 0.0),
        regularite_revenus=features.get('regularite_revenus', 0.0),
        ratio_epargne=features.get('ratio_epargne', 0.0),
        freq_transactions_mois=features.get('freq_transactions_mois', 0.0),
    )


def _determine_risk(score: int) -> str:
    if score >= 750:
        return "Faible"
    if score >= 650:
        return "Moyen"
    return "Élevé"
