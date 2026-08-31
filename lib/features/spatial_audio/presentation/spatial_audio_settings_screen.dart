import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_gradients.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import '../domain/spatial_audio_models.dart';
import '../domain/spatial_audio_providers.dart';
import 'widgets/spatial_sound_visualizer.dart';

/// 3D Spatial Audio Configuration & Interactive Control Screen.
class SpatialAudioSettingsScreen extends ConsumerStatefulWidget {
  const SpatialAudioSettingsScreen({super.key});

  @override
  ConsumerState<SpatialAudioSettingsScreen> createState() =>
      _SpatialAudioSettingsScreenState();
}

class _SpatialAudioSettingsScreenState
    extends ConsumerState<SpatialAudioSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _centerAnimController;
  Animation<SpatialAudioPosition>? _centerAnimation;
  bool _testingAudio = false;

  @override
  void initState() {
    super.initState();
    _centerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _centerAnimController.dispose();
    super.dispose();
  }

  void _animateToCenter(SpatialAudioPosition current) {
    AppHaptics.light();
    const target = SpatialAudioPosition(x: 0.0, y: 0.8, z: 0.0);

    _centerAnimation = Tween<SpatialAudioPosition>(
      begin: current,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _centerAnimController,
        curve: Curves.easeOutCubic,
      ),
    )..addListener(() {
        if (_centerAnimation != null) {
          ref
              .read(spatialAudioSettingsProvider.notifier)
              .setPosition(_centerAnimation!.value);
        }
      });

    _centerAnimController.forward(from: 0.0);
  }

  Future<void> _startTest() async {
    AppHaptics.medium();
    setState(() => _testingAudio = true);

    await ref.read(spatialAudioSettingsProvider.notifier).startTestAudio();

    await Future.delayed(const Duration(milliseconds: 3200));
    if (mounted) {
      setState(() => _testingAudio = false);
      AppHaptics.selection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(spatialAudioSettingsProvider);
    final stateAsync = ref.watch(spatialAudioStateProvider);
    final capsAsync = ref.watch(spatialAudioCapabilitiesProvider);

    final isEnabled = settings.enabled;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final liveState = stateAsync.valueOrNull ?? SpatialAudioState.initial();
    final headYaw = liveState.headYaw;
    final isTesting = _testingAudio || liveState.isTesting;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: theme.colorScheme.onSurface,
                    onPressed: () {
                      AppHaptics.light();
                      context.pop();
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('3D Spatial Audio', style: AppTextStyles.headingLarge),
                      Text('Shape your sound', style: AppTextStyles.tagline),
                    ],
                  ),
                  const Spacer(),
                  // Master Toggle Switch
                  Switch(
                    value: isEnabled,
                    onChanged: (val) {
                      AppHaptics.selection();
                      ref
                          .read(spatialAudioSettingsProvider.notifier)
                          .setEnabled(val);
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero 360° Interactive Spatial Visualizer Card
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isEnabled
                              ? AppColors.purple.withValues(alpha: 0.35)
                              : (isDark ? const Color(0xFF2B293E) : AppColors.cardBorder),
                          width: isEnabled ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isEnabled
                                ? AppColors.purple.withValues(alpha: 0.1)
                                : (isDark ? Colors.black.withValues(alpha: 0.25) : AppColors.cardShadow),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Stage Visualizer
                          SpatialSoundVisualizer(
                            position: settings.position,
                            isEnabled: isEnabled,
                            headYaw: headYaw,
                            isTesting: isTesting,
                            onPositionChanged: (newPos) {
                              ref
                                  .read(spatialAudioSettingsProvider.notifier)
                                  .setPosition(newPos);
                            },
                          ),

                          // Bottom position readout & reset action bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF161522) : const Color(0xFFF9F8FE),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
                              border: Border(
                                top: BorderSide(
                                  color: isDark ? const Color(0xFF2B293E) : AppColors.divider,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                // Position label
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sound Position',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        settings.position.toAccessibleLabel().replaceFirst('Sound source position: ', ''),
                                        style: AppTextStyles.labelLarge.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isEnabled ? AppColors.purple : AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Center Sound Button
                                GestureDetector(
                                  onTap: isEnabled ? () => _animateToCenter(settings.position) : null,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isEnabled
                                          ? AppColors.purple.withValues(alpha: 0.12)
                                          : (isDark ? const Color(0xFF2B293E) : AppColors.disabled),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.center_focus_strong_rounded,
                                          size: 15,
                                          color: isEnabled ? AppColors.purple : AppColors.textMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Center sound',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isEnabled ? AppColors.purple : AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Head Tracking Card
                    _SectionCard(
                      child: Column(
                        children: [
                          capsAsync.when(
                            data: (caps) {
                              final canTrack = caps.supportsHeadTracking;
                              return _ToggleRow(
                                icon: Icons.sensors_rounded,
                                title: 'Head Tracking',
                                subtitle: canTrack
                                    ? 'Keep sound positioned in world space as you move'
                                    : 'Sensor tracking unavailable on this headphone model',
                                value: canTrack && settings.headTracking,
                                enabled: isEnabled && canTrack,
                                onChanged: (val) {
                                  AppHaptics.selection();
                                  ref
                                      .read(spatialAudioSettingsProvider.notifier)
                                      .setHeadTracking(val);
                                },
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3. Spatial Sound Controls (Immersion, Distance, Elevation)
                    _SectionCard(
                      child: Column(
                        children: [
                          // Immersion Slider
                          _SliderRow(
                            label: 'Immersion',
                            subtitle: 'Binaural envelopment & spatial width',
                            value: settings.immersion,
                            minLabel: 'Low',
                            maxLabel: 'High',
                            enabled: isEnabled,
                            onChanged: (val) {
                              ref
                                  .read(spatialAudioSettingsProvider.notifier)
                                  .setImmersion(val);
                            },
                          ),

                          Divider(
                            height: 24,
                            color: isDark ? const Color(0xFF2B293E) : AppColors.divider,
                          ),

                          // Distance Slider
                          _SliderRow(
                            label: 'Distance',
                            subtitle: 'Virtual acoustic soundstage depth',
                            value: settings.distance,
                            minLabel: 'Near',
                            maxLabel: 'Far',
                            enabled: isEnabled,
                            onChanged: (val) {
                              ref
                                  .read(spatialAudioSettingsProvider.notifier)
                                  .setDistance(val);
                            },
                          ),

                          // Elevation (Height)
                          capsAsync.when(
                            data: (caps) {
                              if (caps.supportsElevation) {
                                return Column(
                                  children: [
                                    Divider(
                                      height: 24,
                                      color: isDark ? const Color(0xFF2B293E) : AppColors.divider,
                                    ),
                                    _SliderRow(
                                      label: 'Elevation',
                                      subtitle: 'Vertical height positioning',
                                      value: (settings.elevation + 1.0) / 2.0,
                                      minLabel: 'Below',
                                      maxLabel: 'Above',
                                      enabled: isEnabled,
                                      onChanged: (val) {
                                        final elev = val * 2.0 - 1.0;
                                        ref
                                            .read(spatialAudioSettingsProvider.notifier)
                                            .setElevation(elev);
                                      },
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 4. Acoustic Environment / Room
                    Text('Acoustic Environment', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 8),
                    _SectionCard(
                      child: Column(
                        children: [
                          Row(
                            children: RoomType.values.map((room) {
                              final isSelected = settings.room == room;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: GestureDetector(
                                    onTap: isEnabled
                                        ? () {
                                            AppHaptics.selection();
                                            ref
                                                .read(spatialAudioSettingsProvider.notifier)
                                                .setRoom(room);
                                          }
                                        : null,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.purple.withValues(alpha: isDark ? 0.25 : 0.12)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.purple
                                              : (isDark ? const Color(0xFF2B293E) : AppColors.cardBorder),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          room.label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                            color: isSelected
                                                ? AppColors.purple
                                                : (isDark ? const Color(0xFFB0AFC0) : AppColors.textSecondary),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            settings.room.description,
                            style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 5. Spatial Presets
                    Text('Spatial Presets', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 86,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: SpatialPreset.values.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final p = SpatialPreset.values[index];
                          final isSelected = settings.preset == p;

                          return GestureDetector(
                            onTap: isEnabled
                                ? () {
                                    AppHaptics.selection();
                                    ref
                                        .read(spatialAudioSettingsProvider.notifier)
                                        .applyPreset(p);
                                  }
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 130,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.purple.withValues(alpha: isDark ? 0.3 : 0.12)
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.purple
                                      : (isDark ? const Color(0xFF2B293E) : AppColors.cardBorder),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    p.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? AppColors.purple : (isDark ? Colors.white : AppColors.textPrimary),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    p.description,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? const Color(0xFF9E9DB0) : AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 6. Test 3D Audio Button
                    GestureDetector(
                      onTap: isEnabled && !isTesting ? _startTest : null,
                      child: AnimatedScale(
                        scale: isTesting ? 0.97 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: Container(
                          height: 52,
                          decoration: isEnabled
                              ? AppGradients.primaryButton(radius: 16)
                              : AppGradients.disabledButtonOf(context, radius: 16),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isTesting ? Icons.spatial_tracking_rounded : Icons.play_arrow_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isTesting ? 'Testing 3D Audio (Orbiting)...' : 'Test 3D Audio',
                                  style: AppTextStyles.buttonLarge.copyWith(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 7. Hardware Capabilities Card
                    capsAsync.when(
                      data: (caps) {
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF161522) : const Color(0xFFF9F8FE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified_outlined,
                                    size: 16,
                                    color: AppColors.purple,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Spatial Engine: ${caps.rendererName}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _CapabilityRow(
                                label: 'HRTF Binaural Synthesis',
                                supported: caps.supportsBinaural,
                              ),
                              _CapabilityRow(
                                label: 'Soundstage Spatialization',
                                supported: caps.supportsSpatialization,
                              ),
                              _CapabilityRow(
                                label: 'Head Orientation Sensors',
                                supported: caps.supportsHeadTracking,
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.purple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.minLabel,
    required this.maxLabel,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final double value;
  final String minLabel;
  final String maxLabel;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelLarge),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: enabled ? AppColors.purple : AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 7,
              pressedElevation: 2,
            ),
            activeTrackColor: enabled ? AppColors.purple : AppColors.disabled,
            inactiveTrackColor: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
            thumbColor: enabled ? AppColors.purple : AppColors.disabled,
            overlayColor: AppColors.purple.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: value.clamp(0.0, 1.0),
            onChanged: enabled ? onChanged : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(minLabel, style: AppTextStyles.labelSmall),
              Text(maxLabel, style: AppTextStyles.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.label, required this.supported});
  final String label;
  final bool supported;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            supported ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 14,
            color: supported ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: supported ? AppColors.textSecondary : AppColors.textMuted,
              ),
            ),
          ),
          Text(
            supported ? 'Supported' : 'Limited',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: supported ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
