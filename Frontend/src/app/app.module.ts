import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { HttpClientModule } from '@angular/common/http';
import { SocialLoginModule, SocialAuthServiceConfig, GoogleLoginProvider, GoogleSigninButtonModule } from '@abacritt/angularx-social-login';

import { AppComponent } from './app.component';
import { AppRoutingModule } from './app-routing.module';
import { UploadComponent } from './pages/upload/upload.component';
import { ScoreComponent } from './pages/score/score.component';
import { LoginComponent } from './pages/login/login.component';
import { environment } from '../environments/environment';

@NgModule({
  declarations: [
    AppComponent,
    UploadComponent,
    ScoreComponent,
    LoginComponent
  ],
  imports: [
    BrowserModule,
    HttpClientModule,
    AppRoutingModule,
    SocialLoginModule,
    GoogleSigninButtonModule
  ],
  providers: [
    {
      provide: 'SocialAuthServiceConfig',
      useValue: {
        autoLogin: false,
        providers: [
          {
            id: GoogleLoginProvider.PROVIDER_ID,
            provider: new GoogleLoginProvider(environment.googleClientId, {
              oneTapEnabled: false
            })
          }
        ],
        onError: (err) => {
          console.error(err);
        }
      } as SocialAuthServiceConfig,
    }
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
