import 'package:tune/domain/models/source_scan_result.dart';

/// One scan outcome kept for the stability dimension.
class SourceScanHealthRecord {
  final SourceScanStatus status;
  final int songCount;
  final Duration elapsed;
  final DateTime at;

  const SourceScanHealthRecord({
    required this.status,
    required this.songCount,
    required this.elapsed,
    required this.at,
  });

  factory SourceScanHealthRecord.fromResult(SourceScanResult result) {
    return SourceScanHealthRecord(
      status: result.status,
      songCount: result.songCount,
      elapsed: result.elapsed,
      at: result.scannedAt,
    );
  }

  factory SourceScanHealthRecord.fromJson(Map<String, dynamic> json) {
    final status = SourceScanStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => SourceScanStatus.failed,
    );
    final at = json['at'];
    return SourceScanHealthRecord(
      status: status,
      songCount: (json['songCount'] is num)
          ? (json['songCount'] as num).toInt()
          : 0,
      elapsed: Duration(
        milliseconds: (json['elapsedMs'] is num)
            ? (json['elapsedMs'] as num).toInt()
            : 0,
      ),
      at: at is num
          ? DateTime.fromMillisecondsSinceEpoch(at.toInt())
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'songCount': songCount,
    'elapsedMs': elapsed.inMilliseconds,
    'at': at.millisecondsSinceEpoch,
  };
}

/// The recent scan outcomes of one source, newest last.
class SourceScanHealthHistory {
  final List<SourceScanHealthRecord> records;

  const SourceScanHealthHistory({this.records = const []});

  SourceScanHealthHistory append(
    SourceScanHealthRecord record, {
    int keep = 5,
  }) {
    final next = [...records, record];
    if (next.length > keep) next.removeRange(0, next.length - keep);
    return SourceScanHealthHistory(records: List.unmodifiable(next));
  }

  /// A 0..1 stability rate: success is full, skipped is mostly stable,
  /// failure is not. No history is neutral.
  double get stabilityRate {
    if (records.isEmpty) return 0.5;
    var sum = 0.0;
    for (final record in records) {
      sum += switch (record.status) {
        SourceScanStatus.success => 1.0,
        SourceScanStatus.skipped => 0.75,
        SourceScanStatus.failed => 0.0,
        SourceScanStatus.needsConfiguration => 0.0,
      };
    }
    return sum / records.length;
  }

  factory SourceScanHealthHistory.fromJson(List<dynamic> json) {
    return SourceScanHealthHistory(
      records: List.unmodifiable(
        json.whereType<Map>().map(
          (item) =>
              SourceScanHealthRecord.fromJson(Map<String, dynamic>.from(item)),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> toJson() => [
    for (final record in records) record.toJson(),
  ];
}
