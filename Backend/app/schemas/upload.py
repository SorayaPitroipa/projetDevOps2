from typing import Dict, List
from pydantic import BaseModel

from app.schemas.transaction import TransactionItem


class UploadResponse(BaseModel):
    filename: str
    user_id: str
    profile: str
    transaction_count: int
    score: int
    transactions: List[TransactionItem]
    features: Dict[str, float]
