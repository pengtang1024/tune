import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/play_history_service.dart';

/// 播放历史服务提供者
final playHistoryServiceProvider = Provider<PlayHistoryService>((ref) {
  return PlayHistoryService();
});
