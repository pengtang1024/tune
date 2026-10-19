import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/theme/app_interactions.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class SleepTimer extends ConsumerStatefulWidget {
  const SleepTimer({super.key});

  @override
  ConsumerState<SleepTimer> createState() => _SleepTimerState();
}

class _SleepTimerState extends ConsumerState<SleepTimer> {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _selectedMinutes = 30;
  bool _isRunning = false;

  final List<int> _presets = [15, 30, 45, 60, 90, 120];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _remainingSeconds = _selectedMinutes * 60;
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _stopTimer();
          ref.read(playerStateNotifierProvider.notifier).pause();
        }
      });
    });
  }

  void _stopTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remainingSeconds = 0;
    });
  }

  String _formatRemaining() {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: AppDesignSystem.iconSize24, color: AppDesignSystem.primary),
              const SizedBox(width: AppDesignSystem.spacing12),
              Text(
                _isRunning ? '睡眠定时器 ($_formatRemaining())' : '睡眠定时器',
                style: AppDesignSystem.textTheme.titleSmall?.copyWith(fontWeight: AppDesignSystem.fontWeightSemiBold),
              ),
              const Spacer(),
              if (_isRunning)
                AppInteractions.pressableScale(
                  scaleValue: 0.9,
                  onTap: _stopTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing12, vertical: AppDesignSystem.spacing6),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.error.withValues(alpha: 0.1),
                      borderRadius: AppDesignSystem.borderRadius8,
                    ),
                    child: Text('取消', style: AppDesignSystem.textTheme.labelMedium?.copyWith(color: AppDesignSystem.error)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDesignSystem.spacing12),
          if (!_isRunning) ...[
            Wrap(
              spacing: AppDesignSystem.spacing8,
              runSpacing: AppDesignSystem.spacing8,
              children: _presets.map((m) {
                final isSelected = _selectedMinutes == m;
                return AppInteractions.pressableScale(
                  scaleValue: 0.93,
                  onTap: () => setState(() => _selectedMinutes = m),
                  child: AnimatedContainer(
                    duration: AppDesignSystem.duration200,
                    padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing16, vertical: AppDesignSystem.spacing8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppDesignSystem.primary : AppDesignSystem.primary.withValues(alpha: 0.08),
                      borderRadius: AppDesignSystem.borderRadius12,
                    ),
                    child: Text(
                      m >= 60 ? context.loc.hours(m ~/ 60) : context.loc.minutes(m),
                      style: AppDesignSystem.textTheme.labelMedium?.copyWith(
                        color: isSelected ? Colors.white : AppDesignSystem.primary,
                        fontWeight: AppDesignSystem.fontWeightMedium,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppDesignSystem.spacing12),
            SizedBox(
              width: double.infinity,
              child: AppInteractions.pressableScale(
                scaleValue: 0.97,
                onTap: _startTimer,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing12),
                  decoration: BoxDecoration(
                    gradient: AppDesignSystem.primaryGradient,
                    borderRadius: AppDesignSystem.borderRadius12,
                  ),
                  child: Text(
                    context.loc.sleep_timer_start,
                    style: AppDesignSystem.textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: AppDesignSystem.fontWeightBold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
