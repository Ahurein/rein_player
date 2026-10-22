import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:get/get.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rein_player/features/playback/controller/controls_controller.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/playback/controller/volume_controller.dart';
import 'package:rein_player/features/player_frame/controller/navigation_context_controller.dart';
import 'package:rein_player/features/player_frame/controller/window_actions_controller.dart';
import 'package:rein_player/features/settings/controller/menu_controller.dart';
import 'package:rein_player/features/settings/controller/settings_controller.dart';
import 'package:rein_player/features/playback/views/playback_speed_overlay.dart';
import 'package:rein_player/features/playback/views/subtitle_overlay.dart';
import 'package:rein_player/features/playback/views/bookmark_overlay.dart';
import 'package:rein_player/features/playback/views/ab_loop_overlay.dart';
import 'package:rein_player/features/settings/views/menu/menu_items.dart';
import 'package:rein_player/listeners/scroll_detector.dart';
import 'package:rein_player/utils/constants/rp_enums.dart';

import 'no_media_placeholder.dart';

class RpVideoScreen extends StatelessWidget {
  const RpVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final videoController = Get.put(VideoAndControlController());

    return Obx(() {
      return ContextMenuRegion(
        contextMenu: createContextMenu(),
        child: MouseRegion(
          onHover: (_) => MainMenuController.to.hideMenu,
          child: ScrollDetector(
            onPointerScroll: VolumeController.to.onScrollUpdateVolume,
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                child: Stack(
                  children: [
                    /// video
                    GestureDetector(
                      onTap: () {
                        NavigationContextController.to.switchToPlayer();
                      },
                      onDoubleTap: () {
                        final doubleClickAction = SettingsController.to.settings.doubleClickAction;
                        
                        if (doubleClickAction == DoubleClickAction.toggleWindowSize) {
                          WindowActionsController.to.toggleWindowSize();
                        } else {
                          ControlsController.to.pauseOrPlay();
                        }
                      },
                      onTertiaryTapUp: (details) {
                        if (details.kind == PointerDeviceKind.mouse) {
                          WindowActionsController.to.toggleWindowSize();
                        }
                      },
                      child: Obx(() {
                        if (VideoAndControlController
                            .to.currentVideoUrl.isEmpty) {
                          return const RpNoMediaPlaceholder();
                        }

                        // subtitles are drawn by RpSubtitleOverlay so that the
                        // secondary track can be placed at the top
                        return Video(
                          key: ValueKey(
                              VideoAndControlController.to.currentVideoUrl),
                          controller: videoController.videoPlayerController,
                          controls: NoVideoControls,
                          subtitleViewConfiguration:
                              const SubtitleViewConfiguration(visible: false),
                        );
                      }),
                    ),

                    /// primary (bottom) and secondary (top) subtitles
                    const RpSubtitleOverlay(),

                    /// playback speed overlay
                    const PlaybackSpeedOverlay(),

                    /// bookmark overlay
                    const BookmarkOverlay(),

                    /// A-B loop overlay
                    const ABLoopOverlay(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
