import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundshare/core/constants/app_assets.dart';
import 'package:soundshare/core/utils/app_haptics.dart';
import 'package:soundshare/core/widgets/skeleton_loader.dart';
import 'package:soundshare/app/theme/app_colors.dart';
import 'package:soundshare/app/theme/app_text_styles.dart';
import 'package:soundshare/core/widgets/animated_widgets.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_device_model.dart';
import 'package:soundshare/features/bluetooth/domain/bluetooth_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_providers.dart';
import 'package:soundshare/features/audio_sharing/domain/audio_sharing_service.dart';
import 'widgets/connected_audio_card.dart';
import 'widgets/bluetooth_device_card.dart';
import 'widgets/connected_devices_panel.dart';
import 'widgets/share_audio_button.dart';
import '../../beatsync/presentation/widgets/beatsync_card.dart';
import '../../../core/widgets/theme_toggle_button.dart';

class ShareScreen extends ConsumerWidget {
  const ShareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btAdapterState = ref.watch(bluetoothAdapterStateProvider);
    final isScanning = ref.watch(isScanningProvider);
    final discoveredDevices = ref.watch(discoveredDevicesProvider);
    final connectedDevices = ref.watch(connectedDevicesProvider);
    final sharingState = ref.watch(audioSharingStateProvider);
    final sharingDuration = ref.watch(sharingDurationProvider);

    final btEnabled = btAdapterState.valueOrNull == BluetoothAdapterState.on;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────
            const _AppHeader(),

            // ── Scrollable content ───────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Bluetooth off / no permission banner
                    if (!btEnabled)
                      _BluetoothOffBanner(
                        onEnable: () async {
                          try {
                            await FlutterBluePlus.turnOn();
                          } catch (_) {}
                        },
                      ),

                    if (btEnabled) ...[
                      // Audio Source card (This Phone)
                      ConnectedAudioCard(
                        deviceType: BluetoothDeviceType.phone,
                        deviceName: connectedDevices.isNotEmpty
                            ? 'Broadcasting to ${connectedDevices.length} ${connectedDevices.length == 1 ? 'device' : 'devices'}'
                            : 'This Phone (Media Audio)',
                        isConnected: btEnabled,
                      ),

                      const SizedBox(height: 14),

                      // BeatSync Feature Card
                      const BeatSyncCard(),

                      const SizedBox(height: 20),

                      // Bluetooth devices section
                      _BluetoothDevicesSection(
                        isScanning: isScanning.valueOrNull ?? false,
                        devices: discoveredDevices,
                        onScan: () {
                          if (isScanning.valueOrNull == true) {
                            ref
                                .read(discoveredDevicesProvider.notifier)
                                .stopScan();
                          } else {
                            ref
                                .read(discoveredDevicesProvider.notifier)
                                .startScan();
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      // Connected devices panel
                      ConnectedDevicesPanel(
                        connectedDevices: connectedDevices,
                        sharingState: sharingState,
                      ),

                      const SizedBox(height: 24),
                    ],

                    if (!btEnabled) ...[
                      const BeatSyncCard(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),

            // ── Share Audio button ────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ShareAudioButton(
                state: btEnabled ? sharingState : AudioSharingState.unavailable,
                sharingDuration: sharingDuration,
                onShare: () {
                  ref.read(audioSharingStateProvider.notifier).startSharing();
                },
                onStop: () {
                  ref.read(audioSharingStateProvider.notifier).stopSharing();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// App Header
// ──────────────────────────────────────────────

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Logo
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              AppAssets.logo,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),

          // Name + tagline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SoundShare', style: AppTextStyles.headingMedium),
                Text('Connect multiple devices', style: AppTextStyles.tagline),
              ],
            ),
          ),

          // Animated 3D Dark/Light mode toggle
          const ThemeToggleIconButton(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Bluetooth devices section
// ──────────────────────────────────────────────

class _BluetoothDevicesSection extends StatelessWidget {
  const _BluetoothDevicesSection({
    required this.isScanning,
    required this.devices,
    required this.onScan,
  });

  final bool isScanning;
  final List<dynamic> devices;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text('Bluetooth devices', style: AppTextStyles.headingSmall),
            const Spacer(),
            GestureDetector(
              onTap: () {
                AppHaptics.light();
                onScan();
              },
              child: Row(
                children: [
                  if (isScanning)
                    const ScanningAnimation(size: 14, color: AppColors.purple)
                  else
                    const Icon(
                      Icons.bluetooth_searching_rounded,
                      size: 16,
                      color: AppColors.purple,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    isScanning ? 'Scanning...' : 'Scan',
                    style: AppTextStyles.buttonMedium.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Device list
        if (devices.isEmpty && !isScanning)
          _EmptyDevicesCard()
        else ...[
          for (int i = 0; i < devices.length; i++)
            BluetoothDeviceCard(
              device: devices[i] as dynamic,
              animationDelay: Duration(milliseconds: i * 80),
            ),
        ],

        if (isScanning) ...[
          const BluetoothDeviceSkeletonCard(),
          const BluetoothDeviceSkeletonCard(),
        ],
      ],
    );
  }
}

class _EmptyDevicesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2B293E) : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.bluetooth_disabled_rounded,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            'No Bluetooth audio devices found',
            style: AppTextStyles.headingSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Make sure your headphones are nearby and discoverable.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


// ──────────────────────────────────────────────
// Bluetooth off banner
// ──────────────────────────────────────────────

class _BluetoothOffBanner extends StatelessWidget {
  const _BluetoothOffBanner({required this.onEnable});
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_disabled_rounded,
              color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bluetooth is turned off',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Turn on Bluetooth to find audio devices.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEnable,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Turn On',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
