from fastapi import APIRouter, File, UploadFile, Depends, HTTPException
from starlette.status import HTTP_201_CREATED
from pathlib import Path
import shutil
import uuid

from app.schemas.upload import UploadResponse
from app.services.pdf_extractor import extract_text_from_pdf
from app.services.transaction_parser import parse_transactions
from app.services.scoring_engine import calculate_score, infer_profile, save_user_score
from app.data.feature_engineering import extract_features_from_transactions
from app.core.security import get_api_key
from app.core.config import settings

router = APIRouter()

@router.post("/upload-statement", response_model=UploadResponse, status_code=HTTP_201_CREATED, dependencies=[Depends(get_api_key)])
async def upload_statement(file: UploadFile = File(...)):
    if file.content_type != "application/pdf":
        raise HTTPException(status_code=400, detail="Le fichier doit être un PDF.")

    upload_dir = Path(settings.UPLOAD_DIR)
    upload_dir.mkdir(parents=True, exist_ok=True)
    destination = upload_dir / f"{uuid.uuid4().hex}_{file.filename}"

    with destination.open("wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    if destination.stat().st_size == 0:
        raise HTTPException(status_code=400, detail="Le fichier PDF est vide ou n'a pas été téléchargé correctement.")

    text = extract_text_from_pdf(destination)
    if not text.strip():
        raise HTTPException(status_code=400, detail="Impossible d'extraire le texte du PDF. Vérifiez que le fichier est un PDF valide et non corrompu.")

    transactions = parse_transactions(text)
    if not transactions:
        raise HTTPException(status_code=400, detail="Aucune transaction trouvée dans le PDF.")

    transaction_dicts = [transaction.dict() for transaction in transactions]
    features = extract_features_from_transactions(transaction_dicts)
    profile = infer_profile(features)
    score = calculate_score(transactions)
    user_id = f"USR_{uuid.uuid4().hex[:8]}"
    save_user_score(user_id, score, profile, features)

    return UploadResponse(
        filename=destination.name,
        user_id=user_id,
        profile=profile,
        transaction_count=len(transactions),
        score=score,
        transactions=transaction_dicts,
        features=features,
    )
