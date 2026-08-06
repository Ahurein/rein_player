import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rein_player/features/settings/controller/keyboard_preferences_controller.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';

class KeyboardBindingsModal extends StatefulWidget {
  const KeyboardBindingsModal({super.key});

  @override
  State<KeyboardBindingsModal> createState() => _KeyboardBindingsModalState();
}

class _KeyboardBindingsModalState extends State<KeyboardBindingsModal> {
  String? editingAction;
  bool isListeningForKey = false;

  @override
  Widget build(BuildContext context) {
    // Ensure the controller is available
    if (!Get.isRegistered<KeyboardPreferencesController>()) {
      return Dialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          width: 400,
          height: 200,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: RpColors.accent),
                const SizedBox(height: 16),
                Text(
                  LocaleKeys.keyboardLoading.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
          minWidth: 400,
          minHeight: 500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with integrated toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LocaleKeys.keyboardTitle.tr,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: RpColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Compact enable/disable toggle
                    Obx(() {
                      final isEnabled = KeyboardPreferencesController.to.shortcutsEnabled.value;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isEnabled
                                ? LocaleKeys.keyboardEnabled.tr
                                : LocaleKeys.keyboardDisabled.tr,
                            style: const TextStyle(color: RpColors.white, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          Transform.scale(
                            scale: 0.8,
                            child:                             Switch(
                              value: isEnabled,
                              onChanged: (value) async {
                                await KeyboardPreferencesController.to.toggleShortcuts(value);
                              },
                              activeColor: RpColors.accent,
                              inactiveThumbColor: RpColors.white_300,
                              inactiveTrackColor: RpColors.black_600,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, color: RpColors.white),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              LocaleKeys.keyboardInstruction.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: RpColors.white_300,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 16),

            // Warning banner when shortcuts are disabled
            Obx(() {
              if (!KeyboardPreferencesController.to.shortcutsEnabled.value) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: RpColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: RpColors.orange.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: RpColors.orange, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          LocaleKeys.keyboardDisabledWarning.tr,
                          style: const TextStyle(color: RpColors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await KeyboardPreferencesController.to.resetToDefaults();
                  },
                  icon: const Icon(Icons.restore),
                  label: Text(
                    LocaleKeys.seekResetToDefaults.tr,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RpColors.black_600,
                    foregroundColor: RpColors.white,
                  ),
                ),
                const SizedBox(width: 10),
                if (isListeningForKey)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RpColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: RpColors.accent),
                    ),
                    child: Text(
                      LocaleKeys.keyboardPressAnyKey.tr,
                      style: const TextStyle(
                        color: RpColors.accent,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Bindings list
            Expanded(
              child: GetBuilder<KeyboardPreferencesController>(
                builder: (controller) => ListView.builder(
                  itemCount:
                      KeyboardPreferencesController.defaultBindings.length,
                  itemBuilder: (context, index) {
                    final action = KeyboardPreferencesController
                        .defaultBindings.keys
                        .elementAt(index);
                    final description = KeyboardPreferencesController
                        .actionDescriptions[action]!;
                    final currentKey = controller.keyBindings[action];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: RpColors.gray_800,
                        borderRadius: BorderRadius.circular(6),
                        border: editingAction == action
                            ? Border.all(color: RpColors.accent, width: 2)
                            : null,
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        title: Text(
                          description,
                          style: const TextStyle(
                            color: RpColors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: _buildSubtitle(action),
                        trailing: SizedBox(
                          width: 100,
                          child: GestureDetector(
                            onTap: () => _startEditingKey(action),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: editingAction == action
                                    ? RpColors.accent.withValues(alpha: 0.2)
                                    : RpColors.black_600,
                                borderRadius: BorderRadius.circular(4),
                                border: editingAction == action
                                    ? Border.all(color: RpColors.accent)
                                    : null,
                              ),
                              child: Text(
                                currentKey != null
                                    ? controller.getKeyDisplayName(currentKey)
                                    : LocaleKeys.keyboardUnassigned.tr,
                                style: TextStyle(
                                  color: editingAction == action
                                      ? RpColors.accent
                                      : RpColors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    LocaleKeys.close.tr,
                    style: const TextStyle(color: RpColors.accent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildSubtitle(String action) {
    const actionsToHoldShift = [
      'big_seek_backward',
      'big_seek_forward',
      'delete_and_skip',
      'previous_bookmark',
    ];
    const actionsToHoldCtrl = [
      'toggle_playlist',
      'toggle_developer_log',
      'toggle_keyboard_bindings',
      'add_bookmark',
      'add_ab_loop_segment',
    ];
    const actionsToHoldCtrlShift = [
      'toggle_bookmark_list',
      'toggle_ab_loop_playback',
      'export_ab_loops',
    ];

    if (actionsToHoldCtrlShift.contains(action)) {
      return Text(
        LocaleKeys.keyboardHoldCtrlShift.tr,
        style: const TextStyle(color: RpColors.black_500, fontSize: 11),
      );
    } else if (actionsToHoldShift.contains(action)) {
      return Text(
        LocaleKeys.keyboardHoldShift.tr,
        style: const TextStyle(color: RpColors.black_500, fontSize: 11),
      );
    } else if (actionsToHoldCtrl.contains(action)) {
      return Text(
        LocaleKeys.keyboardHoldCtrl.tr,
        style: const TextStyle(color: RpColors.black_500, fontSize: 11),
      );
    }
    return null;
  }

  void _startEditingKey(String action) {
    setState(() {
      editingAction = action;
      isListeningForKey = true;
    });

    // Set up key listener
    _listenForKeyPress();
  }

  void _listenForKeyPress() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            final logicalKey = event.logicalKey;

            // Ignore modifier keys alone
            if (_isModifierKey(logicalKey)) return;

            // Update the binding
            if (editingAction != null) {
              KeyboardPreferencesController.to
                  .updateKeyBinding(editingAction!, logicalKey);
            }

            // Close dialog and reset state
            Navigator.of(context).pop();
            setState(() {
              editingAction = null;
              isListeningForKey = false;
            });
          }
        },
        child: Dialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.keyboard,
                  size: 48,
                  color: RpColors.accent,
                ),
                const SizedBox(height: 16),
                Text(
                  LocaleKeys.keyboardPressKeyFor.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: RpColors.white,
                        fontSize: 14,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  KeyboardPreferencesController
                          .actionDescriptions[editingAction] ??
                      '',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: RpColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      editingAction = null;
                      isListeningForKey = false;
                    });
                  },
                  child: Text(
                    LocaleKeys.cancel.tr,
                    style: const TextStyle(
                      color: RpColors.white_300,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isModifierKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
  }
}
