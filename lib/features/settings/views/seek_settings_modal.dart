import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rein_player/common/widgets/rp_dialog.dart';
import 'package:rein_player/common/widgets/rp_snackbar.dart';
import 'package:rein_player/features/settings/controller/seek_settings_controller.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/constants/rp_enums.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';
import 'package:rein_player/utils/localization/tr_args.dart';

/// Seek settings modal
class SeekSettingsModal extends StatelessWidget {
  const SeekSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return RpDialog.show(
      context: context,
      title: LocaleKeys.seekTitle.tr,
      titleIcon: const Icon(Icons.fast_forward, color: RpColors.accent),
      maxWidth: 550,
      content: const _SeekSettingsContent(),
      actions: [
        ElevatedButton.icon(
          onPressed: () async {
            await SeekSettingsController.to.resetToDefaults();
            RpSnackbar.success(
              title: LocaleKeys.seekResetToDefaults.tr,
              message: LocaleKeys.seekResetMsg.tr,
            );
          },
          icon: const Icon(Icons.restore, size: 16),
          label: Text(
            LocaleKeys.seekResetToDefaults.tr,
            style: const TextStyle(fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: RpColors.black_600,
            foregroundColor: RpColors.white,
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            LocaleKeys.close.tr,
            style: const TextStyle(color: RpColors.accent, fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Content widget for the seek settings dialog
class _SeekSettingsContent extends StatelessWidget {
  const _SeekSettingsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selection
        Text(
          LocaleKeys.seekSeekMode.tr,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: RpColors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        const _ModeSelector(),
        const SizedBox(height: 24),

        // Regular Seek Configuration
        Text(
          LocaleKeys.seekRegularSeek.tr,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: RpColors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        const _RegularSeekConfig(),
        const SizedBox(height: 24),

        // Big Seek Configuration
        Text(
          LocaleKeys.seekBigSeek.tr,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: RpColors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        const _BigSeekConfig(),
      ],
    );
  }
}

/// Mode selector (Adaptive/Fixed)
class _ModeSelector extends StatelessWidget {
  const _ModeSelector();

  @override
  Widget build(BuildContext context) {
    final controller = SeekSettingsController.to;

    return Obx(() => Column(
          children: [
            RadioListTile<SeekMode>(
              title: Text(
                LocaleKeys.seekAdaptive.tr,
                style: const TextStyle(color: RpColors.white, fontSize: 13),
              ),
              subtitle: Text(
                LocaleKeys.seekAdaptiveDesc.tr,
                style: const TextStyle(color: RpColors.white_300, fontSize: 11),
              ),
              value: SeekMode.adaptive,
              groupValue: controller.settings.value.mode,
              activeColor: RpColors.accent,
              onChanged: (value) {
                if (value != null) {
                  controller.updateSeekMode(value);
                }
              },
            ),
            RadioListTile<SeekMode>(
              title: Text(
                LocaleKeys.seekFixed.tr,
                style: const TextStyle(color: RpColors.white, fontSize: 13),
              ),
              subtitle: Text(
                LocaleKeys.seekFixedDesc.tr,
                style: const TextStyle(color: RpColors.white_300, fontSize: 11),
              ),
              value: SeekMode.fixed,
              groupValue: controller.settings.value.mode,
              activeColor: RpColors.accent,
              onChanged: (value) {
                if (value != null) {
                  controller.updateSeekMode(value);
                }
              },
            ),
          ],
        ));
  }
}

/// Regular seek configuration
class _RegularSeekConfig extends StatelessWidget {
  const _RegularSeekConfig();

  @override
  Widget build(BuildContext context) {
    final controller = SeekSettingsController.to;

    return Obx(() {
      final isAdaptive = controller.settings.value.mode == SeekMode.adaptive;

      if (isAdaptive) {
        // Adaptive mode - show percentage slider
        final percentage = controller.settings.value.regularSeekPercentage;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: percentage,
                    min: 0.005,
                    max: 0.1,
                    divisions: 95,
                    activeColor: RpColors.accent,
                    onChanged: (value) {
                      controller.updateRegularSeekPercentage(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: RpColors.gray_800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: RpColors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.seekRangePercentSmall.tr,
              style: const TextStyle(color: RpColors.white_300, fontSize: 11),
            ),
          ],
        );
      } else {
        // Fixed mode - show seconds input
        final seconds = controller.settings.value.regularSeekSeconds;
        return _SecondsInput(
          value: seconds,
          minValue: 1,
          maxValue: 120,
          onChanged: (value) {
            controller.updateRegularSeekSeconds(value);
          },
        );
      }
    });
  }
}

/// Big seek configuration
class _BigSeekConfig extends StatelessWidget {
  const _BigSeekConfig();

  @override
  Widget build(BuildContext context) {
    final controller = SeekSettingsController.to;

    return Obx(() {
      final isAdaptive = controller.settings.value.mode == SeekMode.adaptive;

      if (isAdaptive) {
        // Adaptive mode - show percentage slider
        final percentage = controller.settings.value.bigSeekPercentage;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: percentage,
                    min: 0.01,
                    max: 0.2,
                    divisions: 190,
                    activeColor: RpColors.accent,
                    onChanged: (value) {
                      controller.updateBigSeekPercentage(value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: RpColors.gray_800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${(percentage * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(color: RpColors.white, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.seekRangePercentBig.tr,
              style: const TextStyle(color: RpColors.white_300, fontSize: 11),
            ),
          ],
        );
      } else {
        // Fixed mode - show seconds input
        final seconds = controller.settings.value.bigSeekSeconds;
        return _SecondsInput(
          value: seconds,
          minValue: 5,
          maxValue: 300,
          onChanged: (value) {
            controller.updateBigSeekSeconds(value);
          },
        );
      }
    });
  }
}

/// Seconds input widget with increment/decrement buttons
class _SecondsInput extends StatelessWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  const _SecondsInput({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decrement button
            IconButton(
              onPressed: value > minValue
                  ? () => onChanged(value - 1)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: RpColors.accent,
              disabledColor: RpColors.white_300,
            ),
            const SizedBox(width: 16),

            // Value display with text input
            Container(
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: RpColors.gray_800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: TextEditingController(text: value.toString())
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: value.toString().length),
                  ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: RpColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  suffix: Text(
                    's',
                    style: TextStyle(
                      color: RpColors.white_300,
                      fontSize: 14,
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (text) {
                  final newValue = int.tryParse(text);
                  if (newValue != null && newValue >= minValue && newValue <= maxValue) {
                    onChanged(newValue);
                  }
                },
              ),
            ),
            const SizedBox(width: 16),

            // Increment button
            IconButton(
              onPressed: value < maxValue
                  ? () => onChanged(value + 1)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
              color: RpColors.accent,
              disabledColor: RpColors.white_300,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          LocaleKeys.seekRangeSeconds.trArgs([minValue, maxValue]),
          style: const TextStyle(color: RpColors.white_300, fontSize: 11),
        ),
      ],
    );
  }
}
