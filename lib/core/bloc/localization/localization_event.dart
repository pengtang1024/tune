/// 本地化事件基类
///
/// 所有本地化相关的事件都应该继承此类。
abstract class LocalizationEvent {}

/// 语言更改事件
///
/// 当用户选择新的语言时触发此事件。
class LanguageChangedEvent extends LocalizationEvent {
  /// 新的语言代码
  final String locale;

  /// 创建语言更改事件
  ///
  /// [locale] 新的语言代码
  LanguageChangedEvent(this.locale);
}