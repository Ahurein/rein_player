import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:get/get.dart';
import 'package:rein_player/common/widgets/rp_dialog.dart';
import 'package:rein_player/common/widgets/rp_snackbar.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/player_frame/controller/navigation_context_controller.dart';
import 'package:rein_player/features/playlist/controller/album_controller.dart';
import 'package:rein_player/features/playlist/controller/playlist_controller.dart';
import 'package:rein_player/features/playlist/models/playlist_item.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/device/rp_device_utils.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';
import 'package:rein_player/utils/localization/tr_args.dart';

import '../controller/album_content_controller.dart';

class AlbumContent extends StatelessWidget {
  const AlbumContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isHovered = false.obs;

    return Column(
      children: [
        /// folder back navigation
        Obx(() {
          if (!AlbumContentController.to.canNavigateBack.value) {
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: AlbumContentController.to.navigateBack,
            child: MouseRegion(
              onEnter: (_) => isHovered.value = true,
              onExit: (_) => isHovered.value = false,
              cursor: SystemMouseCursors.click,
              child: Obx(() {
                return Container(
                  padding: const EdgeInsets.only(left: 7),
                  color: isHovered.value
                      ? RpColors.gray_900.withValues(alpha: 0.2)
                      : Colors.transparent,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.folder,
                        color: Colors.amber,
                        size: 15,
                      ),
                      SizedBox(width: 5),
                      Text("..."),
                    ],
                  ),
                );
              }),
            ),
          );
        }),

        /// playlist items
        const Expanded(child: RpAlbumItems()),
      ],
    );
  }
}

class RpAlbumItems extends StatelessWidget {
  const RpAlbumItems({super.key});

