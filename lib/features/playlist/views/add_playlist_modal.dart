import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rein_player/features/playlist/controller/playlist_controller.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';

import 'package:rein_player/utils/constants/rp_sizes.dart';



class RpAddPlaylistModal extends StatelessWidget {
  const RpAddPlaylistModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// title and close
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                  LocaleKeys.playlistAddNewPlaylist.tr,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    PlaylistController.to.clearForm();
                    Get.back();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            /// Playlist Name Field
            GestureDetector(
              onTap: () {
                PlaylistController.to.playlistNameFocusNode.requestFocus();
              },
              child: SizedBox(
                height: RpSizes.textInputSize,
                child: TextField(
                  controller: PlaylistController.to.playlistNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.normal),
                  focusNode: PlaylistController.to.playlistNameFocusNode,
                  decoration: InputDecoration(
                    labelText: LocaleKeys.playlistName.tr,
                    labelStyle: TextStyle(color: RpColors.black_600, fontSize: 12),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: RpColors.black_500),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// Folder Selection
            Row(
              children: [
                Expanded(
                  child: Obx(() => Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: RpColors.black_500),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      PlaylistController.to.selectedFolderPath.value.isEmpty
                          ? LocaleKeys.playlistNoFolderSelected.tr
                          : PlaylistController.to.selectedFolderPath.value,
                      style: Theme.of(context).textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: PlaylistController.to.pickFolder,
                  icon: const Icon(Icons.folder_open),
                  label: Text(LocaleKeys.playlistBrowse.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RpColors.black_600,
                    textStyle: const TextStyle(fontSize: 12)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            /// Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    PlaylistController.to.clearForm();
                    Get.back();
                  },
                  child: Text(
                    LocaleKeys.cancel.tr,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: PlaylistController.to.createNewPlaylist,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RpColors.accent,
                  ),
                  child: Text(LocaleKeys.playlistCreatePlaylist.tr, style: Theme.of(context).textTheme.labelLarge!.copyWith(color: Colors.black),),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
