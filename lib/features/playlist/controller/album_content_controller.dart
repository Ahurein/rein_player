import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as path;
import 'package:rein_player/features/playback/controller/controls_controller.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/playlist/controller/album_controller.dart';
import 'package:rein_player/features/playlist/controller/playlist_controller.dart';
import 'package:rein_player/features/playlist/models/playlist_item.dart';
import 'package:rein_player/utils/constants/rp_extensions.dart';
import 'package:rein_player/utils/extensions/media_extensions.dart';
import 'package:rein_player/utils/helpers/duration_helper.dart';
import 'package:rein_player/utils/helpers/media_helper.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';

class AlbumContentController extends GetxController {
  static AlbumContentController get to => Get.find();

  final RxList<PlaylistItem> currentContent = <PlaylistItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool canNavigateBack = false.obs;

  final List<String> _navigationStack = [];

  // Keyboard navigation properties
  // -1 means no selection
  final RxInt selectedIndex = (-1).obs;
  final RxInt lastNavigationIndex = (-1).obs;
  final RxBool isKeyboardNavigating = false.obs;
  final ScrollController scrollController = ScrollController();
  Timer? _selectionTimer;

  Future<void> loadDirectory(String dirPath, {navDirection = "down"}) async {
    try {
      final List<PlaylistItem> mediaFiles =
          await RpMediaHelper.getMediaFilesInDirectory(dirPath);

      if (navDirection == "down") {
        _navigationStack.add(dirPath);
      }

      currentContent.value = mediaFiles;
      
      loadDurationsInBackground();
      _initializeNavigationPosition();
    } finally {
      canNavigateBack.value = canNavigationStackBack();
    }
  }

  void clearContent() {
    currentContent.clear();
  }

  void addToCurrentPlaylistContent(PlaylistItem item) {
    if (currentContent.any((el) => el.location.trim() == item.location)) return;
    currentContent.add(item);
  }

  void addItemsToPlaylistContent(List<PlaylistItem> items,
      {clearBefore = false}) {
    if (items.isEmpty) return;
    if (clearBefore) {
      currentContent.clear();
      // Reset navigation when clearing content
      lastNavigationIndex.value = -1;
      selectedIndex.value = -1;
    }
    currentContent.addAll(items);
    
    loadDurationsInBackground();

    // Initialize position after adding items
    _initializeNavigationPosition();
  }

  void navigateBack() {
    if (_navigationStack.length > 1) {
      _navigationStack.removeLast();
      canNavigateBack.value = canNavigationStackBack();
      loadDirectory(_navigationStack.last, navDirection: "up");
    }
  }

  bool canNavigationStackBack() {
    return _navigationStack.length > 1;
  }

  void addToNavigationStack(String path) {
    if (path.isEmpty) return;
    _navigationStack.add(path);
  }

  void clearNavigationStack() {
    _navigationStack.clear();
  }

