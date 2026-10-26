import 'package:tune/shared/ui/hint_trigger.dart';

export 'package:tune/shared/ui/hint_trigger.dart' show HintTrigger;

/// The one tooltip of the app.
///
/// Every hint that is not written into the interface goes through this
/// widget, so the reader meets the same paper and ink wherever the pointer
/// rests. The look itself lives in the theme, this widget only decides when
/// there is a hint at all.
///
/// A tooltip without a message is no tooltip: the widget stays as it is and
/// nothing appears on the pointer. A sidebar that already writes the name of
/// a page does not say it twice.
///
/// The widget is the trigger itself, not a wrapper around one: inside the
/// app there is one [HintLayer] above the navigator, and the trigger only
/// says which words belong to which rectangle. The layer owns the one card
/// and paints it in the overlay of the app, so a library row holds no
/// overlay of its own. A widget test that draws a tip without a layer falls
/// back to [RawTooltip], which keeps the standalone widget working.
///
/// The card is read where it is painted, inside the overlay, so a hint that
/// is open while the theme changes takes the new card at once.
typedef TuneTooltip = HintTrigger;
