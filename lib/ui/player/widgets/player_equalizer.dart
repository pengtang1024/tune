import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class PlayerEqualizer extends ConsumerStatefulWidget {
  const PlayerEqualizer({super.key});

  @override
  ConsumerState<PlayerEqualizer> createState() => _PlayerEqualizerState();
}

class _PlayerEqualizerState extends ConsumerState<PlayerEqualizer> {
  final List<double> _bandValues = List.filled(10, 0.0);
  bool _isEnabled = false;
  String? _activePreset;

  static const _presets = {
    'flat': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'pop':  [3.0, 2.0, 0.0, -1.0, -2.0, -1.0, 1.0, 2.0, 3.0, 4.0],
    'rock': [5.0, 4.0, 1.5, -2.0, -3.0, -2.0, 0.0, 2.0, 4.0, 5.0],
    'jazz': [4.0, 3.0, 2.0, 1.0, 0.0, 0.0, 1.0, 2.0, 3.0, 4.0],
    'classical': [5.0, 4.0, 3.0, 2.0, 1.0, 1.0, 2.0, 3.0, 4.0, 5.0],
    'bass': [8.0, 6.0, 4.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'treble': [0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 4.0, 6.0, 8.0, 8.0],
    'vocal': [0.0, 0.0, -3.0, -2.0, 0.0, 2.0, 3.0, 2.0, 0.0, 0.0],
  };

  void _applyPreset(String name) {
    final values = _presets[name];
    if (values == null) return;
    setState(() {
      _activePreset = name;
      for (int i = 0; i < _bandValues.length && i < values.length; i++) {
        _bandValues[i] = values[i];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return ModernCard(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                loc.equalizer,
                style: AppDesignSystem.textTheme.titleSmall?.copyWith(fontWeight: AppDesignSystem.fontWeightSemiBold),
              ),
              Switch(
                value: _isEnabled,
                activeTrackColor: AppDesignSystem.primary,
                onChanged: (value) => setState(() => _isEnabled = value),
              ),
            ],
          ),
          if (_isEnabled) ...[
            const SizedBox(height: AppDesignSystem.spacing16),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(10, (index) {
                  return _BandSlider(
                    index: index,
                    value: _bandValues[index],
                    onChanged: (v) {
                      setState(() {
                        _bandValues[index] = v;
                        _activePreset = null;
                      });
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacing12),
            Wrap(
              spacing: AppDesignSystem.spacing8,
              runSpacing: AppDesignSystem.spacing8,
              children: _presets.keys.map((name) {
                final isActive = _activePreset == name;
                return GestureDetector(
                  onTap: () => _applyPreset(name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing12, vertical: AppDesignSystem.spacing6),
                    decoration: BoxDecoration(
                      color: isActive ? AppDesignSystem.primary : AppDesignSystem.primary.withValues(alpha: 0.08),
                      borderRadius: AppDesignSystem.borderRadius20,
                    ),
                    child: Text(
                      name[0].toUpperCase() + name.substring(1),
                      style: AppDesignSystem.textTheme.labelMedium?.copyWith(
                        color: isActive ? Colors.white : AppDesignSystem.primary,
                        fontWeight: AppDesignSystem.fontWeightMedium,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _BandSlider extends StatelessWidget {
  final int index;
  final double value;
  final ValueChanged<double> onChanged;
  const _BandSlider({required this.index, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: AppDesignSystem.borderRadius4,
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [AppDesignSystem.primary, AppDesignSystem.primary.withValues(alpha: 0.3)],
            ),
          ),
          child: RotatedBox(
            quarterTurns: -1,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: Colors.white.withValues(alpha: 0.9),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                thumbColor: Colors.white,
              ),
              child: Slider(value: value, min: -10, max: 10, onChanged: onChanged),
            ),
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing4),
        Text('${index + 1}', style: AppDesignSystem.textTheme.labelSmall?.copyWith(color: AppDesignSystem.neutral400)),
      ],
    );
  }
}
