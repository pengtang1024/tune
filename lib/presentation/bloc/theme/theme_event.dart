import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ThemeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ThemeChangedEvent extends ThemeEvent {
  final ThemeMode themeMode;
  final String? themeName;

  ThemeChangedEvent(this.themeMode, {this.themeName});

  @override
  List<Object?> get props => [themeMode, themeName];
}