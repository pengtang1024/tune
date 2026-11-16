import 'package:flutter/widgets.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/content_kind.dart';

/// 列表当前条目的计数，单位跟着这一类内容走（首 / 集 / 章 / 条目）。
///
/// 宽窗口里这个数在工具栏，窄窗口里它在页头。两处各算一次的话，单位早晚
/// 会走样，所以只留这一份。
String libraryCountLabel(
  BuildContext context, {
  required int count,
  ContentKind? kind,
}) => switch (kind) {
  ContentKind.podcast => context.loc.libraryEpisodeCount(count),
  ContentKind.audiobook => context.loc.libraryChapterCount(count),
  ContentKind.radio => context.loc.libraryStationCount(count),
  ContentKind.soundEffect => context.loc.libraryEffectCount(count),
  _ => context.loc.libraryTrackCount(count),
};
