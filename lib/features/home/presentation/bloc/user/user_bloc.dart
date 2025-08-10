import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/config/app_config.dart';
import 'package:tune/features/home/presentation/bloc/user/user_event.dart';
import 'package:tune/features/home/presentation/bloc/user/user_state.dart';

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
    final userId = AppConfig.getUserId();
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
      await AppConfig.setUserId('12345');
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
      // 在实际应用中，这里应该处理Google登录
      await AppConfig.setUserId('google_user_12345');
      emit(UserAuthenticated(
        userId: 'google_user_12345',
        username: 'Google User',
        email: 'google.user@example.com',
      ));
    } catch (e) {
      emit(UserError('Google login failed'));
    }
  }

  void _onFacebookLoginRequested(
      FacebookLoginRequested event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      // 在实际应用中，这里应该处理Facebook登录
      await AppConfig.setUserId('facebook_user_12345');
      emit(UserAuthenticated(
        userId: 'facebook_user_12345',
        username: 'Facebook User',
        email: 'facebook.user@example.com',
      ));
    } catch (e) {
      emit(UserError('Facebook login failed'));
    }
  }

  void _onAppleLoginRequested(
      AppleLoginRequested event, Emitter<UserState> emit) async {
    emit(UserLoading());
    try {
      // 在实际应用中，这里应该处理Apple登录
      await AppConfig.setUserId('apple_user_12345');
      emit(UserAuthenticated(
        userId: 'apple_user_12345',
        username: 'Apple User',
        email: 'apple.user@example.com',
      ));
    } catch (e) {
      emit(UserError('Apple login failed'));
    }
  }

  void _onLogoutRequested(LogoutRequested event, Emitter<UserState> emit) async {
    await AppConfig.clearUserId();
    emit(UserUnauthenticated());
  }
}
