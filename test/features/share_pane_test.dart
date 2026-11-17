import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/share/presentation/share_entry_card.dart';
import 'package:tune/features/share/presentation/share_pane.dart';
import 'package:tune/l10n/app_localizations.dart';

Widget _app(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('没进房间时只给开房与加入两条路', (tester) async {
    await tester.pumpWidget(_app(const SharePane()));
    await tester.pumpAndSettle();

    expect(find.text('开一个房间'), findsWidgets);
    expect(find.text('用邀请码加入'), findsOneWidget);
    // 房间还没开，房间内的三块不该出现。
    expect(find.text('我要分享的'), findsNothing);
    expect(find.text('房间里的内容'), findsNothing);
    // 收件箱是常驻的：没有房间也能看已经收到的文件。
    expect(find.text('收件箱'), findsOneWidget);
  });

  testWidgets('音源页的入口卡能指到分享页', (tester) async {
    await tester.pumpWidget(_app(const ShareEntryCard()));
    await tester.pumpAndSettle();

    expect(find.text('局域网分享'), findsOneWidget);
    expect(find.text('分享'), findsOneWidget);
  });
}
