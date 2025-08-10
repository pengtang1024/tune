import 'package:flutter/material.dart';
import 'package:tune/l10n/app_localizations.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.library_title),
      ),
      body: const Center(
        child: Text('Library Page - To be implemented'),
      ),
    );
  }
}