import 'package:dbus/dbus.dart';
import 'package:tune/data/services/impl/dbus_introspection.dart';

/// The interface that describes the player itself.
const mprisPlayerInterface = 'org.mpris.MediaPlayer2';

/// The interface that carries the track and the transport.
const mprisTransportInterface = 'org.mpris.MediaPlayer2.Player';

/// The names of the arguments of the methods of the specification.
///
/// The names belong to the protocol of the media controls, so they are the
/// same in every language.
const _seekOffsetArgument = 'Offset';
const _setPositionTrackArgument = 'TrackId';
const _setPositionPositionArgument = 'Position';
const _openUriArgument = 'Uri';

/// The description of the two interfaces of the media controls.
///
/// The desktop reads the description to learn which methods and properties
/// the player offers.
List<DBusIntrospectInterface> mprisInterfaces() {
  return [
    DBusIntrospectInterface(
      mprisPlayerInterface,
      methods: [dbusMethod('Raise'), dbusMethod('Quit')],
      properties: [
        dbusProperty('Identity', 's'),
        dbusProperty('DesktopEntry', 's'),
      ],
    ),
    DBusIntrospectInterface(
      mprisTransportInterface,
      methods: [
        dbusMethod('Play'),
        dbusMethod('Pause'),
        dbusMethod('PlayPause'),
        dbusMethod('Stop'),
        dbusMethod('Next'),
        dbusMethod('Previous'),
        dbusMethod('Seek', inArgs: [('x', _seekOffsetArgument)]),
        dbusMethod(
          'SetPosition',
          inArgs: [
            ('o', _setPositionTrackArgument),
            ('x', _setPositionPositionArgument),
          ],
        ),
        dbusMethod('OpenUri', inArgs: [('s', _openUriArgument)]),
      ],
      properties: [
        dbusProperty('PlaybackStatus', 's'),
        dbusProperty('Metadata', 'a{sv}'),
        dbusProperty('Position', 'x'),
        dbusProperty('Volume', 'd', writable: true),
      ],
    ),
  ];
}
