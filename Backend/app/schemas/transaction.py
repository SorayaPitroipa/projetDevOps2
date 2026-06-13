from pydantic import BaseModel


class TransactionItem(BaseModel):
    date: str
    type: str
    montant: float
    description: str
