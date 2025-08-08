import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ThemeInitial extends ThemeState {}

class ThemeChangedState extends ThemeState {
  final ThemeMode themeMode;
  final String? themeName;

  ThemeChangedState(this.themeMode, {this.themeName});

  @override
  List<Object?> get props => [themeMode, themeName];
}