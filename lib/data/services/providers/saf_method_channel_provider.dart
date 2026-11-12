import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/data/services/impl/saf_method_channel.dart';

/// The SAF channel of Android, provided so a page can ask for a library tree
/// without importing the platform implementation.
final safMethodChannelProvider = Provider<SafMethodChannel>(
  (ref) => const SafMethodChannel(),
);
