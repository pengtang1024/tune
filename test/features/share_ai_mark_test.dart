import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/share/application/share_session_controller.dart';
import 'package:tune/features/share/domain/share_ai_disclosure.dart';
import 'package:tune/features/share/domain/share_item.dart';
import 'package:tune/features/share/domain/share_provenance.dart';
import 'package:tune/features/share/domain/share_session_state.dart';
import 'package:tune/features/share/presentation/share_lists.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:tune/shared/ui/meta_badge.dart';

/// 标识只负责说清楚，不提供去除入口（《标识办法》第四条）。
///
/// 这三条钉住界面侧的口径：声明为生成合成的条目必须带 AI 标记，其它声明一律
/// 不带；标记点开只读地展示生成者与生成时间；行上除「撤销分享」外没有任何
/// 能抹掉标识的操作。
class _StubController extends ShareSessionController {
  @override
  Future<ShareSessionState> build() async => ShareSessionState.idle;
}

Finder findAiMark() => find.byWidgetPredicate(
  (widget) => widget is MetaBadge && widget.icon == Icons.auto_awesome,
);

ShareItem _item({
  required String contentId,
  required ShareProvenance provenance,
  String? providerName,
  String? modelId,
  DateTime? createdAt,
}) {
  return ShareItem(
    contentId: contentId,
    name: contentId.substring(0, 8),
    sizeBytes: 4096,
    provenance: provenance,
    createdAt: createdAt ?? DateTime.utc(2026, 11, 18, 3, 30),
    aiDisclosure: ShareAiDisclosure(
      isSynthetic: provenance == ShareProvenance.generated,
      providerName: providerName,
      contentNumber: provenance == ShareProvenance.generated ? contentId : null,
      // modelId 目前只作为 GENERATOR 写进文件元数据，界面上并入生成者一行。
      providerCode: modelId,
    ),
  );
}

Widget _app(List<ShareItem> items) {
  final state = ShareSessionState.idle.copyWith(localItems: items);
  return ProviderScope(
    overrides: [
      shareSessionProvider.overrideWith(() => _StubController()),
    ],
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ShareLocalItemsSection(state: state),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('声明为生成合成的条目在分享列表里带 AI 标识', (tester) async {
    await tester.pumpWidget(
      _app([
        _item(
          contentId: 'a' * 64,
          provenance: ShareProvenance.generated,
          providerName: 'MiniMax',
          modelId: 'music-2.6',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(findAiMark(), findsOneWidget);
  });

  testWidgets('非生成声明的条目不带 AI 标识', (tester) async {
    await tester.pumpWidget(
      _app([
        _item(contentId: 'b' * 64, provenance: ShareProvenance.ownRecording),
        _item(contentId: 'c' * 64, provenance: ShareProvenance.licensed),
      ]),
    );
    await tester.pumpAndSettle();

    expect(findAiMark(), findsNothing);
  });

  testWidgets('点 AI 标识只读地展示生成者与生成时间，且无去除入口', (tester) async {
    await tester.pumpWidget(
      _app([
        _item(
          contentId: 'd' * 64,
          provenance: ShareProvenance.generated,
          providerName: 'MiniMax',
          modelId: 'music-2.6',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(findAiMark());
    await tester.pumpAndSettle();

    expect(find.textContaining('生成者'), findsWidgets);
    expect(find.textContaining('生成时间'), findsOneWidget);
    expect(find.textContaining('MiniMax'), findsWidgets);
    // 标识是只读的：整个界面上没有任何去除标识的动作。
    expect(find.text('去除标识'), findsNothing);
    expect(find.text('清除标识'), findsNothing);
    expect(find.text('AI 生成'), findsWidgets);
  });
}
