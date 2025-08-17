import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/home/states/home_state.dart';
import 'package:tune/ui/home/controllers/home_controller.dart';

class HomeStateNotifier extends StateNotifier<HomeState> {
  final HomeController _homeController;

  HomeStateNotifier({required HomeController homeController})
      : _homeController = homeController,
        super(HomeState.initial());

  Future<void> loadSongs() async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final songs = await _homeController.getAllSongs();
      state = state.copyWith(
        isLoading: false,
        songs: songs,
        errorMessage: '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        songs: [],
        errorMessage: e.toString(),
      );
    }
  }
}