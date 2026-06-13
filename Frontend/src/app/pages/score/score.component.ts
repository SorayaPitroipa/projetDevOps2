import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { ApiService, ScoreResult } from '../../services/api.service';

@Component({
  selector: 'app-score',
  templateUrl: './score.component.html',
  styleUrls: ['./score.component.css']
})
export class ScoreComponent implements OnInit {
  userId = '';
  score: ScoreResult | null = null;
  loading = false;
  errorMessage = '';

  constructor(
    private route: ActivatedRoute,
    private apiService: ApiService
  ) {}

  ngOnInit(): void {
    this.route.paramMap.subscribe(params => {
      const userId = params.get('userId');
      if (userId) {
        this.userId = userId;
        this.fetchScore(userId);
      }
    });
  }

  fetchScore(userId: string): void {
    this.loading = true;
    this.errorMessage = '';
    this.score = null;

    this.apiService.getScore(userId).subscribe({
      next: result => {
        this.loading = false;
        this.score = result;
      },
      error: () => {
        this.loading = false;
        this.errorMessage = 'Impossible de récupérer le score. Vérifiez que le backend est en ligne.';
      }
    });
  }

  get scorePercent(): number {
    return this.score ? Math.round((this.score.score / 850) * 100) : 0;
  }

  get scoreArcOffset(): number {
    return this.score ? Math.max(0, 471 - (this.score.score / 850) * 471) : 471;
  }

  get scoreColor(): string {
    if (!this.score) {
      return '#a04100';
    }
    if (this.score.score >= 750) {
      return '#1c7a4d';
    }
    if (this.score.score >= 650) {
      return '#d29c00';
    }
    return '#ba1a1a';
  }

  get revenuMoyen(): string {
    if (!this.score) {
      return 'N/A';
    }
    return `${this.score.revenu_moyen_mensuel.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} FCFA`;
  }

  get regularityPercent(): number {
    if (!this.score) {
      return 0;
    }
    const pct = 100 - Math.round(this.score.regularite_revenus * 100);
    return Math.max(0, Math.min(100, pct));
  }

  get savingRatio(): string {
    if (!this.score) {
      return 'N/A';
    }
    const ratio = Math.max(0, this.score.ratio_epargne);
    return `${Math.round(ratio * 100)}% / mois`;
  }

  get transactionFrequency(): string {
    if (!this.score) {
      return 'N/A';
    }
    const daily = Math.round((this.score.freq_transactions_mois / 30) * 10) / 10;
    return `${daily.toFixed(1)} trans./jour`;
  }

  getBadgeStatus(type: 'income' | 'regularity' | 'savings' | 'frequency'): string {
    if (!this.score) {
      return '';
    }

    if (type === 'income') {
      return this.score.revenu_moyen_mensuel >= 100000 ? 'EXCELLENT' : this.score.revenu_moyen_mensuel >= 50000 ? 'BON' : 'A AMÉLIORER';
    }
    if (type === 'regularity') {
      return this.regularityPercent >= 80 ? 'EXCELLENT' : this.regularityPercent >= 60 ? 'BON' : 'A AMÉLIORER';
    }
    if (type === 'savings') {
      return this.score.ratio_epargne >= 0.2 ? 'BON' : 'A AMÉLIORER';
    }
    return this.score.freq_transactions_mois <= 10 ? 'BON' : 'A AMÉLIORER';
  }

  getBadgeClass(status: string): string {
    if (status === 'EXCELLENT') {
      return 'bg-[#ECFDF5] text-[#166534]';
    }
    if (status === 'BON') {
      return 'bg-[#EFF6FF] text-[#1E40AF]';
    }
    return 'bg-[#FFF7ED] text-[#C2410C]';
  }
}
