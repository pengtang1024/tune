import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/features/library/presentation/library_view_mode.dart';

/// 页面第一次打开时用哪一档视图。
///
/// 为空表示「按内容分类的默认读法」（见 `library_layout.dart`）：音乐打开专辑墙，
/// 播客打开节目墙。读者自己点过开关之后，这一档就不再生效——那是他当下的选择。
///
/// 存在的理由只有一个：测试要断言平铺列表的行为时，得能直接落在列表上，
/// 而不是先模拟一次点击。
final libraryInitialViewProvider = Provider<LibraryViewMode?>((ref) => null);
