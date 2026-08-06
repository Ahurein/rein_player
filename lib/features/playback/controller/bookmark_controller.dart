import 'package:get/get.dart';
import 'package:rein_player/common/widgets/rp_snackbar.dart';
import 'package:rein_player/features/playback/controller/controls_controller.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/playback/models/video_bookmark.dart';
import 'package:rein_player/utils/constants/rp_keys.dart';
import 'package:rein_player/utils/local_storage/rp_local_storage.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';
import 'package:rein_player/utils/localization/tr_args.dart';

class BookmarkController extends GetxController {
  static BookmarkController get to => Get.find();

  final storage = RpLocalStorage();

  // Current video's bookmarks
  final RxList<VideoBookmark> bookmarks = <VideoBookmark>[].obs;

  // UI visibility
  final isBookmarkOverlayVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load bookmarks when controller initializes
    final currentVideo = VideoAndControlController.to.currentVideo.value;
    if (currentVideo != null) {
      loadBookmarksForVideo(currentVideo.location);
    }
  }

  /// Add a bookmark at the current playback position
  Future<void> addBookmark({String? customName}) async {
    try {
      final video = VideoAndControlController.to.currentVideo.value;
      final position = ControlsController.to.videoPosition.value;

      if (video == null) {
        RpSnackbar.warning(
          message: LocaleKeys.noVideoPlaying.tr,
        );
        return;
      }

      if (position == null) {
        RpSnackbar.warning(
          message: LocaleKeys.snackUnableGetPosition.tr,
        );
        return;
      }

      final timestamp = position.inSeconds;

      // Check if bookmark already exists at this exact timestamp
      final existingBookmark = bookmarks.firstWhereOrNull(
        (b) => b.timestamp == timestamp,
      );

      if (existingBookmark != null) {
        RpSnackbar.info(
          message: LocaleKeys.snackBookmarkExists
              .trArgs([existingBookmark.formattedTimestamp]),
        );
        return;
      }

      // Create new bookmark
      final bookmark = VideoBookmark(
        timestamp: timestamp,
        name: customName ?? '',
      );

      // Add to current list
      bookmarks.add(bookmark);

      bookmarks.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      await _saveBookmarksToStorage(video.location);

      RpSnackbar.success(
        title: LocaleKeys.snackBookmarkAdded.tr,
        message:
            LocaleKeys.snackBookmarkAddedMsg.trArgs([bookmark.formattedTimestamp]),
      );
    } catch (e) {
      RpSnackbar.error(
        message: LocaleKeys.snackFailedAddBookmark.tr,
      );
    }
  }

  /// Delete a bookmark by index
  Future<void> deleteBookmark(int index) async {
    try {
      if (index < 0 || index >= bookmarks.length) return;

      final bookmark = bookmarks[index];
      bookmarks.removeAt(index);

      final video = VideoAndControlController.to.currentVideo.value;
      if (video != null) {
        await _saveBookmarksToStorage(video.location);
      }

      RpSnackbar.success(
        title: LocaleKeys.snackBookmarkDeleted.tr,
        message: LocaleKeys.snackBookmarkDeletedMsg
            .trArgs([bookmark.formattedTimestamp]),
      );
    } catch (e) {
      RpSnackbar.error(
        message: LocaleKeys.snackFailedDeleteBookmark.tr,
      );
    }
  }

  /// Update bookmark name
  Future<void> updateBookmarkName(int index, String name) async {
    try {
      if (index < 0 || index >= bookmarks.length) return;

      final oldBookmark = bookmarks[index];
      bookmarks[index] = oldBookmark.copyWith(name: name);

      final video = VideoAndControlController.to.currentVideo.value;
      if (video != null) {
        await _saveBookmarksToStorage(video.location);
      }
    } catch (e) {
      RpSnackbar.error(
        message: LocaleKeys.snackFailedUpdateBookmarkName.tr,
      );
    }
  }

  /// Load bookmarks for a specific video
  void loadBookmarksForVideo(String videoPath) {
    try {
      final allBookmarks = storage.readData<Map>(RpKeysConstants.videoBookmarksKey);
      if (allBookmarks == null) {
        bookmarks.clear();
        return;
      }

      final videoBookmarks = allBookmarks[videoPath] as List?;
      if (videoBookmarks == null || videoBookmarks.isEmpty) {
        bookmarks.clear();
        return;
      }

      // Parse bookmarks from JSON
      final parsedBookmarks = videoBookmarks
          .map((json) => VideoBookmark.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by timestamp
      parsedBookmarks.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      bookmarks.value = parsedBookmarks;
    } catch (e) {
      bookmarks.clear();
    }
  }

  /// Jump to the next bookmark
  Future<void> jumpToNextBookmark() async {
    if (bookmarks.isEmpty) {
      RpSnackbar.info(
        message: LocaleKeys.snackNoBookmarksAvailable.tr,
      );
      return;
    }

    final currentPosition = ControlsController.to.videoPosition.value?.inSeconds ?? 0;

    // Find the next bookmark after current position
    VideoBookmark? nextBookmark;

    for (int i = 0; i < bookmarks.length; i++) {
      if (bookmarks[i].timestamp > currentPosition) {
        nextBookmark = bookmarks[i];
        break;
      }
    }

    // If no bookmark found after current position, wrap to first
    if (nextBookmark == null) {
      nextBookmark = bookmarks.first;
      RpSnackbar.info(
        message: LocaleKeys.snackJumpedFirstBookmark
            .trArgs([nextBookmark.formattedTimestamp]),
      );
    } else {
      RpSnackbar.info(
        message: LocaleKeys.snackJumpedBookmark
            .trArgs([nextBookmark.formattedTimestamp]),
      );
    }

    await _jumpToTimestamp(nextBookmark.timestamp);
  }

  /// Jump to the previous bookmark
  Future<void> jumpToPreviousBookmark() async {
    if (bookmarks.isEmpty) {
      RpSnackbar.info(
        message: LocaleKeys.snackNoBookmarksAvailable.tr,
      );
      return;
    }

    final currentPosition = ControlsController.to.videoPosition.value?.inSeconds ?? 0;

    // Find the previous bookmark before current position
    VideoBookmark? prevBookmark;

    for (int i = bookmarks.length - 1; i >= 0; i--) {
      if (bookmarks[i].timestamp < currentPosition - 2) { // 2 second buffer
        prevBookmark = bookmarks[i];
        break;
      }
    }

    // If no bookmark found before current position, wrap to last
    if (prevBookmark == null) {
      prevBookmark = bookmarks.last;
      RpSnackbar.info(
        message: LocaleKeys.snackJumpedLastBookmark
            .trArgs([prevBookmark.formattedTimestamp]),
      );
    } else {
      RpSnackbar.info(
        message: LocaleKeys.snackJumpedBookmark
            .trArgs([prevBookmark.formattedTimestamp]),
      );
    }

    await _jumpToTimestamp(prevBookmark.timestamp);
  }

  /// Jump to a specific bookmark by index
  Future<void> jumpToBookmark(int index) async {
    if (index < 0 || index >= bookmarks.length) return;

    final bookmark = bookmarks[index];
    await _jumpToTimestamp(bookmark.timestamp);

    RpSnackbar.info(
      message: LocaleKeys.snackJumpedToTime.trArgs([bookmark.formattedTimestamp]),
    );
  }

  /// Toggle bookmark overlay visibility
  void toggleBookmarkOverlay() {
    isBookmarkOverlayVisible.value = !isBookmarkOverlayVisible.value;
  }

  /// Clear all bookmarks for a video
  Future<void> clearBookmarksForVideo(String videoPath) async {
    try {
      final allBookmarks = storage.readData<Map>(RpKeysConstants.videoBookmarksKey) ?? {};
      allBookmarks.remove(videoPath);
      await storage.saveData(RpKeysConstants.videoBookmarksKey, allBookmarks);

      // If it's the current video, clear the list
      final currentVideo = VideoAndControlController.to.currentVideo.value;
      if (currentVideo?.location == videoPath) {
        bookmarks.clear();
      }

      RpSnackbar.success(
        title: LocaleKeys.snackBookmarksCleared.tr,
        message: LocaleKeys.snackBookmarksClearedMsg.tr,
      );
    } catch (e) {
      RpSnackbar.error(
        message: LocaleKeys.snackFailedClearBookmarks.tr,
      );
    }
  }

  /// Save bookmarks to storage
  Future<void> _saveBookmarksToStorage(String videoPath) async {
    try {
      final allBookmarks = storage.readData<Map>(RpKeysConstants.videoBookmarksKey) ?? {};
      
      // Convert bookmarks to JSON
      final bookmarksJson = bookmarks.map((b) => b.toJson()).toList();
      
      allBookmarks[videoPath] = bookmarksJson;
      await storage.saveData(RpKeysConstants.videoBookmarksKey, allBookmarks);
    } catch (e) {
      // do nothing
    }
  }

  /// Jump to a specific timestamp in the video
  Future<void> _jumpToTimestamp(int seconds) async {
    final player = VideoAndControlController.to.player;
    await player.seek(Duration(seconds: seconds));
  }
}
