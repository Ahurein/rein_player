import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:rein_player/common/widgets/rp_snackbar.dart';
import 'package:rein_player/features/settings/controller/subtitle_styling_controller.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/constants/subtitle_constants.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';
import 'package:rein_player/utils/localization/tr_args.dart';

/// Subtitle settings modal
class SubtitleSettingsModal extends StatelessWidget {
  const SubtitleSettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          height: MediaQuery.of(context).size.height * 0.5,
          constraints: const BoxConstraints(
            maxWidth: 450,
            maxHeight: 650,
            minWidth: 300,
            minHeight: 200,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LocaleKeys.subtitleTitle.tr,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: RpColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: RpColors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Tabs
              TabBar(
                indicatorColor: RpColors.accent,
                labelColor: RpColors.accent,
                unselectedLabelColor: RpColors.white_300,
                labelStyle: const TextStyle(fontSize: 14),
                tabs: [
                  Tab(text: LocaleKeys.subtitleTabFont.tr),
                  Tab(text: LocaleKeys.subtitleTabPosition.tr),
                  Tab(text: LocaleKeys.subtitleTabAdvanced.tr),
                ],
              ),
              const SizedBox(height: 16),

              // Tab Views
              const Expanded(
                child: TabBarView(
                  children: [
                    _FontTab(),
                    _PositionTab(),
                    _AdvancedTab(),
                  ],
                ),
              ),

              // Bottom buttons
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await SubtitleStylingController.to.resetToDefaults();
                      RpSnackbar.success(
                        title: LocaleKeys.subtitleResetToDefaults.tr,
                        message: LocaleKeys.subtitleResetMsg.tr,
                      );
                    },
                    icon: const Icon(Icons.restore, size: 16),
                    label: Text(
                      LocaleKeys.subtitleResetToDefaults.tr,
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RpColors.black_600,
                      foregroundColor: RpColors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      LocaleKeys.close.tr,
                      style: const TextStyle(color: RpColors.accent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Font customization tab
class _FontTab extends StatelessWidget {
  const _FontTab();

  @override
  Widget build(BuildContext context) {
    final controller = SubtitleStylingController.to;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Font Family
            Text(
              LocaleKeys.subtitleFont.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: RpColors.white,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Obx(() => Container(
                  decoration: BoxDecoration(
                    color: RpColors.gray_800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: controller.settings.value.fontFamily,
                    isExpanded: true,
                    dropdownColor: RpColors.gray_800,
                    underline: const SizedBox(),
                    style: const TextStyle(color: RpColors.white),
                    items: SubtitleConstants.availableFonts
                        .map((font) => DropdownMenuItem(
                              value: font,
                              child: Text(font),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.updateFontFamily(value);
                      }
                    },
                  ),
                )),
            const SizedBox(height: 24),

            // Font Size
            Text(
              LocaleKeys.subtitleSize.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: RpColors.white,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Obx(() => Slider(
                        value: controller.settings.value.fontSize,
                        min: SubtitleConstants.minFontSize,
                        max: SubtitleConstants.maxFontSize,
                        activeColor: RpColors.accent,
                        onChanged: (value) {
                          controller.updateFontSize(value);
                        },
                      )),
                ),
                const SizedBox(width: 12),
                Obx(() => Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: RpColors.gray_800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${controller.settings.value.fontSize.toInt()}',
                        style: const TextStyle(color: RpColors.white),
                        textAlign: TextAlign.center,
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 24),

            // Preview
            Text(
              LocaleKeys.subtitlePreview.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: RpColors.white,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: RpColors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Obx(() => Text(
                    LocaleKeys.subtitleSampleText.tr,
                    style: controller.getSubtitleTextStyle(),
                    textAlign: controller.settings.value.textAlign,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Position adjustment tab
class _PositionTab extends StatelessWidget {
  const _PositionTab();

  @override
  Widget build(BuildContext context) {
    final controller = SubtitleStylingController.to;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleKeys.subtitleTabPosition.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: RpColors.white,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 16),

            // Position controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Up button
                _PositionButton(
                  icon: Icons.arrow_upward,
                  label: LocaleKeys.subtitleUp.tr,
                  onPressed: controller.moveUp,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left button
                _PositionButton(
                  icon: Icons.arrow_back,
                  label: LocaleKeys.subtitleLeft.tr,
                  onPressed: controller.moveLeft,
                ),
                const SizedBox(width: 60),
                // Right button
                _PositionButton(
                  icon: Icons.arrow_forward,
                  label: LocaleKeys.subtitleRight.tr,
                  onPressed: controller.moveRight,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Down button
                _PositionButton(
                  icon: Icons.arrow_downward,
                  label: LocaleKeys.subtitleDown.tr,
                  onPressed: controller.moveDown,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current position display
            Center(
              child: Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: RpColors.gray_800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      LocaleKeys.subtitleVerticalHorizontal.trArgs([
                        controller.settings.value.verticalPosition
                            .toStringAsFixed(0),
                        controller.settings.value.horizontalPosition
                            .toStringAsFixed(0),
                      ]),
                      style:
                          const TextStyle(color: RpColors.white, fontSize: 12),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

/// Advanced settings tab
class _AdvancedTab extends StatelessWidget {
  const _AdvancedTab();

  @override
  Widget build(BuildContext context) {
    final controller = SubtitleStylingController.to;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text Alignment
            Text(
              LocaleKeys.subtitleTextAlignment.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: RpColors.white,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Obx(() => Row(
                  children: [
                    _AlignmentButton(
                      icon: Icons.format_align_left,
                      isSelected:
                          controller.settings.value.textAlign == TextAlign.left,
                      onPressed: () =>
                          controller.updateTextAlign(TextAlign.left),
                    ),
                    const SizedBox(width: 8),
                    _AlignmentButton(
                      icon: Icons.format_align_center,
                      isSelected: controller.settings.value.textAlign ==
                          TextAlign.center,
                      onPressed: () =>
                          controller.updateTextAlign(TextAlign.center),
                    ),
                    const SizedBox(width: 8),
                    _AlignmentButton(
                      icon: Icons.format_align_right,
                      isSelected: controller.settings.value.textAlign ==
                          TextAlign.right,
                      onPressed: () =>
                          controller.updateTextAlign(TextAlign.right),
                    ),
                  ],
                )),
            const SizedBox(height: 20),

            // Text Color
            Text(
              LocaleKeys.subtitleTextColor.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: RpColors.white,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Obx(() => _ColorPickerButton(
                  color: controller.settings.value.textColor,
                  onColorChanged: controller.updateTextColor,
                  label: LocaleKeys.subtitleText.tr,
                )),
            const SizedBox(height: 20),

            // Background Color
            Text(
              LocaleKeys.subtitleBackgroundColor.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: RpColors.white,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Obx(() => _ColorPickerButton(
                  color: controller.settings.value.backgroundColor,
                  onColorChanged: controller.updateBackgroundColor,
                  label: LocaleKeys.subtitleBackground.tr,
                )),
            const SizedBox(height: 20),

            // Outline Width
            Text(
              LocaleKeys.subtitleOutlineWidth.tr,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: RpColors.white,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Obx(() => Slider(
                        value: controller.settings.value.outlineWidth,
                        min: 0,
                        max: SubtitleConstants.maxOutlineWidth,
                        activeColor: RpColors.accent,
                        onChanged: (value) {
                          controller.updateOutlineWidth(value);
                        },
                      )),
                ),
                const SizedBox(width: 12),
                Obx(() => Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: RpColors.gray_800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        controller.settings.value.outlineWidth
                            .toStringAsFixed(1),
                        style: const TextStyle(
                            color: RpColors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Position control button widget
class _PositionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PositionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: RpColors.gray_800,
        foregroundColor: RpColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Alignment button widget
class _AlignmentButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;

  const _AlignmentButton({
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      color: isSelected ? RpColors.accent : RpColors.white_300,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: isSelected ? RpColors.gray_800 : Colors.transparent,
      ),
    );
  }
}

/// Color picker button widget
class _ColorPickerButton extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final String label;

  const _ColorPickerButton({
    required this.color,
    required this.onColorChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showColorPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: RpColors.gray_800,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            // Color preview
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: RpColors.white_300),
              ),
            ),
            const SizedBox(width: 12),
            // Color hex value
            Expanded(
              child: Text(
                '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                style: const TextStyle(
                  color: RpColors.white,
                  fontSize: 12,
                  fontFamily: 'Courier',
                ),
              ),
            ),
            const Icon(Icons.edit, color: RpColors.white_300, size: 16),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: Text(
          LocaleKeys.subtitlePickColor.trArgs([label.tr]),
          style: const TextStyle(color: RpColors.white, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: color,
            onColorChanged: onColorChanged,
            pickersEnabled: const {
              ColorPickerType.both: false,
              ColorPickerType.primary: true,
              ColorPickerType.accent: false,
              ColorPickerType.wheel: true,
            },
            enableOpacity: true,
            opacityTrackHeight: 30,
            opacityThumbRadius: 15,
            wheelDiameter: 200,
            wheelWidth: 20,
            wheelSquarePadding: 4,
            wheelSquareBorderRadius: 4,
            wheelHasBorder: true,
            heading: Text(
              LocaleKeys.subtitleSelectColor.tr,
              style: const TextStyle(color: RpColors.white, fontSize: 14),
            ),
            subheading: Text(
              LocaleKeys.subtitleSelectColorShade.tr,
              style: const TextStyle(color: RpColors.white_300, fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              LocaleKeys.subtitleDone.tr,
              style: const TextStyle(color: RpColors.accent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
