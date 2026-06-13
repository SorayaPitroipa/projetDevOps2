import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { SocialAuthService } from '@abacritt/angularx-social-login';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent implements OnInit {

  constructor(private router: Router, private authService: SocialAuthService) { }

  ngOnInit() {
    this.authService.authState.subscribe((user) => {
      console.log('Google user:', user);
      if (user) {
        localStorage.setItem('user', JSON.stringify(user));
        this.router.navigate(['/upload']);
      }
    });
  }

  onLogin(event: Event) {
    event.preventDefault();
    localStorage.setItem('user', JSON.stringify({ name: 'User Test', firstName: 'U', lastName: 'T' }));
    this.router.navigate(['/upload']);
  }
}
