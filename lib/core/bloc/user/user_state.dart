abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserAuthenticated extends UserState {
  final String userId;
  final String username;
  final String email;

  UserAuthenticated({
    required this.userId,
    required this.username,
    required this.email,
  });
}

class UserUnauthenticated extends UserState {}

class UserError extends UserState {
  final String message;

  UserError(this.message);
}