import 'package:flutter/material.dart';

extension ScaffoldMessengerExtension on BuildContext {
  ScaffoldMessengerState get message => ScaffoldMessenger.of(this);
}