  bool isMediaFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase().trim();
    return RpFileExtensions.mediaFileExtensions.contains(extension);
  }

  void handleItemOnTap(PlaylistItem media) async {
    if (media.isDirectory) {
      loadDirectory(media.location);
    } else if (isMediaFile(media.location)) {
      AlbumController.to.updateAlbumCurrentItemToPlay(media.location);
      await AlbumController.to.dumpAllAlbumsToStorage();
      await VideoAndControlController.to
          .loadVideoFromUrl(media.toVideoOrAudioItem());
    }
  }

  //TODO: complete it to show time on watched videos
  void updatePlaylistItemDuration(String url) {
    for (var item in currentContent) {
      if (item.location == url) {
        item.duration.value = RpDurationHelper.formatDurationAuto(
            ControlsController.to.videoDuration.value);
        break;
      }
    }
  }

  Future<Duration?> _extractVideoDuration(String filePath) async {
    try {
      // Create a temporary player instance to extract metadata
      final tempPlayer = Player();
      await tempPlayer.open(Media(filePath));
      
      // Wait for duration to be available (with timeout)
      Duration? duration;
      final completer = Completer<Duration?>();
      
      final subscription = tempPlayer.stream.duration.listen((d) {
        if (d != Duration.zero) {
          completer.complete(d);
        }
      });
      
      // Timeout after 2 seconds
      duration = await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      
      subscription.cancel();
      await tempPlayer.dispose();
      
      return duration;
    } catch (e) {
      return null;
    }
  }

  String adjustTitleOnPlaylistSidebarSize(String title) {
    final sidebarWidth = PlaylistController.to.playlistWindowWidth.value;
    final adjustedWidth = (sidebarWidth * 1).round();
    const averageCharWidth = 8;
    final maxChars = (adjustedWidth / averageCharWidth).floor();
    if (title.length > maxChars) {
      return '${title.substring(0, maxChars)}...';
    }
    return title;
  }

  int getIndexOfCurrentItemInPlaylist() {
    final currentVideo = VideoAndControlController.to.currentVideo.value;
    if (currentContent.isEmpty || currentVideo == null) return -1;
    return currentContent
        .indexWhere((item) => item.location == currentVideo.location);
  }

  String getPlaylistPlayingProgress() {
    if (AlbumContentController.to.currentContent.length == 1) return "";
    final currentVideoIndex = getIndexOfCurrentItemInPlaylist();
    if (currentVideoIndex == -1) return "";
    return "[${currentVideoIndex + 1}/${currentContent.length}]";
  }

  Future<void> goNextItemInPlaylist() async {
    final currentVideoIndex = getIndexOfCurrentItemInPlaylist();
    if (currentVideoIndex == -1 || currentContent.isEmpty) return;
    if (currentVideoIndex + 1 == currentContent.length) return;
    final media = currentContent[currentVideoIndex + 1];
    await VideoAndControlController.to
        .loadVideoFromUrl(media.toVideoOrAudioItem());
    AlbumController.to.updateAlbumCurrentItemToPlay(media.location);
    await AlbumController.to.dumpAllAlbumsToStorage();
  }

  void goPreviousItemInPlaylist() async {
    final currentVideoIndex = getIndexOfCurrentItemInPlaylist();
    if (currentVideoIndex == -1 ||
        currentContent.isEmpty ||
        currentVideoIndex == 0) {
      return;
    }
    final media = currentContent[currentVideoIndex - 1];
    VideoAndControlController.to.loadVideoFromUrl(media.toVideoOrAudioItem());
    AlbumController.to.updateAlbumCurrentItemToPlay(media.location);
    await AlbumController.to.dumpAllAlbumsToStorage();
  }

  void sortPlaylistContent() {
    currentContent.sort(RpMediaHelper.sortMediaFiles);
  }

  void shufflePlaylistContent() {
    currentContent.shuffle();
  }

  Future<void> loadDurationsInBackground() async {
    for (var item in currentContent) {
      if (item.isDirectory || item.duration.value.isNotEmpty) continue;
      
      if (isMediaFile(item.location)) {
        final duration = await _extractVideoDuration(item.location);
        if (duration != null) {
          item.duration.value = RpDurationHelper.formatDurationAuto(duration);
        }
      }
    }
  }

  Future<void> loadSimilarContentInDefaultAlbum(String filename, String dirPath,
      {excludeCurrentFile = true}) async {
    final List<PlaylistItem> mediaFiles =
        await RpMediaHelper.getMediaFilesInDirectory(dirPath);
    String fileNameWithoutExtension = filename.split('.').first;

    String substringToMatch;
    if (fileNameWithoutExtension.length > 3) {
      int lengthToTake = (fileNameWithoutExtension.length * 0.3).floor();
      substringToMatch =
          fileNameWithoutExtension.substring(3, 3 + lengthToTake);
    } else {
      substringToMatch = fileNameWithoutExtension.substring(0, 1);
    }

    final relatedMedia = mediaFiles.where((file) {
      String otherFileNameWithoutExtension = file.name.split('.').first;
      if (excludeCurrentFile) {
        return otherFileNameWithoutExtension.contains(substringToMatch) &&
            file.name != filename;
      }
      return otherFileNameWithoutExtension.contains(substringToMatch);
    }).toList();
    addItemsToPlaylistContent(relatedMedia);
  }

  bool isDirectoryInCurrentVideoPath(String directoryPath) {
    final currentVideo = VideoAndControlController.to.currentVideo.value;
    if (currentVideo == null || currentVideo.location.isEmpty) {
      return false;
    }

    final videoDirectoryPath = path.dirname(currentVideo.location);
    final normalizedDirectoryPath = path.normalize(directoryPath);
    final normalizedVideoPath = path.normalize(videoDirectoryPath);

    final isInPath = normalizedVideoPath.startsWith(normalizedDirectoryPath) ||
        normalizedVideoPath == normalizedDirectoryPath;
    return isInPath;
  }

  bool isDirectoryContainsAlbumCurrentItem(String directoryPath) {
    final selectedAlbumIndex = AlbumController.to.selectedAlbumIndex.value;
    if (selectedAlbumIndex >= AlbumController.to.albums.length) return false;

    final currentItemToPlay =
        AlbumController.to.albums[selectedAlbumIndex].currentItemToPlay;

    if (currentItemToPlay.isEmpty) {
      return false;
    }

    final itemDirectoryPath = path.dirname(currentItemToPlay);
    final normalizedDirectoryPath = path.normalize(directoryPath);
    final normalizedItemPath = path.normalize(itemDirectoryPath);

    final isInPath = normalizedItemPath.startsWith(normalizedDirectoryPath) ||
        normalizedItemPath == normalizedDirectoryPath;
    return isInPath;
  }

  // Context menu actions
  void removeItemFromPlaylist(PlaylistItem item) {
    currentContent.removeWhere((media) => media.location == item.location);
  }

  Future<bool> deleteItemFromDisk(PlaylistItem item) async {
    try {
      final file = File(item.location);
      if (await file.exists()) {
        await file.delete();
        // Also remove from playlist after deletion
        removeItemFromPlaylist(item);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> playItem(PlaylistItem item) async {
    if (item.isDirectory) {
      loadDirectory(item.location);
    } else if (isMediaFile(item.location)) {
      AlbumController.to.updateAlbumCurrentItemToPlay(item.location);
      await AlbumController.to.dumpAllAlbumsToStorage();
      await VideoAndControlController.to
          .loadVideoFromUrl(item.toVideoOrAudioItem());
    }
  }

  Future<Map<String, dynamic>> getFileProperties(PlaylistItem item) async {
    try {
      final file = File(item.location);
      if (!await file.exists()) {
        return {'error': LocaleKeys.albumFileNotFound.tr};
      }

      final stat = await file.stat();
      final fileSize = stat.size;
      final modified = stat.modified;
      final extension =
          path.extension(item.location).toUpperCase().replaceAll('.', '');

      // Format file size
      String formatFileSize(int bytes) {
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024) {
          return '${(bytes / 1024).toStringAsFixed(2)} KB';
        }
        if (bytes < 1024 * 1024 * 1024) {
          return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
        }
        return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
      }

      return {
        'name': item.name,
        'path': item.location,
        'size': formatFileSize(fileSize),
        'format': extension,
        'modified': modified.toString().split('.')[0],
        'directory': path.dirname(item.location),
      };
    } catch (e) {
      return {'error': LocaleKeys.albumFailedGetProperties.tr};
    }
  }

  void showInFileExplorer(String filePath) async {
    try {
      final directory = path.dirname(filePath);
      // Use platform-specific commands
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', filePath]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', filePath]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [directory]);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<bool> deleteCurrentItemAndSkip() async {
    try {
      final currentVideo = VideoAndControlController.to.currentVideo.value;
      if (currentVideo == null) return false;

      final currentIndex = currentContent.indexWhere(
        (item) => item.location == currentVideo.location,
      );

      if (currentIndex == -1) return false;

      final itemToDelete = currentContent[currentIndex];

      final hasNext = currentIndex + 1 < currentContent.length;

      if (hasNext) {
        final nextItem = currentContent[currentIndex + 1];
        await VideoAndControlController.to
            .loadVideoFromUrl(nextItem.toVideoOrAudioItem());
        AlbumController.to.updateAlbumCurrentItemToPlay(nextItem.location);
        await AlbumController.to.dumpAllAlbumsToStorage();
      }

      final file = File(itemToDelete.location);
      if (await file.exists()) {
        await file.delete();
        removeItemFromPlaylist(itemToDelete);
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Keyboard navigation methods
  void selectNextItem() {
    if (currentContent.isEmpty) return;

    // If no current selection, start from last known position
    if (selectedIndex.value == -1) {
      selectedIndex.value =
          lastNavigationIndex.value >= 0 ? lastNavigationIndex.value : 0;
    }

    if (selectedIndex.value < (currentContent.length - 1)) {
      selectedIndex.value++;
      lastNavigationIndex.value = selectedIndex.value; 
      isKeyboardNavigating.value = true;
      _scrollToSelected();
      _resetSelectionTimer();
    }
  }

  void selectPreviousItem() {
    if (currentContent.isEmpty) return;

    // If no current selection, start from last known position
    if (selectedIndex.value == -1) {
      selectedIndex.value =
          lastNavigationIndex.value >= 0 ? lastNavigationIndex.value : 0;
    }

    if (selectedIndex.value > 0) {
      selectedIndex.value--;
      lastNavigationIndex.value = selectedIndex.value;
      isKeyboardNavigating.value = true;
      _scrollToSelected();
      _resetSelectionTimer();
    }
  }

  void playSelectedItem() {
    if (selectedIndex.value >= 0 &&
        selectedIndex.value < currentContent.length) {
      handleItemOnTap(currentContent[selectedIndex.value]);
      _cancelSelectionTimer();
    }
  }

  void selectCurrentPlayingItem() {
    // Find and select the currently playing video
    final currentUrl = VideoAndControlController.to.currentVideoUrl.value;
    if (currentUrl.isNotEmpty) {
      final index =
          currentContent.indexWhere((item) => item.location == currentUrl);
      if (index >= 0) {
        selectedIndex.value = index;
        _scrollToSelected();
        _resetSelectionTimer();
      } else {
        // Fallback to first item if current video not found in list
        if (currentContent.isNotEmpty) {
          selectedIndex.value = 0;
          _resetSelectionTimer();
        }
      }
    } else if (currentContent.isNotEmpty) {
      selectedIndex.value = 0;
      _resetSelectionTimer();
    }
  }

  void _initializeNavigationPosition() {
    // Find current playing video index
    final currentUrl = VideoAndControlController.to.currentVideoUrl.value;
    if (currentUrl.isNotEmpty) {
      final index =
          currentContent.indexWhere((item) => item.location == currentUrl);
      if (index >= 0) {
        lastNavigationIndex.value = index;
      } else if (currentContent.isNotEmpty) {
        lastNavigationIndex.value = 0;
      }
    } else if (currentContent.isNotEmpty) {
      lastNavigationIndex.value = 0;
    }
  }

  void _resetSelectionTimer() {
    _cancelSelectionTimer();
    _selectionTimer = Timer(const Duration(seconds: 3), () {
      selectedIndex.value = -1;
      isKeyboardNavigating.value = false;
    });
  }

  void _cancelSelectionTimer() {
    _selectionTimer?.cancel();
    _selectionTimer = null;
  }

  void _scrollToSelected() {
    if (selectedIndex.value < 0 || !scrollController.hasClients) return;

    // Calculate approximate item height
    const double itemHeight = 30.0;
    final double targetOffset = selectedIndex.value * itemHeight;

    // Get viewport dimensions
    final double viewportHeight = scrollController.position.viewportDimension;
    final double currentOffset = scrollController.offset;

    // Check if item is already visible
    if (targetOffset < currentOffset ||
        targetOffset > currentOffset + viewportHeight - itemHeight) {
      // Scroll to make the item visible with some padding
      scrollController.animateTo(
        targetOffset - (viewportHeight / 2) + (itemHeight / 2),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void onClose() {
    _cancelSelectionTimer();
    scrollController.dispose();
    super.onClose();
  }
}
