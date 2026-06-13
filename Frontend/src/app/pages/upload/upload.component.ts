import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { HttpErrorResponse } from '@angular/common/http';
import { ApiService, UploadResponse } from '../../services/api.service';

@Component({
  selector: 'app-upload',
  templateUrl: './upload.component.html',
  styleUrls: ['./upload.component.css']
})
export class UploadComponent {
  selectedFile: File | null = null;
  dragActive = false;
  uploading = false;
  result: UploadResponse | null = null;
  errorMessage = '';
  successMessage = '';
  analysisReady = false;

  constructor(private apiService: ApiService, private router: Router) {}

  onFileSelected(event: Event): void {
    const element = event.target as HTMLInputElement;
    if (element.files?.length) {
      this.selectedFile = element.files[0];
      this.errorMessage = '';
      this.successMessage = '';
      this.result = null;
      this.analysisReady = true;
    }
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    this.dragActive = true;
  }

  onDragLeave(event: DragEvent): void {
    event.preventDefault();
    this.dragActive = false;
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    this.dragActive = false;

    if (event.dataTransfer?.files.length) {
      this.selectedFile = event.dataTransfer.files[0];
      this.errorMessage = '';
      this.successMessage = '';
      this.result = null;
      this.analysisReady = true;
    }
  }

  uploadStatement(): void {
    if (!this.selectedFile) {
      this.errorMessage = 'Veuillez sélectionner un fichier PDF.';
      return;
    }

    if (this.selectedFile.type !== 'application/pdf') {
      this.errorMessage = 'Seuls les fichiers PDF sont acceptés.';
      return;
    }

    this.uploading = true;
    this.errorMessage = '';
    this.result = null;

    this.apiService.uploadStatement(this.selectedFile).subscribe({
      next: response => {
        this.uploading = false;
        this.result = response;
        this.successMessage = `Analyse terminée : score ${response.score}`;
        this.analysisReady = false;
        this.router.navigate(['/score', response.user_id]);
      },
      error: (error: HttpErrorResponse) => {
        this.uploading = false;
        this.successMessage = '';
        if (error.error?.detail) {
          this.errorMessage = error.error.detail;
        } else if (error.status === 0) {
          this.errorMessage = 'Impossible de contacter le backend. Vérifiez que le serveur est démarré.';
        } else if (error.status === 403) {
          this.errorMessage = 'Clé API invalide. Vérifiez la configuration.';
        } else {
          this.errorMessage = 'Impossible de téléverser le fichier. Vérifiez le backend et la clé API.';
        }
      }
    });
  }
}