  ContextMenu _createItemContextMenu(PlaylistItem media, BuildContext context) {
    return ContextMenu(
      entries: <ContextMenuEntry>[
        MenuItem(
          label: LocaleKeys.albumPlay.tr,
          icon: Icons.play_arrow,
          onSelected: () async {
            await AlbumContentController.to.playItem(media);
          },
        ),
        const MenuDivider(),
        MenuItem(
          label: RpDeviceUtils.isMacOS()
              ? LocaleKeys.albumShowInFinder.tr
              : LocaleKeys.albumShowInExplorer.tr,
          icon: Icons.folder_open,
          onSelected: () {
            AlbumContentController.to.showInFileExplorer(media.location);
          },
        ),
        MenuItem(
          label: LocaleKeys.albumCopyFilePath.tr,
          icon: Icons.copy,
          onSelected: () {
            Clipboard.setData(ClipboardData(text: media.location));
            RpSnackbar.copied(item: LocaleKeys.albumFilePath.tr);
          },
        ),
        MenuItem(
          label: LocaleKeys.albumFileProperties.tr,
          icon: Icons.info_outline,
          onSelected: () async {
            await _showFileProperties(context, media);
          },
        ),
        const MenuDivider(),
        MenuItem(
          label: LocaleKeys.albumRemoveFromPlaylist.tr,
          icon: Icons.playlist_remove,
          onSelected: () {
            AlbumContentController.to.removeItemFromPlaylist(media);
          },
        ),
        MenuItem(
          label: LocaleKeys.albumDeleteFromDisk.tr,
          icon: Icons.delete_forever,
          onSelected: () async {
            // Show confirmation dialog
            final confirmed = await RpDialog.showConfirmation(
              context: context,
              title: LocaleKeys.dialogDeleteFileTitle.tr,
              message: LocaleKeys.dialogDeleteFileMessage.trArgs([media.name]),
              confirmText: LocaleKeys.delete.tr,
              confirmColor: Colors.red,
              titleIcon: const Icon(Icons.delete_forever, color: Colors.red),
            );

            if (confirmed == true) {
              final currentVideo =
                  VideoAndControlController.to.currentVideo.value;
              final isCurrentlyPlaying =
                  currentVideo?.location == media.location;

              bool success;
              if (isCurrentlyPlaying) {
                success =
                    await AlbumContentController.to.deleteCurrentItemAndSkip();
              } else {
                success =
                    await AlbumContentController.to.deleteItemFromDisk(media);
              }

              if (!success) {
                RpSnackbar.error(message: LocaleKeys.snackFailedDeleteFile.tr);
              } else {
                RpSnackbar.success(
                  title: LocaleKeys.snackDeleted.tr,
                  message: isCurrentlyPlaying
                      ? LocaleKeys.snackDeletedAndSkipped.tr
                      : LocaleKeys.snackDeletedSuccessfully.tr,
                );
              }
            }
          },
        ),
      ],
      boxDecoration: BoxDecoration(
        color: RpColors.gray_900,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: RpColors.black_600),
      ),
      padding: const EdgeInsets.all(4),
    );
  }

  Future<void> _showFileProperties(
      BuildContext context, PlaylistItem media) async {
    final properties = await AlbumContentController.to.getFileProperties(media);

    if (!context.mounted) return;

    if (properties.containsKey('error')) {
      RpSnackbar.error(message: properties['error']);
      return;
    }

    return RpDialog.showInfo(
      context: context,
      title: LocaleKeys.albumFileProperties.tr,
      titleIcon: const Icon(Icons.info_outline, color: RpColors.accent),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPropertyRow(LocaleKeys.albumName.tr, properties['name']),
          const SizedBox(height: 8),
          _buildPropertyRow(LocaleKeys.albumFormat.tr, properties['format']),
          const SizedBox(height: 8),
          _buildPropertyRow(LocaleKeys.albumSize.tr, properties['size']),
          const SizedBox(height: 8),
          _buildPropertyRow(LocaleKeys.albumModified.tr,
              properties['modified']),
          const SizedBox(height: 8),
          _buildPropertyRow(
              LocaleKeys.albumLocation.tr, properties['directory'],
              isPath: true),
        ],
      ),
    );
  }

  Widget _buildPropertyRow(String label, String? value, {bool isPath = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: RpColors.accent,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value ?? LocaleKeys.albumNa.tr,
          style: const TextStyle(
            color: RpColors.black_300,
            fontSize: 12,
          ),
          maxLines: isPath ? 3 : 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AlbumContentController.to;
    
    return Obx(() {
      return ListView.builder(
        controller: controller.scrollController,
        itemCount: controller.currentContent.length,
        itemBuilder: (context, index) {
          final media = controller.currentContent[index];
          final isHovered = false.obs;

          return Obx(() {
            final isSelected = controller.selectedIndex.value == index;
            
            return ContextMenuRegion(
              contextMenu: _createItemContextMenu(media, context),
              child: GestureDetector(
                onTap: () {
                  controller.selectedIndex.value = index;
                  // Update persistent position
                  controller.lastNavigationIndex.value = index;
                  NavigationContextController.to.switchToPlaylist();
                },
                onDoubleTap: () =>
                    controller.handleItemOnTap(media),
                child: MouseRegion(
                  onEnter: (_) => isHovered.value = true,
                  onExit: (_) => isHovered.value = false,
                  cursor: SystemMouseCursors.click,
                  child: Obx(() {
                    final isCurrentPlayingMedia = VideoAndControlController
                            .to.currentVideo.value?.location ==
                        media.location;
                    final isAlbumCurrentItemToPlay = AlbumController
                            .to
                            .albums[AlbumController.to.selectedAlbumIndex.value]
                            .currentItemToPlay ==
                        media.location;

                    final isDirectoryInVideoPath = media.isDirectory &&
                    controller.isDirectoryInCurrentVideoPath(media.location);

                    // Also check if this directory contains the album's current item to play
                    final isDirectoryContainsCurrentItem = media.isDirectory &&
                    controller.isDirectoryContainsAlbumCurrentItem(media.location);

                    return Row(
                      children: [
                        const SizedBox(width: 5),
                        Icon(
                          media.isDirectory ? Icons.folder : Icons.video_file,
                          color: (isCurrentPlayingMedia ||
                                  isHovered.value ||
                                  isSelected ||
                                  media.isDirectory ||
                                  isAlbumCurrentItemToPlay ||
                                  isDirectoryInVideoPath ||
                                  isDirectoryContainsCurrentItem)
                              ? RpColors.accent
                              : Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 5),

                        /// Title
                        Expanded(
                          child: Text(
                            "${index + 1}. ${media.name}",
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: (isCurrentPlayingMedia ||
                                              isHovered.value ||
                                              isSelected ||
                                              isAlbumCurrentItemToPlay ||
                                              isDirectoryInVideoPath ||
                                              isDirectoryContainsCurrentItem)
                                          ? RpColors.accent
                                          : RpColors.black_300,
                                    ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),

                        /// video duration
                        Obx(() {
                          final durationText = media.duration.value;
                          if (durationText.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8),
                            child: Text(
                              durationText,
                              style: TextStyle(
                                color: (isCurrentPlayingMedia ||
                                        isHovered.value ||
                                        isAlbumCurrentItemToPlay ||
                                        isDirectoryInVideoPath ||
                                        isDirectoryContainsCurrentItem)
                                    ? RpColors.accent
                                    : RpColors.black_300,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 5),
                      ],
                    );
                  }),
                ),
              ),
            );
          });
        },
      );
    });
  }
}
