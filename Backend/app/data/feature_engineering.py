import numpy as np
import pandas as pd


def compute_retention(df: pd.DataFrame) -> float:
    """Durée moyenne (en jours) entre une entrée et la sortie suivante significative."""
    entrees = df[df['type'] == 'entree'].reset_index(drop=True)
    sorties = df[df['type'] == 'sortie'].reset_index(drop=True)
    durees = []

    for _, entree in entrees.iterrows():
        sorties_apres = sorties[sorties['date'] > entree['date']]
        if not sorties_apres.empty:
            prochaine_sortie = sorties_apres.iloc[0]
            duree = (prochaine_sortie['date'] - entree['date']).days
            durees.append(duree)

    return float(np.mean(durees)) if durees else 0.0


def extract_features_from_transactions(transactions: list) -> dict:
    df = pd.DataFrame(transactions)
    df['date'] = pd.to_datetime(df['date'])
    df = df.sort_values('date')

    entrees = df[df['type'] == 'entree']
    sorties = df[df['type'] == 'sortie']

    revenu_total = float(entrees['montant'].sum())
    revenu_moyen = float(entrees['montant'].mean()) if not entrees.empty else 0.0
    revenu_median = float(entrees['montant'].median()) if not entrees.empty else 0.0
    revenu_std = float(entrees['montant'].std(ddof=0)) if len(entrees) > 1 else 0.0

    depenses_total = float(sorties['montant'].sum())
    depense_moyenne = float(sorties['montant'].mean()) if not sorties.empty else 0.0
    depense_max = float(sorties['montant'].max()) if not sorties.empty else 0.0
    ratio_depenses = float(depenses_total / max(revenu_total, 1.0))

    solde_net = revenu_total - depenses_total
    ratio_epargne = float(solde_net / max(revenu_total, 1.0))

    retention = compute_retention(df)

    entrees_par_mois = entrees.groupby(entrees['date'].dt.to_period('M'))['montant'].sum()
    regularite = float(entrees_par_mois.std(ddof=0) / max(entrees_par_mois.mean(), 1.0)) if len(entrees_par_mois) > 0 else 0.0
    nb_mois_actifs = int(len(entrees_par_mois))

    nb_transactions_total = len(df)
    nb_entrees = len(entrees)
    nb_sorties = len(sorties)
    freq_transactions_mois = float(nb_transactions_total / max(nb_mois_actifs, 1))

    petites_depenses = float(sorties[sorties['montant'] < depense_moyenne]['montant'].sum()) if not sorties.empty else 0.0
    score_depenses = float(petites_depenses / max(depenses_total, 1.0)) if depenses_total > 0 else 0.0

    revenu_moyen_mensuel = float(entrees_par_mois.mean()) if nb_mois_actifs > 0 else 0.0
    capacite_emprunt = float(revenu_moyen_mensuel * 0.30 * min(nb_mois_actifs, 12))

    return {
        'revenu_total': revenu_total,
        'revenu_moyen': revenu_moyen,
        'revenu_median': revenu_median,
        'revenu_std': revenu_std,
        'revenu_moyen_mensuel': revenu_moyen_mensuel,
        'depenses_total': depenses_total,
        'depense_moyenne': depense_moyenne,
        'depense_max': depense_max,
        'ratio_depenses': ratio_depenses,
        'score_depenses': score_depenses,
        'solde_net': solde_net,
        'ratio_epargne': ratio_epargne,
        'duree_retention_moyenne': retention,
        'regularite_revenus': regularite,
        'nb_mois_actifs': nb_mois_actifs,
        'nb_transactions_total': nb_transactions_total,
        'nb_entrees': nb_entrees,
        'nb_sorties': nb_sorties,
        'freq_transactions_mois': freq_transactions_mois,
        'capacite_emprunt': capacite_emprunt,
    }
