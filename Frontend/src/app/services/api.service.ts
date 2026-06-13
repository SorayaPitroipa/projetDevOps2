import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface UploadResponse {
  filename: string;
  user_id: string;
  profile: string;
  transaction_count: number;
  score: number;
  transactions: any[];
  features: Record<string, number>;
}

export interface ScoreResult {
  user_id: string;
  score: number;
  risk_level: string;
  profile: string;
  revenu_moyen_mensuel: number;
  regularite_revenus: number;
  ratio_epargne: number;
  freq_transactions_mois: number;
}

@Injectable({
  providedIn: 'root'
})
export class ApiService {
  private readonly baseUrl = '/api/v1';
  private readonly apiKey = 'changeme';

  constructor(private http: HttpClient) {}

  uploadStatement(file: File): Observable<UploadResponse> {
    const formData = new FormData();
    formData.append('file', file);
    const headers = new HttpHeaders({ 'X-API-Key': this.apiKey });
    return this.http.post<UploadResponse>(`${this.baseUrl}/upload-statement`, formData, { headers });
  }

  getScore(userId: string): Observable<ScoreResult> {
    const headers = new HttpHeaders({ 'X-API-Key': this.apiKey });
    return this.http.get<ScoreResult>(`${this.baseUrl}/score/${userId}`, { headers });
  }
}
