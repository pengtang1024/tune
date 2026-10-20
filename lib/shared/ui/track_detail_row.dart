import 'package:flutter/material.dart';
import 'package:tune/shared/ui/track_fact.dart';

/// One line of the details of a track.
///
/// A line names a thing on the left and says what that thing is on the right.
/// The details panel keeps every name in one column, so the values stand in
/// a single stripe and the eye can run down the names to find one.
class TrackDetailRow {
  /// The name of the thing, such as the format of a track.
  final String label;

  /// The icon that lets a reader recognise the thing at a glance.
  final IconData icon;

  /// What the thing is.
  final String value;

  /// The colour of the icon, which tells the reader what kind of thing it
  /// is without reading the name.
  final FactTone tone;

  /// Whether the value was written by a machine.
  ///
  /// A path, an address, a number and an identifier are written in the
  /// machine face; the words of a person are written in the body face.
  final bool machine;

  /// The name of the button that takes the value away, when the value can be
  /// taken away.
  final String? copyHint;

  const TrackDetailRow({
    required this.label,
    required this.icon,
    required this.value,
    this.tone = FactTone.neutral,
    this.machine = false,
    this.copyHint,
  });
}
