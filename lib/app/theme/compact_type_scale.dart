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
///
/// The scale has two ladders. The lower one is the sans text of the
/// interface and runs from [mark] to [heading] in steps of one pixel. The
/// upper one is the serif voice of the shell and starts a pixel above the
/// top of the lower one: [displaySmall] is a serif, and a serif next to a
/// sans of the same size reads as a different kind of text even when the two
/// numbers are equal. A page that needs a big heading asks the display
/// ladder for it.
///
/// The lower ladder starts at eleven pixels, and that is a floor and not a
/// preference. The app is a Chinese one, and a Chinese glyph packs a dozen
/// strokes into the space of a letter: below eleven pixels the strokes of
/// one character fall on top of each other and the character turns into a
/// blot. The shell used to write its eyebrows, its pills and its counts at
/// eight and nine pixels, and on a screen that is not scaled up there was
/// nothing left to read.
abstract final class CompactTypeScale {
  /// The size of a mark and of a small number.
  ///
  /// A mark is not read as a sentence: the eyebrow of a page, the label of
  /// a pill, the number of a section, a timestamp, a count. It is set in
  /// the mono face with wide letter spacing, so it stays a mark next to the
  /// text around it.
  ///
  /// This is the floor of the scale. Anything that carries Chinese has to
  /// be at least this big.
  static const double mark = 11;

  /// The label of a control and the other secondary descriptions.
  ///
  /// The size of the text of a filter, of a count next to a title and of a
  /// note under a field.
  static const double label = 12;

  /// The text of an input, of a list entry and of a paragraph.
  ///
  /// The size most of the text of the shell uses. It is the body of a card
  /// and the title of a track in a list.
  static const double body = 13;

  /// The title of a track, of a card and of a button.
  ///
  /// The step where the text carries weight. It is the title of the track
  /// that plays and the label of the button that starts the scan.
  static const double strong = 14;

  /// The title of a group of content.
  ///
  /// A step above [strong], used where a group of rows needs a name of its
  /// own.
  static const double title = 15;

  /// A heading that has to stand out from the body around it.
  ///
  /// The title of a sheet and of a dialog.
  static const double heading = 16;

  /// The size of a heading in the display face.
  ///
  /// The display face is the big serif voice of the shell: it writes the
  /// title of a page, the name of the app and the title of the track that
  /// plays now. It sits above the scale of the interface text, so the
  /// smallest step of it is already a pixel above the biggest sans.
  static const double displaySmall = 17;
  static const double displayMedium = 24;
  static const double displayLarge = 38;
}
