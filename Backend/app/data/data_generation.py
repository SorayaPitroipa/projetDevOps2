import json
import random
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List

from faker import Faker
from .feature_engineering import extract_features_from_transactions

fake = Faker('fr_FR')

PROFILS = {
    'petit': {
        'revenu': (1000, 50000),
        'regularite': 0.85,
        'epargne': (0.05, 0.20),
        'weight': 0.60,
    },
    'moyen': {
        'revenu': (20000, 200000),
        'regularite': 0.70,
        'epargne': (0.10, 0.35),
        'weight': 0.30,
    },
    'haut': {
        'revenu': (50000, 700000),
        'regularite': 0.50,
        'epargne': (0.15, 0.40),
        'weight': 0.10,
    },
}


def sample_skewed_amount(min_value: int, max_value: int, exponent: float = 2.2) -> int:
    """Retourne un montant où les petites valeurs sont beaucoup plus fréquentes que les valeurs maximales."""
    fraction = random.random() ** exponent
    return int(min_value + fraction * (max_value - min_value))


def generate_user_transactions(profil: str, n_mois: int = 8) -> List[Dict]:
    config = PROFILS[profil]
    transactions: List[Dict] = []
    date_debut = datetime.now() - timedelta(days=30 * n_mois)

    for m in range(n_mois):
        date_mois = date_debut + timedelta(days=30 * m)

        if random.random() < config['regularite']:
            for _ in range(random.randint(2, 4)):
                transactions.append({
                    'date': (date_mois + timedelta(days=random.randint(0, 28))).strftime('%Y-%m-%d'),
                    'type': 'entree',
                    'montant': sample_skewed_amount(*config['revenu']),
                    'description': f'Reçu de {fake.name()}',
                })

        ratio_epargne = random.uniform(*config['epargne'])
        sortie_max = min(700000, int(config['revenu'][1] * 1.5))
        for _ in range(random.randint(8, 15)):
            transactions.append({
                'date': (date_mois + timedelta(days=random.randint(0, 28))).strftime('%Y-%m-%d'),
                'type': 'sortie',
                'montant': max(1000, sample_skewed_amount(1000, sortie_max)),
                'description': random.choice([
                    'Paiement marchand',
                    'Transfert envoyé',
                    'Retrait cash',
                    'Facture',
                    'Achat boutique',
                ]),
            })

    return sorted(transactions, key=lambda x: x['date'])


def generate_dataset(n_users: int = 100, n_mois: int = 8) -> List[Dict]:
    dataset: List[Dict] = []
    profils = list(PROFILS.keys())
    poids = [PROFILS[p]['weight'] for p in profils]

    for i in range(n_users):
        profil = random.choices(profils, weights=poids, k=1)[0]
        transactions = generate_user_transactions(profil, n_mois=n_mois)
        features = extract_features_from_transactions(transactions)
        dataset.append({
            'user_id': f'USR_{i+1:04d}',
            'profil': profil,
            'transactions': transactions,
            'features': features,
        })
    return dataset


def save_raw_dataset(dataset: List[Dict], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    raw_data = [
        {
            'user_id': user['user_id'],
            'profil': user['profil'],
            'transactions': user['transactions'],
        }
        for user in dataset
    ]
    with output_path.open('w', encoding='utf-8') as f:
        json.dump(raw_data, f, ensure_ascii=False, indent=2)


def save_features_dataset(dataset: List[Dict], output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    features_data = [
        {
            'user_id': user['user_id'],
            'profil': user['profil'],
            **user['features'],
        }
        for user in dataset
    ]
    with output_path.open('w', encoding='utf-8') as f:
        json.dump(features_data, f, ensure_ascii=False, indent=2)


def main() -> None:
    dataset = generate_dataset(n_users=100, n_mois=8)
    raw_output = Path(__file__).resolve().parent / 'synthetic_users_100_raw.json'
    features_output = Path(__file__).resolve().parent / 'synthetic_users_100_features.json'
    save_raw_dataset(dataset, raw_output)
    save_features_dataset(dataset, features_output)

    print(f'Généré {len(dataset)} utilisateurs dans {raw_output}')
    print(f'Généré {len(dataset)} fiches de features dans {features_output}')
    average_tx = sum(len(user['transactions']) for user in dataset) / len(dataset)
    print(f'Transactions moyennes par utilisateur : {average_tx:.1f}')


if __name__ == '__main__':
    main()
