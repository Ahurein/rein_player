import 'dart:async';
import 'dart:io';

import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:rein_player/features/developer/controller/developer_log_controller.dart';
import 'package:rein_player/features/playback/controller/ab_loop_controller.dart';
import 'package:rein_player/features/playback/controller/bookmark_controller.dart';
import 'package:rein_player/features/playback/controller/subtitle_controller.dart';
import 'package:rein_player/features/playback/controller/volume_controller.dart';
import 'package:rein_player/features/playback/models/video_audio_item.dart';
import 'package:rein_player/features/player_frame/controller/window_actions_controller.dart';
import 'package:rein_player/features/playlist/controller/album_content_controller.dart';
import 'package:rein_player/features/playlist/controller/album_controller.dart';
import 'package:rein_player/features/playlist/models/playlist_item.dart';
import 'package:rein_player/features/settings/controller/settings_controller.dart';
import 'package:rein_player/utils/constants/rp_enums.dart';
import 'package:rein_player/utils/constants/rp_keys.dart';
import 'package:rein_player/utils/device/rp_device_utils.dart';
import 'package:rein_player/utils/helpers/media_helper.dart';
import 'package:rein_player/utils/local_storage/rp_local_storage.dart';

import '../../../core/video_player.dart';
import '../../../utils/constants/rp_sizes.dart';
import 'controls_controller.dart';

class VideoAndControlController extends GetxController {
  static VideoAndControlController get to => Get.find();

  final storage = RpLocalStorage();

  final isVideoPlaying = false.obs;
  final isVideoCompleted = false.obs;
  final isFullScreenMode = false.obs;
  Rx<String> currentVideoUrl = "".obs;
  Rx<VideoOrAudioItem?> currentVideo = Rx<VideoOrAudioItem?>(null);

  Rx<double> videoAndControlScreenSize =
      RpSizes.minWindowAndControlScreenSize.obs;

  Player player = VideoPlayer.getInstance.player;
  late final videoPlayerController = VideoController(player);
  RxDouble reloadPlayerView = 0.0.obs;

  Timer? _positionSaveTimer;

  @override
  void dispose() async {
    await _stopPositionSaver();
    super.dispose();
    await videoPlayerController.player.dispose();
    videoPlayerController.player.dispose();
  }

  // Load saved position for a video
  int? _getSavedPosition(String videoPath) {
    try {
      final positions =
          storage.readData<Map>(RpKeysConstants.videoPositionsKey);
      if (positions == null) return null;

      final position = positions[videoPath];
      return position != null ? position['position'] as int : null;
    } catch (e) {
      return null;
    }
  }

  // Save current position to storage
  Future<void> _saveCurrentPosition() async {
    try {
      final video = currentVideo.value;
      final position = ControlsController.to.videoPosition.value;

      if (video == null || position == null) return;
      // Don't save if <5 seconds
      if (position.inSeconds < 5) return;

      final duration = ControlsController.to.videoDuration.value;
      if (duration != null && position.inSeconds > duration.inSeconds - 10) {
        // Don't save if within 10 seconds of end (video completed)
        return;
      }

      final positions =
          storage.readData<Map>(RpKeysConstants.videoPositionsKey) ?? {};
      positions[video.location] = {
        'position': position.inSeconds,
        'lastWatched': DateTime.now().toIso8601String(),
      };

      await storage.saveData(RpKeysConstants.videoPositionsKey, positions);
    } catch (e) {
      // do nothing
    }
  }

