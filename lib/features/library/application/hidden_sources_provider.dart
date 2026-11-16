import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The sources the health gate keeps out of the library page.
///
/// The rule itself lives in [SourceVisibility]; this provider only says which
/// data it reads, so the page and its counts ask one question. It is empty by
/// default: a host that never wires the gate (tests, a fresh container) shows
/// every source, which is the behaviour before the gate existed.
final libraryHiddenSourcesProvider = Provider<Set<String>>((ref) => const {});
