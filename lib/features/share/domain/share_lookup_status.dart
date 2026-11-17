/// 查重的可用状态。三态分开是因为「卡在哪」决定用户下一步做什么：没填 key 去填
/// key，缺 `fpcalc` 去装组件。
enum ShareLookupStatus {
  /// client key 与 `fpcalc` 都在，查重真的会跑。
  ready,

  /// 有 `fpcalc` 但没有 AcoustID 的 client key。
  missingKey,

  /// 有 key 但本机没有 `fpcalc`（也没装组件）。
  missingFpcalc;

  bool get canLookup => this == ShareLookupStatus.ready;
}
