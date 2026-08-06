import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rein_player/common/widgets/rp_snackbar.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/playlist/controller/album_controller.dart';
import 'package:rein_player/features/playlist/models/album.dart';
import 'package:rein_player/utils/constants/rp_sizes.dart';
import 'package:rein_player/utils/local_storage/rp_local_storage.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';
import 'package:window_manager/window_manager.dart';

import '../views/add_playlist_modal.dart';

class PlaylistController extends GetxController {
  static PlaylistController get to => Get.find();

  final storage = RpLocalStorage();

  final isPlaylistWindowOpened = false.obs;
  Rx<double> playlistWindowWidth = RpSizes.minPlaylistWindowSize.obs;

  /// add playlist
  final playlistNameController = TextEditingController();
  final RxString selectedFolderPath = "".obs;
  final FocusNode playlistNameFocusNode = FocusNode();

  void togglePlaylistWindow() {
    // Toggle immediately for instant UI feedback
    final wasOpened = isPlaylistWindowOpened.value;
    isPlaylistWindowOpened.value = !wasOpened;

    // Resize window in background without blocking UI
    _resizeWindowForPlaylist(wasOpened);
  }

  Future<void> _resizeWindowForPlaylist(bool wasOpened) async {
    final isMaximized = await windowManager.isMaximized();
    
    // If maximized, don't resize - let the layout handle it
    if (isMaximized) {
      return;
    }
    
    // If not maximized, resize the window
    final currentSize = await windowManager.getSize();
    
    if (wasOpened) {
      // Closing playlist - subtract playlist width
      await windowManager.setSize(Size(
          currentSize.width - playlistWindowWidth.value, currentSize.height));
    } else {
      // Opening playlist - add playlist width
      final newWidth = currentSize.width + playlistWindowWidth.value;
      await windowManager.setSize(Size(newWidth, currentSize.height));
    }
  }

  void updatePlaylistWindowSizeOnDrag(DragUpdateDetails details) {
    final dx = details.delta.dx;
    final videoAndControlScreenSize =
        VideoAndControlController.to.videoAndControlScreenSize.value;

    if (dx > 0 && playlistWindowWidth.value > RpSizes.minPlaylistWindowSize) {
      playlistWindowWidth.value -= dx;
    } else if (dx < 0 &&
        videoAndControlScreenSize > RpSizes.minWindowAndControlScreenSize) {
      playlistWindowWidth.value -= dx;
    }
  }

  Future<void> showAddPlaylistModal() {
    return Get.dialog(const RpAddPlaylistModal(), barrierDismissible: false);
  }

  Future<void> pickFolder() async {
    String? folderPath = await FilePicker.platform.getDirectoryPath();
    selectedFolderPath.value = folderPath ?? "";
  }

  void createNewPlaylist() async {
    if (playlistNameController.text.trim().isEmpty ||
        selectedFolderPath.isEmpty) {
      RpSnackbar.error(message: LocaleKeys.snackFillAllFields.tr);
      return;
    }

    if (AlbumController.to.albums
        .any((album) => album.location == selectedFolderPath.value)) {
      RpSnackbar.warning(
        title: LocaleKeys.snackAlreadyAdded.tr,
        message: LocaleKeys.snackAlreadyAddedMsg.tr,
      );
      return;
    }

    AlbumController.to.albums.add(
      Album(
        name: playlistNameController.value.text.trim(),
        location: selectedFolderPath.value,
      ),
    );

    /// dump list to local storage
    AlbumController.to.dumpAllAlbumsToStorage();
    await AlbumController.to
        .updateSelectedAlbumIndex(AlbumController.to.albums.length - 1);
    clearForm();
    Get.back();

    RpSnackbar.success(
      title: LocaleKeys.snackPlaylistCreated.tr,
      message: LocaleKeys.snackPlaylistCreatedMsg.tr,
    );
  }

  void clearForm() {
    playlistNameController.clear();
    selectedFolderPath.value = '';
  }

  @override
  void onClose() {
    playlistNameController.dispose();
    playlistNameFocusNode.dispose();
    super.onClose();
  }
}
