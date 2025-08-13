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
import 'package:tune/core/services/search_history_service.dart';

@RoutePage()
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late SearchSongs _searchSongs;
  late SearchHistoryService _searchHistoryService;
  List<Song> _songs = [];
  List<String> _searchHistory = [];
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _showSuggestions = true;
  String? _errorMessage;
  late final TextEditingController _searchController;
  late final StreamController<String> _searchStreamController;
  late final StreamSubscription<String> _searchSubscription;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchSongs = Injector.get<SearchSongs>();
    _searchHistoryService = Injector.get<SearchHistoryService>();
    _searchController.addListener(_onSearchChanged);

    // 初始化搜索流控制器
    _searchStreamController = StreamController();

    // 添加防抖搜索
    _searchSubscription = _searchStreamController.stream
        .where((query) => query.isNotEmpty)
        .debounceTime(const Duration(milliseconds: 300))
        .listen((query) async {
      // 获取搜索建议
      _updateSuggestions(query);
      
      // 执行实际搜索
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

    // 加载搜索历史
    _loadSearchHistory();
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
        _suggestions = [];
        _isLoading = false;
        _showSuggestions = true;
      });
      return;
    }

    // 添加搜索请求到流
    _isLoading = true;
    _showSuggestions = true;
    _searchStreamController.add(query);
  }

  void _updateSuggestions(String query) {
    final suggestions = <String>[];
    for (final history in _searchHistory) {
      if (history.toLowerCase().contains(query.toLowerCase()) && 
          history.toLowerCase() != query.toLowerCase()) {
        suggestions.add(history);
        if (suggestions.length >= 5) break;
      }
    }
    
    // 如果历史记录中没有足够的建议，添加一些基于当前查询的通用建议
    if (suggestions.length < 5) {
      final commonSuggestions = [
        query,
        '$query 歌曲',
        '$query 专辑',
        '$query 歌手',
      ];
      
      for (final suggestion in commonSuggestions) {
        if (!suggestions.contains(suggestion) && 
            suggestion.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(suggestion);
          if (suggestions.length >= 5) break;
        }
      }
    }
    
    setState(() {
      _suggestions = suggestions;
    });
  }

  Future<void> _loadSearchHistory() async {
    final history = await _searchHistoryService.getSearchHistory();
    setState(() {
      _searchHistory = history;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _songs = [];
        _isLoading = false;
        _showSuggestions = true;
      });
      return;
    }

    // 添加到搜索历史
    await _searchHistoryService.addSearchHistory(query);
    await _loadSearchHistory();

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _showSuggestions = false;
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

  void _onSuggestionSelected(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  void _clearSearchHistory() async {
    await _searchHistoryService.clearSearchHistory();
    await _loadSearchHistory();
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
            _performSearch(query);
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _searchController.clear();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _songs = [];
                  _suggestions = [];
                  _showSuggestions = true;
                });
              },
            ),
          // 添加搜索按钮
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _performSearch(_searchController.text.trim());
            },
          ),
        ],
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
            Text(_errorMessage ?? localizations.failed_to_load_songs,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _performSearch(_searchController.text.trim());
              },
              child: Text(localizations.retry),
            ),
          ],
        ),
      );
    }

    // 显示搜索建议和历史
    if ((_songs.isEmpty && _showSuggestions) || _searchController.text.isEmpty) {
      return _buildSuggestionsAndHistory(localizations);
    }

    // 显示搜索结果
    if (_songs.isNotEmpty) {
      return SongList(
        songs: _songs,
        onSongSelected: (song) {
          context.read<PlayerBloc>().add(PlaySongEvent(song.id));
          context.pushRoute(const MusicPlayerRoute());
        },
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 48, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(localizations.search_no_results,
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildSuggestionsAndHistory(AppLocalizations localizations) {
    final List<Widget> children = [];

    // 搜索建议
    if (_suggestions.isNotEmpty && _searchController.text.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            localizations.search_suggestions,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );

      children.addAll(
        _suggestions.map(
          (suggestion) => ListTile(
            leading: const Icon(Icons.search),
            title: Text(suggestion),
            onTap: () => _onSuggestionSelected(suggestion),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                _searchController.text = suggestion;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: suggestion.length),
                );
              },
            ),
          ),
        ),
      );
    }

    // 搜索历史
    if (_searchHistory.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                localizations.search_history,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: _clearSearchHistory,
                child: Text(
                  localizations.clear_history,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
      );

      children.addAll(
        _searchHistory.take(10).map(
          (history) => ListTile(
            leading: const Icon(Icons.history),
            title: Text(history),
            onTap: () {
              _searchController.text = history;
              _performSearch(history);
            },
          ),
        ),
      );
    } else if (_searchController.text.isEmpty) {
      // 无历史记录时显示提示
      children.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 48,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.search_empty,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      children: children,
    );
  }
}

class _SearchHintStyle extends TextStyle {
  final BuildContext context;

  _SearchHintStyle({required this.context})
      : super(
          fontSize: 18,
          color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
        );
}

class _SearchTextStyle extends TextStyle {
  final BuildContext context;

  _SearchTextStyle({required this.context})
      : super(
          fontSize: 18,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        );
}