import 'package:tune/domain/models/song.dart';

class PlaylistService {
  List<Song> _currentPlaylist = [];
  int _currentIndex = 0;

  List<Song> get currentPlaylist => List.unmodifiable(_currentPlaylist);
  int get currentIndex => _currentIndex;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _currentPlaylist.length 
      ? _currentPlaylist[_currentIndex] 
      : null;

  void setPlaylist(List<Song> songs, {int startIndex = 0}) {
    _currentPlaylist = List.from(songs);
    _currentIndex = startIndex.clamp(0, songs.isEmpty ? 0 : songs.length - 1);
  }

  void addSong(Song song) {
    _currentPlaylist.add(song);
  }

  void removeSong(Song song) {
    final index = _currentPlaylist.indexOf(song);
    if (index != -1) {
      _currentPlaylist.removeAt(index);
      if (_currentIndex >= _currentPlaylist.length) {
        _currentIndex = _currentPlaylist.isEmpty ? 0 : _currentPlaylist.length - 1;
      }
    }
  }

  Song? next() {
    if (_currentPlaylist.isEmpty) return null;
    _currentIndex = (_currentIndex + 1) % _currentPlaylist.length;
    return currentSong;
  }

  Song? previous() {
    if (_currentPlaylist.isEmpty) return null;
    _currentIndex = (_currentIndex - 1 + _currentPlaylist.length) % _currentPlaylist.length;
    return currentSong;
  }

  void playAtIndex(int index) {
    if (index >= 0 && index < _currentPlaylist.length) {
      _currentIndex = index;
    }
  }

  void clear() {
    _currentPlaylist.clear();
    _currentIndex = 0;
  }
}
