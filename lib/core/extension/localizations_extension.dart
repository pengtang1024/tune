import 'package:flutter/cupertino.dart';
import 'package:tune/l10n/app_localizations.dart';

extension LocalizationExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this)!;
}
