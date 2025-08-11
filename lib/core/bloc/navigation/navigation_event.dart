import 'package:equatable/equatable.dart';

/// 导航事件基类
abstract class NavigationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 导航更改事件
class NavigationChangedEvent extends NavigationEvent {
  /// 当前选中的导航索引
  final int currentIndex;

  NavigationChangedEvent(this.currentIndex);

  @override
  List<Object?> get props => [currentIndex];
}