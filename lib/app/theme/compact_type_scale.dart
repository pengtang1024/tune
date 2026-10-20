/// The sizes of the text of the compact shell.
///
/// The shell used to write a font size at every place that needed one, and
/// the sizes drifted apart: nine different values sat between 10 and 16
/// logical pixels, half a pixel away from each other. Two labels that meant
/// the same thing ended up a pixel apart, a track title was a third of a
/// pixel wider than the panel it sits in, and the smallest text was small
/// enough to be hard to read on a desk.
///
/// The scale below holds one size per role instead of one size per call
/// site. A role is picked by what the text does and not by where it sits, so
/// the same kind of text keeps the same size wherever it appears, and a new
/// page can only pick from the steps that already exist.
///
/// The scale is deliberately short. Every extra step is another half pixel
/// that the eye has to learn, and the shell puts a lot of text on screen at
/// once.
abstract final class CompactTypeScale {
  /// The size of a mark in a place that has little room for it.
  ///
  /// A mark is not read as a sentence. It is set in the mono face, in upper
  /// case and with wide letter spacing, so it can sit below the smallest
  /// size of the interface text without becoming noise.
  static const double markDense = 8;

  /// The size of a mark: the eyebrow of a page, the label of a pill.
  static const double mark = 9;

  /// Counts, timestamps and other text the machine wrote.
  ///
  /// The smallest readable size of the shell. It is only used for text that
  /// carries a number or a name that the user already knows.
  static const double micro = 10.5;

  /// The label of a control and the other secondary descriptions.
  ///
  /// One step above [micro], and the size of the text of a filter, of a count
  /// next to a title and of a note under a field.
  static const double label = 11.5;

  /// The text of an input, of a list entry and of a paragraph.
  ///
  /// The size most of the text of the shell uses. It is the body of a card
  /// and the title of a track in a list.
  static const double body = 12.5;

  /// The title of a track, of a card and of a button.
  ///
  /// The step where the text carries weight. It is the title of the track
  /// that plays and the label of the button that starts the scan.
  static const double strong = 13.5;

  /// The title of a group of content.
  ///
  /// A step above [strong], used where a group of rows needs a name of its
  /// own.
  static const double title = 15;

  /// A heading that has to stand out from the body around it.
  ///
  /// The title of a sheet and of a dialog.
  static const double heading = 16;
}
