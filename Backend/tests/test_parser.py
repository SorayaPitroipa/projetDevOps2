from app.services.transaction_parser import parse_transactions


def test_parse_transactions_simple_text():
    raw_text = "2026-06-01 Paiement client 1200.50\n2026-06-02 Achat café -2.50"
    transactions = parse_transactions(raw_text)

    assert len(transactions) == 2
    assert transactions[0].date == "2026-06-01"
    assert transactions[0].montant == 1200.50
    assert transactions[1].description == "Achat café"


def test_parse_transactions_french_date_and_currency():
    raw_text = "01.06.2026 Virement reçu 1 200,50 €\n02/06/2026 Achat épicerie -45,20 €"
    transactions = parse_transactions(raw_text)

    assert len(transactions) == 2
    assert transactions[0].date == "2026-06-01"
    assert transactions[0].montant == 1200.50
    assert transactions[1].date == "2026-06-02"
    assert transactions[1].montant == 45.20
