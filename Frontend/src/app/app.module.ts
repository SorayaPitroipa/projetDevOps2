import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpClientModule } from '@angular/common/http';

import { AppComponent } from './app.component';
import { AppRoutingModule } from './app-routing.module';
import { UploadComponent } from './pages/upload/upload.component';
import { ScoreComponent } from './pages/score/score.component';

@NgModule({
  declarations: [
    AppComponent,
    UploadComponent,
    ScoreComponent
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    AppRoutingModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }
