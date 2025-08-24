import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// 均衡器控制组件
class PlayerEqualizer extends ConsumerStatefulWidget {
  const PlayerEqualizer({super.key});

  @override
  ConsumerState<PlayerEqualizer> createState() => _PlayerEqualizerState();
}

class _PlayerEqualizerState extends ConsumerState<PlayerEqualizer> {
  // 模拟均衡器频段值
  List<double> _bandValues = List.filled(10, 0.0);
  bool _isEnabled = false;

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.equalizer,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Switch(
                value: _isEnabled,
                onChanged: (value) {
                  setState(() {
                    _isEnabled = value;
                  });
                },
              ),
            ],
          ),
          if (_isEnabled) ...[
            const SizedBox(height: 16),
            // 频段滑块
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(10, (index) {
                return Column(
                  children: [
                    RotatedBox(
                      quarterTurns: -1,
                      child: SizedBox(
                        width: 100,
                        child: Slider(
                          value: _bandValues[index],
                          min: -10.0,
                          max: 10.0,
                          onChanged: (value) {
                            setState(() {
                              _bandValues[index] = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Text('${index + 1}'),
                  ],
                );
              }),
            ),
            const SizedBox(height: 16),
            // 预设选项
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ChoiceChip(
                  label: Text(loc.flat),
                  selected: false,
                  onSelected: (selected) {},
                ),
                ChoiceChip(
                  label: Text(loc.pop),
                  selected: false,
                  onSelected: (selected) {},
                ),
                ChoiceChip(
                  label: Text(loc.rock),
                  selected: false,
                  onSelected: (selected) {},
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}