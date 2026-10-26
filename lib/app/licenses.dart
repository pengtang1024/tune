import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers the notices that Flutter's generated `NOTICES` file does not
/// collect.
///
/// The Flutter tool collects each pub package's `LICENSE` and the root
/// `LICENSE` into `NOTICES`. The bundled fonts and the system libmpv notice
/// live outside that mechanism, so they are registered here and shown on the
/// in-app license page.
void registerThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    final notices = await rootBundle.loadString('THIRD_PARTY_NOTICES.md');
    yield LicenseEntryWithLineBreaks(const [
      'Tune third-party notices',
    ], notices);
  });
}
