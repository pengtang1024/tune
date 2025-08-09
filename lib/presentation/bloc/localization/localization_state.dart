import 'package:equatable/equatable.dart';

/// 本地化状态基类
/// 
/// 所有本地化相关状态的基类，继承自Equatable以支持状态比较。
/// 通过实现props getter来定义状态的相等性比较。
class LocalizationState extends Equatable {
  /// 定义状态的相等性比较属性
  /// 
  /// 返回一个对象列表，用于比较状态是否相等。
  /// 空列表表示所有实例都相等。
  @override
  List<Object?> get props => [];
}

/// 初始本地化状态
/// 
/// 应用程序启动时的默认本地化状态。
class LocalizationInitial extends LocalizationState {}

/// 本地化已更改状态
/// 
/// 当用户更改语言设置后，Bloc会发出此状态以通知UI更新。
/// 该状态包含当前的语言代码。
class LocalizationChangedState extends LocalizationState {
  /// 当前的语言代码
  final String locale;

  /// 创建本地化已更改状态实例
  /// 
  /// [locale] 当前的语言代码
  LocalizationChangedState(this.locale);

  /// 定义状态的相等性比较属性
  /// 
  /// 包含locale，用于比较两个LocalizationChangedState是否相等。
  @override
  List<Object?> get props => [locale];
}