import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object> get props => [];
}

class AppStarted extends UserEvent {}

class LoginRequested extends UserEvent {
  final String email;
  final String password;

  const LoginRequested(this.email, this.password);

  @override
  List<Object> get props => [email, password];
}

class GoogleLoginRequested extends UserEvent {}

class FacebookLoginRequested extends UserEvent {}

class AppleLoginRequested extends UserEvent {}

class LogoutRequested extends UserEvent {}