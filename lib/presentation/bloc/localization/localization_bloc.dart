import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/presentation/bloc/localization/localization_event.dart';
import 'package:tune/presentation/bloc/localization/localization_state.dart';

/// 本地化Bloc类
/// 
/// 负责管理应用程序的本地化状态，处理语言更改事件，
/// 并将语言设置持久化到本地存储中。
class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  /// 本地存储键名
  static const String _selectedLocaleKey = 'selected_locale';
  
  /// SharedPreferences实例
  late SharedPreferences _prefs;

  /// 创建本地化Bloc实例
  /// 
  /// 初始化Bloc，设置初始状态为LocalizationInitial，并注册事件处理器。
  LocalizationBloc() : super(LocalizationInitial()) {
    // 注册语言更改事件的处理器
    on<LanguageChangedEvent>(_onLanguageChanged);
    
    // 初始化时读取已保存的语言设置
    _initLocalization();
  }
  
  /// 初始化本地化设置
  /// 
  /// 从本地存储中读取已保存的语言代码，并发出初始本地化状态。
  Future<void> _initLocalization() async {
    _prefs = await SharedPreferences.getInstance();
    
    // 从本地存储中读取语言代码
    final locale = _prefs.getString(_selectedLocaleKey) ?? 'en';
    
    // 使用add来触发事件，而不是直接emit状态
    add(LanguageChangedEvent(locale));
  }

  /// 处理语言更改事件
  /// 
  /// 当用户在设置页面更改语言时，会触发此事件处理器。
  /// 它会将新的语言设置保存到本地存储，并发出新的本地化状态。
  /// 
  /// [event] 语言更改事件，包含新的语言代码
  /// [emit] 状态发射器，用于发出新的状态
  Future<void> _onLanguageChanged(LanguageChangedEvent event, Emitter<LocalizationState> emit) async {
    // 保存语言代码到共享偏好设置，实现语言设置的持久化
    await _prefs.setString(_selectedLocaleKey, event.locale);
    
    // 发出新的本地化状态，通知UI更新
    emit(LocalizationChangedState(event.locale));
  }
}