import 'package:dbus/dbus.dart';

/// A method in the description of an interface.
///
/// The arguments are given as pairs of a signature and a name, so the
/// description of an interface stays readable.
DBusIntrospectMethod dbusMethod(
  String name, {
  List<(String, String)> inArgs = const [],
  List<(String, String)> outArgs = const [],
}) {
  return DBusIntrospectMethod(
    name,
    args: [
      ...inArgs.map(
        (argument) => DBusIntrospectArgument(
          DBusSignature(argument.$1),
          DBusArgumentDirection.in_,
          name: argument.$2,
        ),
      ),
      ...outArgs.map(
        (argument) => DBusIntrospectArgument(
          DBusSignature(argument.$1),
          DBusArgumentDirection.out,
          name: argument.$2,
        ),
      ),
    ],
  );
}

/// A property in the description of an interface.
DBusIntrospectProperty dbusProperty(
  String name,
  String signature, {
  bool writable = false,
}) {
  return DBusIntrospectProperty(
    name,
    DBusSignature(signature),
    access: writable ? DBusPropertyAccess.readwrite : DBusPropertyAccess.read,
  );
}

/// A signal in the description of an interface.
DBusIntrospectSignal dbusSignal(String name) => DBusIntrospectSignal(name);
