import 'package:equatable/equatable.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserAuthenticated extends UserState {
  final String userId;
  final String username;
  final String email;

  const UserAuthenticated({
    required this.userId,
    required this.username,
    required this.email,
  });

  @override
  List<Object> get props => [userId, username, email];
}

class UserUnauthenticated extends UserState {}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object> get props => [message];
}