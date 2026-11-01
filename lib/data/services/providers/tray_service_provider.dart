import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/impl/tray/tray_service_io.dart';
import 'package:tune/data/services/tray/tray_service.dart';

/// The system tray of the desktop.
final trayServiceProvider = Provider<TrayService>((ref) {
  final service = TrayServiceImpl();
  ref.onDispose(() => service.destroy());
  return service;
});
