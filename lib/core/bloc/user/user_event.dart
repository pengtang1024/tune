abstract class UserEvent {}

class AppStarted extends UserEvent {}

class LoginRequested extends UserEvent {
  final String email;
  final String password;

  LoginRequested(this.email, this.password);
}

class GoogleLoginRequested extends UserEvent {}

class FacebookLoginRequested extends UserEvent {}

class AppleLoginRequested extends UserEvent {}

class LogoutRequested extends UserEvent {}