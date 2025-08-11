import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/bloc/user/user_event.dart';
import 'package:tune/core/bloc/user/user_state.dart';
import 'package:tune/core/services/user_session_service.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(UserInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<GoogleLoginRequested>(_onGoogleLoginRequested);
    on<FacebookLoginRequested>(_onFacebookLoginRequested);
    on<AppleLoginRequested>(_onAppleLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  void _onAppStarted(AppStarted event, Emitter<UserState> emit) async {
    emit(UserLoading());
    final userId = UserSessionService.getUserId();
    if (userId != null) {
      // 在实际应用中，这里应该从API获取用户信息
      emit(UserAuthenticated(
        userId: userId,
        username: 'User',
        email: 'user@example.com',
      ));
    } else {
      emit(UserUnauthenticated());
    }
  }

  void _onLoginRequested(
      LoginRequested event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      // 在实际应用中，这里应该调用API进行登录
      // 模拟登录成功
      await UserSessionService.setUserId('12345');
      emit(UserAuthenticated(
        userId: '12345',
        username: 'User',
        email: event.email,
      ));
    } catch (e) {
      emit(UserError('Login failed'));
    }
  }

  void _onGoogleLoginRequested(
      GoogleLoginRequested event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      // 在实际应用中，这里应该调用Google登录API
      // 模拟登录成功
      await UserSessionService.setUserId('google_12345');
      emit(UserAuthenticated(
        userId: 'google_12345',
        username: 'Google User',
        email: 'googleuser@example.com',
      ));
    } catch (e) {
      emit(UserError('Google login failed'));
    }
  }

  void _onFacebookLoginRequested(
      FacebookLoginRequested event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      // 在实际应用中，这里应该调用Facebook登录API
      // 模拟登录成功
      await UserSessionService.setUserId('facebook_12345');
      emit(UserAuthenticated(
        userId: 'facebook_12345',
        username: 'Facebook User',
        email: 'fbuser@example.com',
      ));
    } catch (e) {
      emit(UserError('Facebook login failed'));
    }
  }

  void _onAppleLoginRequested(
      AppleLoginRequested event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      // 在实际应用中，这里应该调用Apple登录API
      // 模拟登录成功
      await UserSessionService.setUserId('apple_12345');
      emit(UserAuthenticated(
        userId: 'apple_12345',
        username: 'Apple User',
        email: 'appleuser@example.com',
      ));
    } catch (e) {
      emit(UserError('Apple login failed'));
    }
  }

  void _onLogoutRequested(
      LogoutRequested event, Emitter<UserState> emit) async {
    await UserSessionService.clearUserId();
    await UserSessionService.clearUserToken();
    emit(UserUnauthenticated());
  }
}