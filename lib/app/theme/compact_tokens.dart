import 'package:flutter/material.dart';

/// Small, explicit token set for the compact desktop shell.
///
/// The legacy [AppDesignSystem] remains available for the old UI while it is
/// being removed. New code should depend on this file and on [Theme.of] instead
/// of reaching into the legacy token surface.
abstract final class CompactTokens {
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space10 = 10;
  static const double space12 = 12;
  static const double space14 = 14;
  static const double space16 = 16;
  static const double space18 = 18;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;

  static const double radius4 = 4;
  static const double radius6 = 6;
  static const double radius8 = 8;
  static const double radius10 = 10;
  static const double radius12 = 12;

  /// Size of the icon of a mark, next to a label of the mark family.
  static const double icon12 = 12;

  /// Size of the icon of a control.
  ///
  /// The ladder runs in steps of two pixels, so an icon next to a label of
  /// the body size is one step above it and an icon of a big button is two
  /// steps above that.
  static const double icon14 = 14;
  static const double icon16 = 16;
  static const double icon18 = 18;
  static const double icon20 = 20;
  static const double icon24 = 24;
  static const double icon28 = 28;

  /// Side of the square a chip sits in.
  ///
  /// A chip is a mark and not a control: its height does not grow with the
  /// word next to it, so a row of chips keeps the same rhythm in every
  /// language. Its width follows the words of the fact, because the main of
  /// a fact is worth reading.
  static const double chipBox = 22;

  /// Size of the drawings that stand for a screen with nothing in it.
  ///
  /// They are pictures and not the icon of a control, so they are allowed a
  /// size of their own.
  static const double illustrationSmall = 32;
  static const double illustration = 36;
  static const double illustrationLarge = 44;

  static const double headerHeight = 44;
  static const double tabsHeight = 44;
  static const double rowHeight = 52;

  /// Height of the controls of the shell.
  ///
  /// The shell keeps its buttons dense, so the ladder runs in steps of two
  /// pixels up to the default and then jumps to the roomy ones.
  ///
  /// The three kinds of button share [controlDefault]: they stand next to
  /// each other, and a row that is one step taller on one side reads as a
  /// mistake.
  static const double controlTiny = 28;
  static const double controlCompact = 30;
  static const double controlSmall = 32;
  static const double controlDefault = 34;
  static const double controlMedium = 40;
  static const double controlLarge = 56;
  static const double inputHeight = 36;

  static const double playerPaneMinWidth = 312;
  static const double playerPaneMaxWidth = 360;

  /// Gutter between the edge of the content pane and the page content.
  ///
  /// Every page of the shell uses this gutter, so the heading, the toolbar
  /// and the list below it share one left edge and one right edge.
  static const double pageGutter = 24;

  /// Space above the heading of a page.
  static const double pageTopPadding = 24;

  /// Space below the heading of a page, before the toolbar or the list.
  static const double pageHeadingGap = 16;

  /// Width of the navigation rail, and of its narrow form.
  static const double sidebarWidth = 196;
  static const double sidebarWidthCompact = 76;

  /// Width below which the navigation rail drops its labels.
  ///
  /// The minimum window is 760 wide, so the threshold has to sit above it:
  /// a narrow form that the window cannot reach is a form nobody sees.
  static const double sidebarCompactBreakpoint = 800;

  /// Inner padding of the navigation rail.
  static const double sidebarPadding = 20;

  /// Height of one entry of the navigation rail.
  static const double navItemHeight = 40;

  /// Height of the player dock and the space it keeps from the window edge.
  static const double dockHeight = 88;
  static const double dockMargin = 16;
  static const double dockPadding = 14;
  static const double dockRadius = 18;

  /// Width of the side panel that floats over the content area.
  ///
  /// A panel keeps a readable measure instead of following the page: it grows
  /// to [sidePanelWidthMax] and no further. It also leaves the page a strip of
  /// at least [sidePanelContentReserve] pixels, so the panel reads as a side
  /// panel rather than a page that lost its heading. A very narrow window
  /// clamps the panel to the room it has, gutters included.
  static const double sidePanelWidthMin = 360;
  static const double sidePanelWidthMax = 440;
  static const double sidePanelContentReserve = 160;

  /// Space between the edge of the content area and the floating panel.
  static const double sidePanelGutter = 12;

  /// Radius of the floating panel, shared with the player dock.
  static const double sidePanelRadius = dockRadius;

