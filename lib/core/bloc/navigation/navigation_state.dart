import 'package:equatable/equatable.dart';

/// 导航状态基类
abstract class NavigationState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 初始导航状态
class NavigationInitial extends NavigationState {}

/// 导航更改状态
class NavigationChangedState extends NavigationState {
  /// 当前选中的导航索引
  final int currentIndex;

  NavigationChangedState(this.currentIndex);

  @override
  List<Object?> get props => [currentIndex];
}