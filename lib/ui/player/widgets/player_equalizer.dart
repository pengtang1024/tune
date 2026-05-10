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
                style: AppDesignSystem.textTheme.titleSmall?.copyWith(
                  fontWeight: AppDesignSystem.fontWeightSemiBold,
                ),
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
                    onChanged: (v) => setState(() => _bandValues[index] = v),
                  );
                }),
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacing12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PresetChip(label: loc.flat, onTap: () => _resetBands()),
                const SizedBox(width: AppDesignSystem.spacing8),
                _PresetChip(label: loc.pop, onTap: () {}),
                const SizedBox(width: AppDesignSystem.spacing8),
                _PresetChip(label: loc.rock, onTap: () {}),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _resetBands() {
    setState(() {
      for (int i = 0; i < _bandValues.length; i++) {
        _bandValues[i] = 0.0;
      }
    });
  }
}

class _BandSlider extends StatelessWidget {
  final int index;
  final double value;
  final ValueChanged<double> onChanged;

  const _BandSlider({
    required this.index,
    required this.value,
    required this.onChanged,
  });

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
              colors: [
                AppDesignSystem.primary,
                AppDesignSystem.primary.withValues(alpha: 0.3),
              ],
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
              child: Slider(
                value: value,
                min: -10,
                max: 10,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing4),
        Text(
          '${index + 1}',
          style: AppDesignSystem.textTheme.labelSmall?.copyWith(
            color: AppDesignSystem.neutral400,
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacing16,
          vertical: AppDesignSystem.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppDesignSystem.primary.withValues(alpha: 0.08),
          borderRadius: AppDesignSystem.borderRadius20,
        ),
        child: Text(
          label,
          style: AppDesignSystem.textTheme.labelMedium?.copyWith(
            color: AppDesignSystem.primary,
            fontWeight: AppDesignSystem.fontWeightMedium,
          ),
        ),
      ),
    );
  }
}
