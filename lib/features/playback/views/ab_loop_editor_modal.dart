import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rein_player/common/widgets/rp_snackbar.dart';
import 'package:rein_player/features/playback/controller/ab_loop_controller.dart';
import 'package:rein_player/features/playback/controller/controls_controller.dart';
import 'package:rein_player/features/playback/models/ab_loop_segment.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';
import 'package:rein_player/utils/localization/tr_args.dart';

class ABLoopEditorModal extends StatefulWidget {
  final ABLoopSegment? segment;
  final int? segmentIndex;

  const ABLoopEditorModal({
    super.key,
    this.segment,
    this.segmentIndex,
  });

  @override
  State<ABLoopEditorModal> createState() => _ABLoopEditorModalState();
}

class _ABLoopEditorModalState extends State<ABLoopEditorModal> {
  late TextEditingController _startTimeController;
  late TextEditingController _durationController;
  late TextEditingController _loopCountController;
  late TextEditingController _delayController;
  late TextEditingController _titleController;

  bool _delayEnabled = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.segment != null;

    if (_isEditing) {
      final segment = widget.segment!;
      _startTimeController =
          TextEditingController(text: segment.formattedStartTime);
      // Show as seconds
      _durationController = TextEditingController(
          text: (segment.durationMs / 1000).toStringAsFixed(1));
      _loopCountController =
          TextEditingController(text: segment.loopCount.toString());
      _delayController =
          TextEditingController(text: segment.repeatDelayMs.toString());
      _titleController = TextEditingController(text: segment.title ?? '');
      _delayEnabled = segment.delayEnabled;
    } else {
      // Default values for new segment
      final currentPos = ControlsController.to.videoPosition.value;
      _startTimeController = TextEditingController(
          text: currentPos != null ? _formatDuration(currentPos) : '00:00:00');
      // 5 seconds as number
      _durationController = TextEditingController(text: '5');
      _loopCountController = TextEditingController(text: '1');
      _delayController = TextEditingController(text: '0');
      _titleController = TextEditingController();
      _delayEnabled = false;
    }
  }

  @override
  void dispose() {
    _startTimeController.dispose();
    _durationController.dispose();
    _loopCountController.dispose();
    _delayController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: RpColors.gray_900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _isEditing ? Icons.edit : Icons.add,
                  color: RpColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  _isEditing
                      ? LocaleKeys.abLoopEditorEditTitle.tr
                      : LocaleKeys.abLoopEditorAddTitle.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Start time
            _buildTextField(
              label: LocaleKeys.abLoopEditorPointA.tr,
              controller: _startTimeController,
              hint: LocaleKeys.abLoopEditorHhmmss.tr,
              suffix: IconButton(
                icon: const Icon(Icons.my_location, size: 18),
                onPressed: _setCurrentPositionAsStart,
                tooltip: LocaleKeys.abLoopEditorUseCurrentPosition.tr,
                color: RpColors.accent,
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            _buildTextField(
              label: LocaleKeys.abLoopEditorDuration.tr,
              controller: _durationController,
              hint: LocaleKeys.abLoopEditorDurationHint.tr,
              suffix: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  LocaleKeys.abLoopEditorSec.tr,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Loop count
            _buildTextField(
              label: LocaleKeys.abLoopEditorLoopCount.tr,
              controller: _loopCountController,
              hint: LocaleKeys.abLoopEditorLoopCountHint.tr,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),

            // Delay settings
            Row(
              children: [
                Checkbox(
                  value: _delayEnabled,
                  onChanged: (value) {
                    setState(() {
                      _delayEnabled = value ?? false;
                    });
                  },
                  activeColor: RpColors.accent,
                ),
                Text(
                  LocaleKeys.abLoopEditorEnableRepeatDelay.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            if (_delayEnabled) ...[
              const SizedBox(height: 8),
              _buildTextField(
                label: LocaleKeys.abLoopEditorRepeatDelay.tr,
                controller: _delayController,
                hint: LocaleKeys.abLoopEditorRepeatDelayHint.tr,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
            const SizedBox(height: 16),

            // Title
            _buildTextField(
              label: LocaleKeys.abLoopEditorTitle.tr,
              controller: _titleController,
              hint: LocaleKeys.abLoopEditorTitleHint.tr,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(LocaleKeys.cancel.tr),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                  ),
                ),
                const SizedBox(width: 12),

                // Save button
                ElevatedButton(
                  onPressed: _saveSegment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RpColors.accent,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    _isEditing
                        ? LocaleKeys.abLoopEditorUpdate.tr
                        : LocaleKeys.abLoopEditorAdd.tr,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: RpColors.accent, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  void _setCurrentPositionAsStart() {
    final position = ControlsController.to.videoPosition.value;
    if (position != null) {
      _startTimeController.text = _formatDuration(position);
    }
  }

  void _saveSegment() {
    try {
      final startMs = _parseTimeToMs(_startTimeController.text);
      
      // Parse duration as seconds (decimal)
      final durationSeconds = double.parse(_durationController.text);
      final durationMs = (durationSeconds * 1000).round();
      
      final loopCount = int.parse(_loopCountController.text);
      final delayMs = _delayEnabled ? int.parse(_delayController.text) : 0;
      final title = _titleController.text.trim();

      if (loopCount < 1) {
        RpSnackbar.error(
          title: LocaleKeys.abLoopEditorInvalidLoopCount.tr,
          message: LocaleKeys.abLoopEditorInvalidLoopCountMsg.tr,
        );
        return;
      }

      if (durationMs < 100) {
        RpSnackbar.error(
          title: LocaleKeys.abLoopEditorInvalidDuration.tr,
          message: LocaleKeys.abLoopEditorInvalidDurationMsg.tr,
        );
        return;
      }

      final segment = ABLoopSegment(
        sequenceIndex: _isEditing ? widget.segment!.sequenceIndex : 0,
        startTimeMs: startMs,
        durationMs: durationMs,
        loopCount: loopCount,
        title: title.isNotEmpty ? title : null,
        repeatDelayMs: delayMs,
        delayEnabled: _delayEnabled,
      );

      if (_isEditing && widget.segmentIndex != null) {
        ABLoopController.to.updateSegment(widget.segmentIndex!, segment);
      } else {
        ABLoopController.to.addSegment(segment);
      }

      Navigator.of(context).pop();
    } catch (e) {
      RpSnackbar.error(
        title: LocaleKeys.abLoopEditorInvalidInput.tr,
        message:
            LocaleKeys.abLoopEditorInvalidInputMsg.trArgs([e.toString()]),
      );
    }
  }

  int _parseTimeToMs(String time) {
    final parts = time.split(':');
    if (parts.length != 3) {
      throw FormatException('Invalid time format');
    }

    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2]);

    return (hours * 3600 + minutes * 60 + seconds) * 1000;
  }
}