  /// Width of the transport column of the dock, and of its narrow form.
  ///
  /// The column holds the buttons and the seek bar, and it sits between two
  /// sides of the same width, so the transport lands on the centre of the
  /// dock.
  static const double dockTransportWidth = 280;
  static const double dockTransportWidthNarrow = 210;

  /// Artwork of the track that plays right now in the dock.
  static const double artworkDock = 54;

  /// Size of the button that switches the mode of the playback.
  static const double modeButtonSize = 26;

  /// Artwork of a track inside a list.
  static const double artworkRow = 36;

  /// Artwork of a track that a sheet shows on its own.
  static const double artworkHero = 56;

  /// Height of a row of a track list.
  ///
  /// The library and the queue show the same track the same way, so both
  /// rows are this tall and their columns line up with each other. The row
  /// is kept tight: a reader looking for a track scans a column of names,
  /// and every pixel a row does not use is a track that is out of sight.
  static const double listRowHeight = 48;

  /// Space above and below the artwork of a row of a track list.
  ///
  /// The row is [listRowHeight] tall and the artwork is [artworkRow], so
  /// the room around the artwork is what is left of the row.
  static const double listRowPadding = (listRowHeight - artworkRow) / 2;

  /// Height of a row of the library table.
  ///
  /// The library is where a reader looks for one track among hundreds, so
  /// it is a table and not a stack of cards: one line per track, and the
  /// columns carry the artist, the album and the facts beside the title.
  /// The row is shorter than [listRowHeight] because a table row says
  /// everything it has to say in one line.
  static const double libraryRowHeight = 32;

  /// Artwork of a track in the library table.
  static const double libraryArtwork = 24;

  /// Space above and below the artwork of a row of the library table.
  static const double libraryRowPadding =
      (libraryRowHeight - libraryArtwork) / 2;

  /// Size of the action of a library row.
  ///
  /// The heart, the details and the queue action sit in a row that is
  /// [libraryRowHeight] tall, so they are one step smaller than the action
  /// of a full page row.
  static const double libraryRowAction = 24;

  /// Width of the column that carries the position of a track.
  static const double positionColumnWidth = 22;

  /// Artwork of the track that plays right now.
  static const double artworkNowPlaying = 380;

  /// Width of the text column of the track that plays right now.
  static const double nowPlayingInfoWidth = 480;

  /// Space between the artwork and the text of the track that plays now.
  static const double nowPlayingGap = 48;

  /// Width of a bottom sheet.
  ///
  /// Material caps a bottom sheet at the same width, so asking for more
  /// would only hide the request.
  static const double sheetWidth = 640;

  /// The room a sheet keeps above it.
  ///
  /// A sheet that reaches the top of the window leaves the reader no way to
  /// close it with the mouse, because the barrier behind it is covered. Every
  /// sheet keeps this much room above it, so there is always a place to tap.
  static const double sheetBarrierGap = 64;

  /// Radius of the top corners of a bottom sheet.
  static const double sheetRadius = 20;

  /// Longest width of the search field of the library.
  ///
  /// A field that follows the whole width of the page turns into a thin
  /// ribbon; the cap keeps it a box a reader can aim at, and the actions of
  /// the row keep the far end of the page.
  static const double searchFieldMaxWidth = 680;

  /// Size of the ring that says the app is busy, and of its stroke.
  ///
  /// The Material indicator draws its stroke centred on the path, so half of
  /// the stroke falls outside of the box and is cut away: the ring is thick
  /// on the diagonals and thin at the top, the bottom and the sides, and it
  /// reads as a rough polygon. The ring of the shell is drawn inside its box
  /// instead, and the stroke stays a tenth of the diameter so that even the
  /// small rings of the buttons still read as a circle.
  static const double spinnerSmall = 16;
  static const double spinnerMedium = 20;
  static const double spinnerLarge = 36;
  static const double spinnerStrokeSmall = 2;
  static const double spinnerStrokeMedium = 2.5;
  static const double spinnerStrokeLarge = 3;

  static const EdgeInsets pagePadding = EdgeInsets.all(space16);
  static const EdgeInsets pagePaddingCompact = EdgeInsets.all(space12);

  static const BorderRadius borderRadius6 = BorderRadius.all(
    Radius.circular(radius6),
  );
  static const BorderRadius borderRadius8 = BorderRadius.all(
    Radius.circular(radius8),
  );
  static const BorderRadius borderRadius12 = BorderRadius.all(
    Radius.circular(radius12),
  );

  static const Duration fastMotion = Duration(milliseconds: 120);
  static const Duration standardMotion = Duration(milliseconds: 180);
}
