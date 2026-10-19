import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/impl/shared_preferences_service.dart';
import 'package:tune/data/services/persistence_service.dart';

final sharedPreferencesServiceProvider = Provider<PersistenceService>((ref) {
  return SharedPreferencesService();
});
