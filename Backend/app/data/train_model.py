import joblib
import pandas as pd
from pathlib import Path
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.metrics import mean_absolute_error, r2_score
from sklearn.model_selection import train_test_split


FEATURES = [
    'revenu_moyen',
    'revenu_median',
    'revenu_std',
    'revenu_moyen_mensuel',
    'ratio_depenses',
    'score_depenses',
    'ratio_epargne',
    'solde_net',
    'duree_retention_moyenne',
    'regularite_revenus',
    'nb_mois_actifs',
    'freq_transactions_mois',
    'nb_entrees',
    'nb_sorties',
]
TARGET = 'capacite_emprunt'


def load_features_dataset(features_path: Path):
    df = pd.read_json(features_path)
    return df


def train(features_path: Path, output_path: Path):
    df = load_features_dataset(features_path)
    X = df[FEATURES]
    y = df[TARGET]

    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    model = GradientBoostingRegressor(n_estimators=200, max_depth=5, random_state=42)
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    print(f'MAE  : {mean_absolute_error(y_test, y_pred):,.0f} FCFA')
    print(f'R²   : {r2_score(y_test, y_pred):.3f}')

    output_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, output_path)
    print(f'Modèle sauvegardé dans {output_path}')


if __name__ == '__main__':
    features_path = Path(__file__).resolve().parent / 'synthetic_users_100_features.json'
    output_path = Path(__file__).resolve().parent.parent / 'models' / 'scoring_model.pkl'
    train(features_path, output_path)
