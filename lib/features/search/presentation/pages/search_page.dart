import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tune/app/router/app_router.dart';
import 'package:tune/core/utils/platform_detector.dart';
import 'package:tune/core/widgets/music/song_list.dart';
import 'package:tune/di/injector.dart';
import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/usecases/search_songs.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_bloc.dart';
import 'package:tune/features/audio/presentation/bloc/player/player_event.dart';
import 'package:tune/l10n/app_localizations.dart';

@RoutePage()
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late SearchSongs _searchSongs;
  List<Song> _songs = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  late final TextEditingController _searchController;
  late final StreamController<String> _searchStreamController;
  late final StreamSubscription<String> _searchSubscription;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchSongs = Injector.get<SearchSongs>();
    _searchController.addListener(_onSearchChanged);

    // 初始化搜索流控制器
    _searchStreamController = StreamController();

    // 添加防抖搜索
    _searchSubscription = _searchStreamController.stream.where((query) => query.isNotEmpty).debounceTime(const Duration(milliseconds: 300)).listen((query) async {
      try {
        final songs = await _searchSongs(query);
        if (mounted) {
          setState(() {
            _songs = songs;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = e.toString();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchSubscription.cancel();
    _searchStreamController.close();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // 清除错误状态
    if (_hasError) {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    }

    // 处理空查询
    if (query.isEmpty) {
      setState(() {
        _songs = [];
        _isLoading = false;
      });
      return;
    }

    // 添加搜索请求到流
    _isLoading = true;
    _searchStreamController.add(query);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final useMobileLayout = PlatformDetector.isMobile;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: localizations.search_hint,
            border: InputBorder.none,
            hintStyle: _SearchHintStyle(context: context),
          ),
          style: _SearchTextStyle(context: context),
          onSubmitted: (query) {
            _onSearchChanged();
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _searchController.clear();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _buildBody(localizations),
    );
  }

  Widget _buildBody(AppLocalizations localizations) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage ?? localizations.failed_to_load_songs, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _performSearch(_searchController.text.trim());
              },
              child: Text(localizations.search_title), // 使用已存在的本地化字符串
            ),
          ],
        ),
      );
    }

    if (_songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(localizations.search_no_results, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return SongList(
      songs: _songs,
      onSongSelected: (song) {
        context.read<PlayerBloc>().add(PlaySongEvent(song.id));
        context.pushRoute(const MusicPlayerRoute());
      },
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _songs = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final songs = await _searchSongs(query);
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }
}

class _SearchHintStyle extends TextStyle {
  final BuildContext context;

  _SearchHintStyle({required this.context}) : super(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5));
}

class _SearchTextStyle extends TextStyle {
  final BuildContext context;

  _SearchTextStyle({required this.context}) : super(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color);
}
