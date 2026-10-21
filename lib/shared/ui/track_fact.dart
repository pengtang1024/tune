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
/// shows the icon with the value as well, the name of the fact waiting in
/// the tooltip.
class TrackFact {
  final String label;
  final String value;
  final IconData icon;
  final FactTone tone;

  /// The second half of the content, when the fact has one.
  ///
  /// A source says two things: the name it calls itself and the name the
  /// app knows it by. The first is the main, the second is the extra, so the
  /// chip shows the main and the extra waits in the tooltip.
  final String? secondary;

  /// Whether the fact is worth a place in a list row.
  final bool compact;

  /// Whether the value is a text too long for a chip.
  ///
  /// A description is a paragraph, so the details panel writes it out under
  /// its own name instead of putting it in a chip.
  final bool paragraph;

  final String? _sentence;

  const TrackFact({
    required this.label,
    required this.value,
    required this.icon,
    this.tone = FactTone.neutral,
    this.secondary,
    this.compact = false,
    this.paragraph = false,
    String? sentence,
  }) : _sentence = sentence;

  /// The words of the fact, for a tooltip.
  ///
  /// A state that repeats its own name, such as a favourite that is already a
  /// favourite, says it once. The second half of the content waits here too.
  String get sentence {
    final base = _sentence ?? '$label · $value';
    final tail = secondary;
    return tail == null ? base : '$base · $tail';
  }

  /// The words the chip itself carries, when it carries any.
  ///
  /// A fact with one piece of content keeps it in the tooltip: the icon
  /// already says which fact it is, and a chip that writes its words grows
  /// with them. A fact with a main and a second half shows its main, because
  /// the main is the name of the thing itself.
  String? get chipValue => secondary == null ? null : value;
}
