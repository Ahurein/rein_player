import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';

class RpDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    double maxWidth = 500,
    Widget? titleIcon,
  }) {
    return showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Dialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        if (titleIcon != null) ...[
                          titleIcon,
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Content
                    Flexible(
                      child: SingleChildScrollView(
                        child: content,
                      ),
                    ),

                    // Actions
                    if (actions != null && actions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '',
    String cancelText = '',
    Color confirmColor = Colors.red,
    Widget? titleIcon,
    double maxWidth = 400,
  }) {
    return show<bool>(
      context: context,
      title: title,
      titleIcon: titleIcon,
      maxWidth: maxWidth,
      content: Text(
        message,
        style: const TextStyle(
          color: RpColors.black_300,
          fontSize: 14,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelText.isEmpty ? LocaleKeys.cancel.tr : cancelText,
            style: const TextStyle(color: RpColors.black_300),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText.isEmpty ? LocaleKeys.confirm.tr : confirmText),
        ),
      ],
    );
  }

  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required Widget content,
    String closeText = '',
    Widget? titleIcon,
    double maxWidth = 500,
  }) {
    return show(
      context: context,
      title: title,
      titleIcon: titleIcon,
      maxWidth: maxWidth,
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            closeText.isEmpty ? LocaleKeys.close.tr : closeText,
            style: const TextStyle(color: RpColors.accent),
          ),
        ),
      ],
    );
  }

  static Widget buildActionButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: RpColors.accent,
          foregroundColor: Colors.black,
        ),
        child: Text(text),
      );
    } else {
      return TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(color: RpColors.black_300),
        ),
      );
    }
  }
}
