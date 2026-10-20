import 'package:flutter/material.dart';

/// How a fact is painted on screen.
///
/// The tone tells the reader what kind of fact this is without reading it: a
/// failure is red, a live stream is green, everything else stays quiet.
enum FactTone { neutral, primary, secondary, tertiary, error }

/// One piece of information about a track.
///
/// The fact carries the label that names it, the value that says what it is
/// and the icon that lets a reader recognise it at a glance.
///
/// The same fact is read in three ways: a list row shows the icon alone, the
/// now playing page shows the icon with the value, and the details sheet
/// shows the icon with the name and the value.
class TrackFact {
  final String label;
  final String value;
  final IconData icon;
  final FactTone tone;

  /// Whether the fact is worth a place in a list row.
  final bool compact;

  /// Whether the value was written by a machine.
  ///
  /// A number, a path, an identifier and a format name come out of a file or
  /// out of a source; an album, a style and a description come out of a
  /// person. The details panel writes the two kinds in two faces: the
  /// machine face for the first and the body face for the second, so the
  /// reader sees at once which words a machine wrote.
  final bool machine;

  /// Whether the value is a text too long for a row.
  ///
  /// A description is a paragraph, so the details panel writes it out under
  /// its own name instead of putting it in a line of the table.
  final bool paragraph;

  final String? _sentence;

  const TrackFact({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = FactTone.neutral,
    this.compact = false,
    this.machine = false,
    this.paragraph = false,
    String? sentence,
  }) : _sentence = sentence;

  /// The words of the fact, for a tooltip.
  ///
  /// A state that repeats its own name, such as a favourite that is already a
  /// favourite, says it once.
  String get sentence => _sentence ?? '$label · $value';
}
