import 'dart:convert';

/// The arguments the player was started with.
///
/// The command line of a process on Linux is a list of words separated by null
/// bytes, and the first word is the program itself.
List<String> commandLineArguments(List<int> bytes) {
  final words = <String>[];
  var start = 0;
  for (var index = 0; index < bytes.length; index++) {
    if (bytes[index] != 0) continue;
    words.add(utf8.decode(bytes.sublist(start, index), allowMalformed: true));
    start = index + 1;
  }
  if (start < bytes.length) {
    words.add(utf8.decode(bytes.sublist(start), allowMalformed: true));
  }
  if (words.isEmpty) return const [];
  return words.sublist(1);
}

/// The files the player was started with.
///
/// The arguments of the command line are not only files: switches and
/// unknown options are ignored, so the player never tries to play something
/// that is not there.
List<String> startupFiles(List<String> arguments) {
  final files = <String>[];
  for (final argument in arguments) {
    if (argument.isEmpty) continue;
    if (argument.startsWith('-')) continue;
    files.add(argument);
  }
  return files;
}
