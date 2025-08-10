import 'package:equatable/equatable.dart';

/// 本地化事件基类
/// 
/// 所有本地化相关事件的基类，继承自Equatable以支持状态比较。
/// 通过实现props getter来定义事件的相等性比较。
abstract class LocalizationEvent extends Equatable {
  /// 定义事件的相等性比较属性
  /// 
  /// 返回一个对象列表，用于比较事件是否相等。
  /// 空列表表示所有实例都相等。
  @override
  List<Object?> get props => [];
}

/// 语言更改事件
/// 
/// 当用户更改语言设置时触发的事件，包含新的语言代码。
/// 该事件会被LocalizationBloc处理以更新应用程序的语言。
class LanguageChangedEvent extends LocalizationEvent {
  /// 新的语言代码
  final String locale;

  /// 创建语言更改事件实例
  /// 
  /// [locale] 新的语言代码
  LanguageChangedEvent(this.locale);

  /// 定义事件的相等性比较属性
  /// 
  /// 包含locale，用于比较两个LanguageChangedEvent是否相等。
  @override
  List<Object?> get props => [locale];
}