  // Start periodic position saving
  void _startPositionSaver() {
    _positionSaveTimer?.cancel();
    _positionSaveTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _saveCurrentPosition(),
    );
  }

  // Stop and save position
  Future<void> _stopPositionSaver() async {
    _positionSaveTimer?.cancel();
    await _saveCurrentPosition();
  }

  /// load media file from url
  Future<void> loadVideoFromUrl(VideoOrAudioItem media,
      {bool play = true}) async {
    // Save position of previous video before switching
    await _saveCurrentPosition();

    // if (currentVideo.value?.location == media.location) return;
    currentVideoUrl.value = media.location;
    currentVideo.value = media;
    ControlsController.to.resetVideoProgress();

    // Load bookmarks for new video
    BookmarkController.to.loadBookmarksForVideo(media.location);

    // Auto-load PBF file if exists
    await ABLoopController.to.autoLoadPBFForVideo(media.location);

    VolumeController.to.currentVolume.value =
        VolumeController.to.currentVolume.value == 0
            ? RpSizes.defaultVolume
            : VolumeController.to.currentVolume.value;

    final windowSize = await RpDeviceUtils.getWindowFrameSize();
    if (windowSize.height == RpSizes.initialAppWindowSize.height &&
        windowSize.width == RpSizes.initialAppWindowSize.width) {
      await RpDeviceUtils.setWindowFrameSize(
          RpSizes.initialVideoLoadedAppWidowSize);
    }

    /// Add media streams to gather info
    addMediaStreamsForInfo();
    await SubtitleController.to.resetTracksForNewMedia();
    await videoPlayerController.player.open(Media(media.location));
    await VolumeController.to.ensureVolume();

    // Restore saved position (wait a bit for player to be ready)
    final savedPosition = _getSavedPosition(media.location);
    if (savedPosition != null && savedPosition > 5) {
      // Small delay to ensure player is ready
      await Future.delayed(const Duration(milliseconds: 100));
      await videoPlayerController.player.seek(Duration(seconds: savedPosition));
    }

    if (!SubtitleController.to.isSubtitleEnabled.value) {
      await SubtitleController.to.disableSubtitle();
    }

    if (play) {
      await videoPlayerController.player.play();
    } else {
      await videoPlayerController.player.pause();
    }

    // Start saving position periodically
    _startPositionSaver();
  }

  void addMediaStreamsForInfo() {
    /// playing listener
    player.stream.playing.listen((playing) {
      isVideoPlaying.value = playing;
    });

    /// duration listener
    player.stream.duration.listen((duration) {
      ControlsController.to.videoDuration.value = duration;
    });

    /// current video position listener
    player.stream.position.listen((position) {
      ControlsController.to.videoPosition.value = position;
      ControlsController.to.updateProgressFromPosition();
    });

    /// current video completion status
    player.stream.completed.listen((isCompleted) async {
      if (isCompleted && !isVideoCompleted.value) {
        isVideoCompleted.value = true;

        // Clear saved position when video completes
        final video = currentVideo.value;
        if (video != null) {
          final positions =
              storage.readData<Map>(RpKeysConstants.videoPositionsKey) ?? {};
          positions.remove(video.location);
          await storage.saveData(RpKeysConstants.videoPositionsKey, positions);
        }

        // Check if there's a next item in the playlist
        final currentVideoIndex = AlbumContentController.to.getIndexOfCurrentItemInPlaylist();
        final hasNextItem = currentVideoIndex != -1 && 
                           currentVideoIndex + 1 < AlbumContentController.to.currentContent.length;

        if (hasNextItem) {
          // Play next item
          await AlbumContentController.to.goNextItemInPlaylist();
        } else {
          final behavior = SettingsController.to.settings.playlistEndBehavior;
          if (behavior == PlaylistEndBehavior.showHomeScreen) {
            // Clear the video to show home screen
            currentVideoUrl.value = '';
            currentVideo.value = null;
          } else if (behavior == PlaylistEndBehavior.shutdown) {
            // Close the application
            WindowActionsController.to.closeWindow();
          }
        }
        
        isVideoCompleted.value = false;
      }
    });
  }

  Future<void> handleCommandLineArgs(List<String> args) async {
    if (args.isEmpty) return;

    String filePath = args.first.trim();
    ControlsController.to.resetPlayer();

    if (filePath.isNotEmpty) {
      try {
        final media = VideoOrAudioItem(
          filePath.split('/').last,
          filePath,
        );

        await AlbumController.to.setDefaultAlbum(
          filePath,
          currentItemToPlay: filePath,
        );
        await AlbumController.to.dumpAllAlbumsToStorage();

        final playlistItem = PlaylistItem(
          name: filePath.split('/').last,
          location: filePath,
          isDirectory: await FileSystemEntity.isDirectory(filePath),
          type: RpMediaHelper.getPlaylistItemType(filePath),
        );

        final shouldClear = SettingsController.to.settings.playlistLoadBehavior == 
                            PlaylistLoadBehavior.clearAndReplace;
        AlbumContentController.to
            .addItemsToPlaylistContent([playlistItem], clearBefore: shouldClear);

        await loadVideoFromUrl(media);
        WindowActionsController.to.maximizeWindow();
      } catch (e) {
        DeveloperLogController.to.log("Error handling file: $e");
      }
    }
  }
}
