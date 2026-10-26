import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/app/licenses.dart';

void main() {
  test('third-party notices cover fonts and the system player', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    LicenseRegistry.reset();
    registerThirdPartyLicenses();

    final entries = await LicenseRegistry.licenses.toList();
    final entry = entries.firstWhere(
      (entry) => entry.packages.contains('Tune third-party notices'),
    );
    final text = entry.paragraphs.map((paragraph) => paragraph.text).join('\n');

    expect(text, contains('SIL Open Font License'));
    expect(text, contains('Fraunces'));
    expect(text, contains('libmpv'));
    expect(text, contains('MIT'));
  });
}
