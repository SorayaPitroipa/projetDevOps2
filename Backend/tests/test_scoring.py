from app.services.scoring_engine import calculate_score
from app.models.transaction import Transaction


def test_calculate_score_with_transactions():
    transactions = [
        Transaction(date="2026-06-01", type="entree", montant=100.0, description="Vente"),
        Transaction(date="2026-06-02", type="sortie", montant=50.0, description="Achat"),
    ]
    score = calculate_score(transactions)
    assert isinstance(score, int)
    assert 300 <= score <= 850


def test_calculate_score_model_prediction():
    transactions = [
        Transaction(date="2026-06-10", type="entree", montant=120000.0, description="Reçu salaire"),
        Transaction(date="2026-06-15", type="sortie", montant=25000.0, description="Paiement marchand"),
        Transaction(date="2026-06-20", type="sortie", montant=10000.0, description="Facture"),
    ]
    score = calculate_score(transactions)
    assert isinstance(score, int)
    assert 300 <= score <= 850
