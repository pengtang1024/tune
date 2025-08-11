/// 本地化状态基类
///
/// 所有本地化相关的状态都应该继承此类。
abstract class LocalizationState {}

/// 初始本地化状态
///
/// Bloc的初始状态。
class LocalizationInitial extends LocalizationState {}

/// 本地化更改状态
///
/// 当本地化发生更改时的状态。
class LocalizationChangedState extends LocalizationState {
  /// 当前的语言代码
  final String locale;

  /// 创建本地化更改状态
  ///
  /// [locale] 当前的语言代码
  LocalizationChangedState(this.locale);
}