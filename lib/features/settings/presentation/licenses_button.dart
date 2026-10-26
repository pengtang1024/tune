import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';

/// Opens the in-app license page from the About card.
///
/// The page is kept in its own widget so the About card stays a layout-only
/// piece and the source guard that watches the chips does not read the label
/// as part of the version pill.
class LicensesButton extends StatelessWidget {
  final String version;

  const LicensesButton({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton.icon(
      onPressed: () => showLicensePage(
        context: context,
        applicationName: 'Tune',
        applicationVersion: 'v$version',
      ),
      icon: const Icon(Icons.description_outlined, size: CompactTokens.icon14),
      label: Text(MaterialLocalizations.of(context).viewLicensesButtonLabel),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: theme.colorScheme.primary,
      ),
    );
  }
}
