import { Component, OnInit } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { ApiService, ScoreResult } from '../../services/api.service';
import jsPDF from 'jspdf';
import { SocialAuthService } from '@abacritt/angularx-social-login';
import { Router } from '@angular/router';

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
  userInitials: string = '';
  userOptionsOpen: boolean = false;

  constructor(
    private route: ActivatedRoute,
    private apiService: ApiService,
    private authService: SocialAuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    const userStr = localStorage.getItem('user');
    if (userStr) {
      const user = JSON.parse(userStr);
      const f = user.firstName || '';
      const l = user.lastName || '';
      this.userInitials = (f[0] || '') + (l[0] || '');
      if (!this.userInitials && user.name) {
        this.userInitials = user.name.substring(0, 2).toUpperCase();
      }
    } else {
      this.userInitials = 'U';
    }

    this.route.paramMap.subscribe(params => {
      const userId = params.get('userId');
      if (userId) {
        this.userId = userId;
        this.fetchScore(userId);
      }
    });
  }

  logout() {
    this.authService.signOut().catch(() => {});
    localStorage.removeItem('user');
    this.router.navigate(['/login']);
  }
  
  toggleUserOptions() {
    this.userOptionsOpen = !this.userOptionsOpen;
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
    if (!this.score) { return '#a04100'; }
    if (this.score.score >= 750) { return '#1c7a4d'; }
    if (this.score.score >= 650) { return '#d29c00'; }
    return '#ba1a1a';
  }

  get revenuMoyen(): string {
    if (!this.score) { return 'N/A'; }
    return `${this.score.revenu_moyen_mensuel.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} FCFA`;
  }

  get regularityPercent(): number {
    if (!this.score) { return 0; }
    const pct = 100 - Math.round(this.score.regularite_revenus * 100);
    return Math.max(0, Math.min(100, pct));
  }

  get savingRatio(): string {
    if (!this.score) { return 'N/A'; }
    const ratio = Math.max(0, this.score.ratio_epargne);
    return `${Math.round(ratio * 100)}% / mois`;
  }

  get transactionFrequency(): string {
    if (!this.score) { return 'N/A'; }
    const daily = Math.round((this.score.freq_transactions_mois / 30) * 10) / 10;
    return `${daily.toFixed(1)} trans./jour`;
  }

  getBadgeStatus(type: 'income' | 'regularity' | 'savings' | 'frequency'): string {
    if (!this.score) { return ''; }

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
    if (status === 'EXCELLENT') { return 'bg-[#ECFDF5] text-[#166534]'; }
    if (status === 'BON') { return 'bg-[#EFF6FF] text-[#1E40AF]'; }
    return 'bg-[#FFF7ED] text-[#C2410C]';
  }

  downloadReport(): void {
    if (!this.score) { return; }
    const doc = new jsPDF();
    const dateStr = new Date().toLocaleDateString('fr-FR');
    
    // Titre
    doc.setFont("helvetica", "bold");
    doc.setFontSize(22);
    doc.text("CEquality", 105, 20, { align: "center" });
    doc.setFontSize(16);
    doc.text("RAPPORT DE SCORE DE CRÉDIT", 105, 30, { align: "center" });
    
    // Ligne séparatrice
    doc.setLineWidth(0.5);
    doc.line(20, 35, 190, 35);
    
    // Infos
    doc.setFontSize(12);
    doc.setFont("helvetica", "normal");
    doc.text(`ID Utilisateur : ${this.userId}`, 20, 45);
    doc.text(`Date du rapport : ${dateStr}`, 130, 45);
    
    // Resume
    doc.setFont("helvetica", "bold");
    doc.setFontSize(14);
    doc.text("RÉSULTAT GLOBAL", 20, 60);
    doc.setFont("helvetica", "normal");
    doc.setFontSize(12);
    doc.text(`Score : ${this.score.score} / 850`, 20, 70);
    doc.text(`Niveau de risque : ${this.score.risk_level.toUpperCase()}`, 20, 80);
    if (this.score?.capacite_emprunt) { doc.text(`Droit d'emprunt : ${this.score.capacite_emprunt?.toFixed(0).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} FCFA (Estimé)`, 20, 90); } else { doc.text(`Droit d'emprunt : N/A`, 20, 90); }
    
    doc.setFont("helvetica", "bold");
    doc.setFontSize(14);
    doc.text("MÉTRIQUES DÉTAILLÉES", 20, 110);
    doc.setFont("helvetica", "normal");
    doc.setFontSize(12);
    doc.text(`Revenu moyen :`, 20, 120); doc.text(`${this.revenuMoyen}`, 80, 120);
    doc.text(`Régularité :`, 20, 130); doc.text(`${this.regularityPercent}%`, 80, 130);
    doc.text(`Ratio d'épargne :`, 20, 140); doc.text(`${this.savingRatio}`, 80, 140);
    doc.text(`Fréquence :`, 20, 150); doc.text(`${this.transactionFrequency}`, 80, 150);

    doc.line(20, 170, 190, 170);
    doc.setFontSize(10);
    doc.setFont("helvetica", "italic");
    doc.text("CEquality - Analysé localement et en toute sécurité", 105, 180, { align: "center" });

    doc.save(`rapport_score_cequility_${this.userId}.pdf`);
  }
}
