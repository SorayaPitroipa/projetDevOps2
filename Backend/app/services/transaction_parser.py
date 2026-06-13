import re
from typing import List
from app.models.transaction import Transaction

DATE_RE = re.compile(r"\b(?P<date>\d{4}[-/.]\d{2}[-/.]\d{2}|\d{2}[-/.]\d{2}[-/.]\d{4})\b")
AMOUNT_RE = re.compile(r"(?P<amount>[-+]?[\d ]{1,18}(?:[.,]\d{1,2})?)\s*€?")
ENTRY_KEYWORDS = [
    "reçu",
    "revenu",
    "versement",
    "salair",
    "salaire",
    "remboursement",
    "virement reçu",
    "dépôt",
    "deposit",
]
EXIT_KEYWORDS = [
    "paiement",
    "facture",
    "achat",
    "retrait",
    "transfert envoyé",
    "prélèvement",
    "débit",
    "euro",
    "versement sorti",
]


def _normalize_date(text: str) -> str:
    cleaned = text.replace('.', '/').replace('-', '/')
    parts = cleaned.split('/')
    if len(parts) == 3:
        if len(parts[0]) == 4:
            year, month, day = parts
        else:
            day, month, year = parts
        return f"{year}-{month.zfill(2)}-{day.zfill(2)}"
    return text


def _normalize_amount(amount_str: str) -> float:
    cleaned = amount_str.replace("€", "").replace(" ", "").replace(",", ".")
    cleaned = cleaned.replace("+", "").replace("−", "-").replace("—", "-")
    try:
        return float(cleaned)
    except ValueError:
        return 0.0


def _infer_type(description: str, amount: float) -> str:
    lower_desc = description.lower()
    if amount < 0:
        return "sortie"
    if any(keyword in lower_desc for keyword in ENTRY_KEYWORDS):
        return "entree"
    if any(keyword in lower_desc for keyword in EXIT_KEYWORDS):
        return "sortie"
    return "entree" if amount > 0 else "sortie"


def _parse_grouped_transaction(lines: List[str], index: int):
    date_line = lines[index]
    date_match = DATE_RE.search(date_line)
    if not date_match:
        return None

    date = _normalize_date(date_match.group("date"))
    next_index = index + 1
    if next_index + 2 < len(lines):
        type_line = lines[next_index].strip().lower()
        amount_line = lines[next_index + 1].strip()
        description_line = lines[next_index + 2].strip()
        if type_line in ("entree", "sortie"):
            amount_match = AMOUNT_RE.search(amount_line)
            if amount_match:
                amount = _normalize_amount(amount_match.group("amount"))
                type_ = "entree" if type_line == "entree" else "sortie"
                return (
                    Transaction(
                        date=date,
                        type=type_,
                        montant=abs(amount),
                        description=description_line or "Opération",
                    ),
                    3,
                )

    return None


def parse_transactions(raw_text: str) -> List[Transaction]:
    lines = [line.strip() for line in raw_text.splitlines() if line.strip()]
    transactions: List[Transaction] = []
    index = 0

    while index < len(lines):
        grouped = _parse_grouped_transaction(lines, index)
        if grouped is not None:
            transaction, skip = grouped
            transactions.append(transaction)
            index += skip + 1
            continue

        line = lines[index]
        date_match = DATE_RE.search(line)
        if not date_match:
            index += 1
            continue

        date = _normalize_date(date_match.group("date"))
        after_date = line[date_match.end():].strip()
        if not after_date:
            after_date = line[: date_match.start()].strip()

        amount_matches = list(AMOUNT_RE.finditer(after_date))
        if not amount_matches:
            amount_matches = list(AMOUNT_RE.finditer(line))
        if not amount_matches:
            index += 1
            continue

        amount_match = amount_matches[-1]
        amount_token = amount_match.group("amount")
        amount = _normalize_amount(amount_token)

        description = after_date[: amount_match.start()].strip()
        if not description:
            description = after_date[amount_match.end():].strip()
        if not description:
            description = line[: date_match.start()].strip()

        type_ = _infer_type(description, amount)
        transactions.append(
            Transaction(
                date=date,
                type=type_,
                montant=abs(amount),
                description=description or "Opération",
            )
        )
        index += 1

    return transactions
