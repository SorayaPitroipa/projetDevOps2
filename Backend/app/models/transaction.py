from pydantic import BaseModel


class Transaction(BaseModel):
    date: str
    type: str
    montant: float
    description: str
