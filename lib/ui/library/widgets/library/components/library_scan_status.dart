import 'package:flutter/material.dart';
import 'package:tune/ui/library/states/library_state.dart';

class LibraryScanStatus extends StatelessWidget {
  final LibraryState state;

  const LibraryScanStatus({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.scanStatus == ScanStatus.idle ||
        state.scanStatus == ScanStatus.completed) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
          color: state.scanStatus == ScanStatus.error
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0)),
      child: Row(
        children: [
          if (state.scanStatus == ScanStatus.scanning) ...[
            const CircularProgressIndicator(),
            const SizedBox(width: 12)
          ] else if (state.scanStatus == ScanStatus.error) ...[
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 12)
          ],
          Expanded(
            child: Text(state.statusMessage,
                style: TextStyle(
                    color: state.scanStatus == ScanStatus.error
                        ? Colors.red
                        : Theme.of(context).textTheme.bodyMedium?.color)),
          ),
        ],
      ),
    );
  }
}