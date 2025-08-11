import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tune/core/bloc/navigation/navigation_event.dart';
import 'package:tune/core/bloc/navigation/navigation_state.dart';

/// 导航Bloc类
///
/// 负责管理应用程序的导航状态，处理导航更改事件
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  /// 创建导航Bloc实例
  ///
  /// 初始化Bloc，设置初始状态为NavigationInitial，并注册事件处理器。
  NavigationBloc() : super(NavigationInitial()) {
    // 注册导航更改事件的处理器
    on<NavigationChangedEvent>(_onNavigationChanged);
  }

  /// 处理导航更改事件
  ///
  /// 当用户在应用中导航时，会触发此事件处理器。
  ///
  /// [event] 导航更改事件，包含新的导航信息
  /// [emit] 状态发射器，用于发出新的状态
  Future<void> _onNavigationChanged(
      NavigationChangedEvent event, Emitter<NavigationState> emit) async {
    // 发出新的导航状态，包含新的导航信息
    emit(NavigationChangedState(event.currentIndex));
  }
}