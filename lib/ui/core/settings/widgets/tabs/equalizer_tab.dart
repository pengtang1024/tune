import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/persistence_providers.dart';

class EqualizerTab extends ConsumerStatefulWidget {
  const EqualizerTab({super.key});

  @override
  ConsumerState<EqualizerTab> createState() => _EqualizerTabState();
}

class _EqualizerTabState extends ConsumerState<EqualizerTab> {
  bool _equalizerEnabled = false;
  List<double> _bandValues = List.filled(10, 0.0); // 10个频段
  String _selectedPreset = 'flat';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    final persistenceService = ref.read(sharedPreferencesServiceProvider);

    setState(() {
      _equalizerEnabled = persistenceService.getBool('equalizer_enabled') ?? false;
      _selectedPreset = persistenceService.getString('equalizer_preset') ?? 'flat';
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final persistenceService = ref.read(sharedPreferencesServiceProvider);

    if (value is bool) {
      await persistenceService.setBool(key, value);
    } else if (value is String) {
      await persistenceService.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sharedPreferencesServiceProvider);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.equalizer,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 均衡器开关
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.loc.enable_equalizer,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _equalizerEnabled,
                    onChanged: (value) {
                      setState(() {
                        _equalizerEnabled = value;
                      });
                      _saveSetting('equalizer_enabled', value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (_equalizerEnabled) ...[
            // 预设选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.presets,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedPreset,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPreset = newValue;
                          });
                          _saveSetting('equalizer_preset', newValue);
                        }
                      },
                      items: [
                        DropdownMenuItem(value: 'flat', child: Text(context.loc.flat)),
                        DropdownMenuItem(value: 'pop', child: Text(context.loc.pop)),
                        DropdownMenuItem(value: 'rock', child: Text(context.loc.rock)),
                        DropdownMenuItem(value: 'jazz', child: Text(context.loc.jazz)),
                        DropdownMenuItem(value: 'classical', child: Text(context.loc.classical)),
                        DropdownMenuItem(value: 'hip_hop', child: Text(context.loc.hip_hop)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 自定义均衡器
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.custom_equalizer,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // 频段滑块
                    for (int i = 0; i < _bandValues.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _bandValues[i],
                                min: -10.0,
                                max: 10.0,
                                divisions: 20,
                                label: '${_bandValues[i].toStringAsFixed(1)} dB',
                                onChanged: (value) {
                                  setState(() {
                                    _bandValues[i] = value;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 50,
                              child: Text(
                                '${_bandValues[i].toStringAsFixed(1)} dB',
                                textAlign: TextAlign.end,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}