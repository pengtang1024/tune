import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tune/data/services/impl/preference_store.dart';
import 'package:tune/data/services/impl/saf_document_writer.dart';
import 'package:tune/data/services/impl/saf_method_channel.dart';
import 'package:tune/data/services/impl/system_library_row.dart';
import 'package:tune/data/services/library/saf_tree_store.dart';
import 'package:tune/data/services/persistence_service.dart';

/// The write door of the sheet, on the device.
///
/// A unit test answers the platform channel with a mock; this one lets the
/// real `DocumentsContract` of the phone write into the tree the reader
/// picked, which is the only place the landing can be seen. Run it on the
/// emulator after a folder was picked in the app:
///
/// ```
/// flutter test integration_test/saf_sheet_write_test.dart -d emulator-5554
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the machine sheet lands in the picked tree', (tester) async {
    final PersistenceService persistence = createPersistenceService();
    await persistence.init();

    final tree = SafTreeStore(persistence).treeUri;
    expect(tree, isNotNull, reason: '先在应用里选择一个音乐库文件夹');

    final page = await const SafMethodChannel().listTreePage(
      tree!,
      offset: 0,
      limit: 1,
    );
    expect(page, isNotEmpty, reason: '选中的目录里要有可读的音频');
    final song = songOfSystemRow(page.first);
    expect(song, isNotNull);

    final writer = SafDocumentWriter(tree: SafTreeStore(persistence));
    expect(await writer.canWrite(song!), isTrue, reason: '目录要仍持有写权限');

    await writer.writeSmartLyrics(song, '[00:01.00] SAF 写入验证');
  });
}
