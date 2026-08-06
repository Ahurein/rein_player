import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rein_player/common/widgets/rp_snackbar.dart';
import 'package:rein_player/features/developer/controller/developer_log_controller.dart';
import 'package:rein_player/features/playback/controller/ab_loop_controller.dart';
import 'package:rein_player/features/playback/controller/bookmark_controller.dart';
import 'package:rein_player/features/playback/controller/controls_controller.dart';
import 'package:rein_player/features/playback/controller/playback_speed_controller.dart';
import 'package:rein_player/features/playback/controller/subtitle_controller.dart';
import 'package:rein_player/features/playback/controller/volume_controller.dart';
import 'package:rein_player/features/player_frame/controller/navigation_context_controller.dart';
import 'package:rein_player/features/player_frame/controller/window_actions_controller.dart';
import 'package:rein_player/features/playlist/controller/album_content_controller.dart';
import 'package:rein_player/features/playlist/controller/playlist_controller.dart';
import 'package:rein_player/features/settings/controller/keyboard_preferences_controller.dart';
import 'package:rein_player/features/settings/views/keyboard_bindings_modal.dart';
import 'package:rein_player/utils/constants/rp_enums.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';

class KeyboardController extends GetxController {
  static KeyboardController get to => Get.find();

  void handleKey(KeyEvent event) async {
    if (event is KeyDownEvent) {
      // Check if shortcuts are enabled
      if (!KeyboardPreferencesController.to.shortcutsEnabled.value) {
        return; // Skip all shortcut processing
      }

      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;
      final currentKey = event.logicalKey;

      // Get the keyboard preferences controller
      final keyPrefs = KeyboardPreferencesController.to;

      // Check each action and its assigned key
      final keyBindings = keyPrefs.keyBindings;

      // Get action context early for context-aware checks
      final actionContext = NavigationContextController.to.currentContext.value;

      // Play/Pause (only in player context to avoid conflicts with playlist Space)
      if (currentKey == keyBindings['play_pause'] &&
          actionContext == ActionContext.player) {
        ControlsController.to.pauseOrPlay();
        return;
      }

      // Fullscreen (only in player context to avoid conflicts with playlist Enter)
      if (currentKey == keyBindings['toggle_maximize_window'] &&
          !WindowActionsController.to.isFullScreenMode.value &&
          actionContext == ActionContext.player) {
        WindowActionsController.to.toggleWindowSize();
        return;
      }

      // Seek operations (with modifier key support)
      if (currentKey == keyBindings['seek_backward'] ||
          currentKey == keyBindings['big_seek_backward']) {
        if (isShiftPressed && currentKey == keyBindings['big_seek_backward']) {
          await ControlsController.to.bigSeekBackward();
        } else if (!isShiftPressed &&
            currentKey == keyBindings['seek_backward']) {
          await ControlsController.to.seekBackward();
        }
        return;
      }

      if (currentKey == keyBindings['seek_forward'] ||
          currentKey == keyBindings['big_seek_forward']) {
        if (isShiftPressed && currentKey == keyBindings['big_seek_forward']) {
          await ControlsController.to.bigSeekForward();
        } else if (!isShiftPressed &&
            currentKey == keyBindings['seek_forward']) {
          await ControlsController.to.seekForward();
        }
        return;
      }

      // Volume controls / Playlist navigation (context-aware)
      if (currentKey == keyBindings['volume_up']) {
        if (actionContext == ActionContext.player) {
          final currentVolume = VolumeController.to.currentVolume.value;
          final volumeToSet = currentVolume + 0.1;
          if (volumeToSet > 1) {
            VolumeController.to.updateVolume(1);
          } else {
            VolumeController.to.updateVolume(volumeToSet);
          }
        } else if (actionContext == ActionContext.playlist) {
          AlbumContentController.to.selectPreviousItem();
        }
        return;
      }

      if (currentKey == keyBindings['volume_down']) {
        if (actionContext == ActionContext.player) {
          final currentVolume = VolumeController.to.currentVolume.value;
          final volumeToSet = currentVolume - 0.1;
          if (volumeToSet < 0) {
            VolumeController.to.updateVolume(0);
          } else {
            VolumeController.to.updateVolume(volumeToSet);
          }
        } else if (actionContext == ActionContext.playlist) {
          AlbumContentController.to.selectNextItem();
        }
        return;
      }

      // Play selected item in playlist context with Enter/Space
      if (actionContext == ActionContext.playlist &&
          (currentKey == LogicalKeyboardKey.enter || 
           currentKey == LogicalKeyboardKey.space)) {
        
        // If an item is highlighted, play it
        if (AlbumContentController.to.selectedIndex.value >= 0) {
          AlbumContentController.to.playSelectedItem();
        } else {
          // No highlight, replay current video from start
          await ControlsController.to.player.seek(Duration.zero);
        }
        return;
      }

      // Toggle mute
      if (currentKey == keyBindings['toggle_mute']) {
        VolumeController.to.toggleVolumeMuteState();
        return;
      }

      // Toggle subtitle
      if (currentKey == keyBindings['toggle_subtitle']) {
        SubtitleController.to.toggleSubtitle();
        return;
      }

      // Exit fullscreen
      if (currentKey == keyBindings['toggle_fullscreen']) {
        WindowActionsController.to.toggleFullScreenWindow();
        return;
      }

      // Bookmark operations (B key with various modifiers)
      if (currentKey == keyBindings['add_bookmark']) {
        // Ctrl+Shift+B: Toggle bookmark list
        if (isCtrlPressed && isShiftPressed) {
          BookmarkController.to.toggleBookmarkOverlay();
          return;
        }
        // Ctrl+B: Add bookmark (but not Shift, to avoid conflict with toggle playlist)
        if (isCtrlPressed && !isShiftPressed) {
          await BookmarkController.to.addBookmark();
          return;
        }
        // Shift+B: Previous bookmark
        if (isShiftPressed && !isCtrlPressed) {
          await BookmarkController.to.jumpToPreviousBookmark();
          return;
        }
        // B alone: Next bookmark
        if (!isCtrlPressed && !isShiftPressed) {
          await BookmarkController.to.jumpToNextBookmark();
          return;
        }
      }

      // A-B Loop operations (L key with various modifiers)
      if (currentKey == keyBindings['add_ab_loop_segment'] ||
          currentKey == keyBindings['toggle_ab_loop_overlay'] ||
          currentKey == keyBindings['toggle_ab_loop_playback']) {
        // Ctrl+Shift+L: Toggle A-B loop playback
        if (isCtrlPressed && isShiftPressed &&
            currentKey == keyBindings['toggle_ab_loop_playback']) {
          ABLoopController.to.toggleABLoopPlayback();
          return;
        }
        // Ctrl+L: Add segment at current position
        if (isCtrlPressed && !isShiftPressed &&
            currentKey == keyBindings['add_ab_loop_segment']) {
          ABLoopController.to.addSegmentAtCurrentPosition();
          return;
        }
        // L alone: Toggle A-B loop overlay
        if (!isCtrlPressed && !isShiftPressed &&
            currentKey == keyBindings['toggle_ab_loop_overlay']) {
          ABLoopController.to.toggleOverlay();
          return;
        }
      }

      // A-B Loop segment navigation
      if (currentKey == keyBindings['previous_ab_loop_segment']) {
        // [: Previous segment
        await ABLoopController.to.jumpToPreviousSegment();
        return;
      }

      if (currentKey == keyBindings['next_ab_loop_segment']) {
        // ]: Next segment
        await ABLoopController.to.jumpToNextSegment();
        return;
      }

      // Export A-B loops to PBF
      if (currentKey == keyBindings['export_ab_loops'] &&
          isCtrlPressed &&
          isShiftPressed) {
        await ABLoopController.to.exportToPBF();
        return;
      }

      // Toggle playlist (with Ctrl modifier)
      if (currentKey == keyBindings['toggle_playlist'] && isCtrlPressed) {
        PlaylistController.to.togglePlaylistWindow();
        if (PlaylistController.to.isPlaylistWindowOpened.value) {
          NavigationContextController.to.switchToPlaylist();
        }
        return;
      }

      // Toggle developer log (with Ctrl modifier)
      if (currentKey == keyBindings['toggle_developer_log'] && isCtrlPressed) {
        DeveloperLogController.to.toggleVisibility();
        return;
      }

      // Toggle keyboard bindings (with Ctrl modifier)
      if (currentKey == keyBindings['toggle_keyboard_bindings'] && isCtrlPressed) {
        Get.dialog(const KeyboardBindingsModal());
        return;
      }

      // Playback speed controls
      if (currentKey == keyBindings['decrease_speed']) {
        PlaybackSpeedController.to.decreaseSpeed();
        return;
      }

      if (currentKey == keyBindings['increase_speed']) {
        PlaybackSpeedController.to.increaseSpeed();
        return;
      }

      // Playlist navigation
      if (currentKey == keyBindings['next_track']) {
        await AlbumContentController.to.goNextItemInPlaylist();
        return;
      }

      if (currentKey == keyBindings['previous_track']) {
        AlbumContentController.to.goPreviousItemInPlaylist();
        return;
      }

      // Delete current item and skip to next (with Shift modifier)
      if (currentKey == keyBindings['delete_and_skip'] && isShiftPressed) {
        final success =
            await AlbumContentController.to.deleteCurrentItemAndSkip();
        if (success) {
          RpSnackbar.success(
            title: LocaleKeys.snackDeleted.tr,
            message: LocaleKeys.snackDeletedAndSkipped.tr,
          );
        } else {
          RpSnackbar.error(message: LocaleKeys.snackFailedDeleteFile.tr);
        }
        return;
      }

      // Shuffle playlist
      if (currentKey == keyBindings['shuffle_playlist']) {
        AlbumContentController.to.shufflePlaylistContent();
        RpSnackbar.success(
          title: LocaleKeys.snackPlaylistShuffled.tr,
          message: LocaleKeys.snackPlaylistShuffledMsg.tr,
        );
        return;
      }
    }
  }
}
