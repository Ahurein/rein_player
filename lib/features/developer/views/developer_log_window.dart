import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';
import '../controller/developer_log_controller.dart';

class DeveloperLogWindow extends StatelessWidget {
  const DeveloperLogWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!DeveloperLogController.to.isVisible.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        right: 10,
        bottom: 10,
        width: 400,
        height: 300,
        child: Material(
          elevation: 8,
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.devLogTitle.tr,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear_all, color: Colors.white),
                          onPressed: DeveloperLogController.to.clearLogs,
                          tooltip: LocaleKeys.devLogClearLogs.tr,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: DeveloperLogController.to.toggleVisibility,
                          tooltip: LocaleKeys.close.tr,
                        ),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: Obx(() => ListView.builder(
                    reverse: true,
                    itemCount: DeveloperLogController.to.logs.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = DeveloperLogController.to.logs.length - 1 - index;
                      return Text(
                        DeveloperLogController.to.logs[reversedIndex],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  )),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
} 