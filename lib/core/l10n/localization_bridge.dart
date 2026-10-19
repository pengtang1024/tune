import 'package:flutter/widgets.dart';
import 'package:tune/core/l10n/app_strings.dart';

/// Keeps [AppStrings] in sync with the locale the app renders in.
///
/// The widget sits below the `Localizations` scope of `MaterialApp`, so the
/// locale it reports is the one the user picked, including the fallback the
/// platform resolved.
class LocalizationBridge extends StatefulWidget {
  final Widget child;

  const LocalizationBridge({super.key, required this.child});

  @override
  State<LocalizationBridge> createState() => _LocalizationBridgeState();
}

class _LocalizationBridgeState extends State<LocalizationBridge> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppStrings.use(Localizations.localeOf(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
