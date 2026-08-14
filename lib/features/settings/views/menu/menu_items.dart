import 'package:flutter/material.dart';
import 'package:flutter_context_menu/flutter_context_menu.dart';
import 'package:media_kit/media_kit.dart';
import 'package:get/get.dart';
import 'package:rein_player/common/widgets/rp_snackbar.dart';
import 'package:rein_player/features/playback/controller/audio_track_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:rein_player/features/playback/controller/ab_loop_controller.dart';
import 'package:rein_player/features/playback/controller/bookmark_controller.dart';
import 'package:rein_player/features/playback/controller/controls_controller.dart';
import 'package:rein_player/features/playback/controller/playlist_type_controller.dart';
import 'package:rein_player/features/playback/controller/subtitle_controller.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/player_frame/controller/window_actions_controller.dart';
import 'package:rein_player/features/playlist/controller/album_content_controller.dart';
import 'package:rein_player/features/settings/controller/settings_controller.dart';
import 'package:rein_player/features/settings/views/menu/menu_item.dart';
import 'package:rein_player/features/settings/views/keyboard_bindings_modal.dart';
import 'package:rein_player/features/settings/views/about_dialog.dart';
import 'package:rein_player/features/settings/views/subtitle_settings_modal.dart';
import 'package:rein_player/features/settings/views/seek_settings_modal.dart';
import 'package:rein_player/utils/constants/rp_enums.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/localization/app_languages.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';

List<RpMenuItem> get defaultMenuData {
  final currentType = PlaylistTypeController.to.playlistType.value;
  final availableAudioTracks = AudioTrackController.to.availableAudioTracks;
  final currentAudioTrack = AudioTrackController.to.currentAudioTrack.value;
  final currentLanguage = SettingsController.to.settings.language;

  return [
    /// Open file
    RpMenuItem(
      text: LocaleKeys.menuOpenFile.tr,
      icon: Icons.file_open,
      onTap: ControlsController.to.open,
    ),

    /// Subtitles
    RpMenuItem(
      text: LocaleKeys.menuSubtitles.tr,
      icon: Icons.subtitles,
      subMenuItems: [
        RpMenuItem(
          icon: Icons.add,
          text: LocaleKeys.menuAddSubtitle.tr,
          onTap: SubtitleController.to.loadSubtitle,
        ),
        RpMenuItem(
          icon: Icons.remove,
          text: LocaleKeys.menuDisableSubtitle.tr,
          onTap: SubtitleController.to.disableSubtitle,
        ),
        RpMenuItem(
          icon: Icons.settings,
          text: LocaleKeys.menuSubtitleSettings.tr,
          onTap: () {
            Get.dialog(const SubtitleSettingsModal());
          },
        ),
      ],
    ),

    /// Audio
    RpMenuItem(
      text: LocaleKeys.menuAudio.tr,
      icon: Icons.audiotrack,
      subMenuItems:
          _buildAudioTrackMenu(availableAudioTracks, currentAudioTrack),
    ),

    // Preferences submenu
    RpMenuItem(
      text: LocaleKeys.menuPreferences.tr,
      icon: Icons.settings,
      subMenuItems: [
        RpMenuItem(
          icon: Icons.keyboard,
          text: LocaleKeys.menuKeyboardBindings.tr,
          onTap: () {
            Get.dialog(const KeyboardBindingsModal());
          },
        ),
        RpMenuItem(
          text: LocaleKeys.menuDoubleClickAction.tr,
          icon: Icons.mouse,
          subMenuItems: [
            RpMenuItem(
              icon: SettingsController.to.settings.doubleClickAction == 
                    DoubleClickAction.toggleWindowSize
                  ? Icons.check
                  : null,
              text: LocaleKeys.menuMaximizeMinimizeWindow.tr,
              onTap: () async {
                await SettingsController.to.updateDoubleClickAction(
                  DoubleClickAction.toggleWindowSize,
                );
              },
            ),
            RpMenuItem(
              icon: SettingsController.to.settings.doubleClickAction == 
                    DoubleClickAction.playPause
                  ? Icons.check
                  : null,
              text: LocaleKeys.menuPlayPauseVideo.tr,
              onTap: () async {
                await SettingsController.to.updateDoubleClickAction(
                  DoubleClickAction.playPause,
                );
              },
            ),
          ],
        ),
        RpMenuItem(
          text: LocaleKeys.menuLanguage.tr,
          icon: Icons.language,
          subMenuItems: [
            for (final language in AppLanguage.values)
              RpMenuItem(
                icon: currentLanguage == language ? Icons.check : null,
                text: language.displayName,
                onTap: () async {
                  await SettingsController.to.updateLanguage(language);
                },
              ),
          ],
        ),
        RpMenuItem(
          icon: Icons.fast_forward,
          text: LocaleKeys.menuSeekIntervals.tr,
          onTap: () {
            final context = Get.context;
            if (context != null) {
              SeekSettingsModal.show(context);
            }
          },
        ),
        RpMenuItem(
          text: LocaleKeys.menuWhenPlaylistEnds.tr,
          icon: Icons.playlist_remove,
          subMenuItems: [
            RpMenuItem(
              icon: SettingsController.to.settings.playlistEndBehavior == 
                    PlaylistEndBehavior.showHomeScreen
                  ? Icons.check
                  : null,
              text: LocaleKeys.menuShowHomeScreen.tr,
              onTap: () async {
                await SettingsController.to.updatePlaylistEndBehavior(
                  PlaylistEndBehavior.showHomeScreen,
                );
                RpSnackbar.success(
                  title: LocaleKeys.snackPlaylistEndBehaviorUpdated.tr,
                  message: LocaleKeys.snackPlaylistEndHomeMsg.tr,
                );
              },
            ),
            RpMenuItem(
              icon: SettingsController.to.settings.playlistEndBehavior == 
                    PlaylistEndBehavior.shutdown
                  ? Icons.check
                  : null,
              text: LocaleKeys.menuShutdownApplication.tr,
              onTap: () async {
                await SettingsController.to.updatePlaylistEndBehavior(
                  PlaylistEndBehavior.shutdown,
                );
                RpSnackbar.success(
                  title: LocaleKeys.snackPlaylistEndBehaviorUpdated.tr,
                  message: LocaleKeys.snackPlaylistEndShutdownMsg.tr,
                );
              },
            ),
          ],
        ),
      ],
    ),

    /// Playlist
    RpMenuItem(
      text: LocaleKeys.menuPlaylist.tr,
      icon: Icons.playlist_play,
      subMenuItems: [
        /// Playlist Type submenu
        RpMenuItem(
          text: LocaleKeys.menuPlaylistType.tr,
          icon: Icons.featured_play_list,
          subMenuItems: [
            RpMenuItem(
              icon: currentType == PlaylistType.defaultPlaylistType
                  ? Icons.check
                  : null,
              text: LocaleKeys.menuDefault.tr,
              onTap: () => PlaylistTypeController.to
                  .changePlaylistType(PlaylistType.defaultPlaylistType),
            ),
            RpMenuItem(
              icon: currentType == PlaylistType.potPlayerPlaylistType
                  ? Icons.check
                  : null,
              text: LocaleKeys.menuPotPlayer.tr,
              onTap: () => PlaylistTypeController.to
                  .changePlaylistType(PlaylistType.potPlayerPlaylistType),
            ),
          ],
        ),

        /// Shuffle Playlist
        RpMenuItem(
          icon: Icons.shuffle,
          text: LocaleKeys.menuShufflePlaylist.tr,
          onTap: () {
            Get.find<AlbumContentController>().shufflePlaylistContent();
            RpSnackbar.success(
              title: LocaleKeys.snackPlaylistShuffled.tr,
              message: LocaleKeys.snackPlaylistShuffledMsg.tr,
            );
          },
        ),

        /// Playlist Load Behavior submenu
        RpMenuItem(
          text: LocaleKeys.menuWhenLoadingFiles.tr,
          icon: Icons.playlist_add,
          subMenuItems: [
            RpMenuItem(
              icon: SettingsController.to.settings.playlistLoadBehavior == 
                    PlaylistLoadBehavior.clearAndReplace
                  ? Icons.check
                  : null,
              text: LocaleKeys.menuClearAndReplacePlaylist.tr,
              onTap: () async {
                await SettingsController.to.updatePlaylistLoadBehavior(
                  PlaylistLoadBehavior.clearAndReplace,
                );
                RpSnackbar.success(
                  title: LocaleKeys.snackPlaylistBehaviorUpdated.tr,
                  message: LocaleKeys.snackPlaylistLoadClearMsg.tr,
                );
              },
            ),
            RpMenuItem(
              icon: SettingsController.to.settings.playlistLoadBehavior == 
                    PlaylistLoadBehavior.appendToExisting
                  ? Icons.check
                  : null,
              text: LocaleKeys.menuAppendToExistingPlaylist.tr,
              onTap: () async {
                await SettingsController.to.updatePlaylistLoadBehavior(
                  PlaylistLoadBehavior.appendToExisting,
                );
                RpSnackbar.success(
                  title: LocaleKeys.snackPlaylistBehaviorUpdated.tr,
                  message: LocaleKeys.snackPlaylistLoadAppendMsg.tr,
                );
              },
            ),
          ],
        ),
      ],
    ),

    /// Bookmarks
    RpMenuItem(
      text: LocaleKeys.menuBookmarks.tr,
      icon: Icons.bookmark,
      subMenuItems: [
        RpMenuItem(
          icon: Icons.bookmark_add,
          text: LocaleKeys.menuAddBookmark.tr,
          onTap: () async {
            await BookmarkController.to.addBookmark();
          },
        ),
        RpMenuItem(
          icon: Icons.bookmark_border,
          text: LocaleKeys.menuShowBookmarks.tr,
          onTap: () {
            BookmarkController.to.toggleBookmarkOverlay();
          },
        ),
        RpMenuItem(
          icon: Icons.skip_next,
          text: LocaleKeys.menuNextBookmark.tr,
          onTap: () async {
            await BookmarkController.to.jumpToNextBookmark();
          },
        ),
        RpMenuItem(
          icon: Icons.skip_previous,
          text: LocaleKeys.menuPreviousBookmark.tr,
          onTap: () async {
            await BookmarkController.to.jumpToPreviousBookmark();
          },
        ),
        RpMenuItem(
          icon: Icons.clear_all,
          text: LocaleKeys.menuClearAllBookmarks.tr,
          onTap: () {
            final video = VideoAndControlController.to.currentVideo.value;
            if (video != null) {
              // Show confirmation dialog before clearing
              Get.dialog(
                Builder(
                  builder: (context) => AlertDialog(
                    backgroundColor: RpColors.gray_900,
                    title: Text(
                      LocaleKeys.dialogClearAllBookmarksTitle.tr,
                      style: const TextStyle(color: RpColors.white),
                    ),
                    content: Text(
                      LocaleKeys.dialogClearAllBookmarksMessage.tr,
                      style: const TextStyle(color: RpColors.white_300),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(LocaleKeys.cancel.tr),
                      ),
                      TextButton(
                        onPressed: () {
                          BookmarkController.to
                              .clearBookmarksForVideo(video.location);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          LocaleKeys.clearAll.tr,
                          style: const TextStyle(color: RpColors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              RpSnackbar.warning(message: LocaleKeys.noVideoPlaying.tr);
            }
          },
        ),
      ],
    ),

    /// A-B Loop Segments
    RpMenuItem(
      text: LocaleKeys.menuAbLoopSegments.tr,
      icon: Icons.repeat,
      subMenuItems: [
        RpMenuItem(
          icon: Icons.add,
          text: LocaleKeys.menuAddSegmentAtCurrentPosition.tr,
          onTap: () async {
            ABLoopController.to.addSegmentAtCurrentPosition();
          },
        ),
        RpMenuItem(
          icon: Icons.list,
          text: LocaleKeys.menuShowSegments.tr,
          onTap: () {
            ABLoopController.to.toggleOverlay();
          },
        ),
        RpMenuItem(
          icon: Icons.play_circle,
          text: LocaleKeys.menuStartStopABLoopPlayback.tr,
          onTap: () {
            ABLoopController.to.toggleABLoopPlayback();
          },
        ),
        RpMenuItem(
          icon: Icons.skip_next,
          text: LocaleKeys.menuNextSegment.tr,
          onTap: () async {
            await ABLoopController.to.jumpToNextSegment();
          },
        ),
        RpMenuItem(
          icon: Icons.skip_previous,
          text: LocaleKeys.menuPreviousSegment.tr,
          onTap: () async {
            await ABLoopController.to.jumpToPreviousSegment();
          },
        ),
        RpMenuItem(
          icon: Icons.file_upload,
          text: LocaleKeys.menuImportPBF.tr,
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pbf'],
            );
            if (result != null && result.files.single.path != null) {
              await ABLoopController.to.importFromPBF(result.files.single.path!);
            }
          },
        ),
        RpMenuItem(
          icon: Icons.file_download,
          text: LocaleKeys.menuExportPBF.tr,
          onTap: () async {
            await ABLoopController.to.exportToPBF();
          },
        ),
        RpMenuItem(
          icon: Icons.clear_all,
          text: LocaleKeys.menuClearAllSegments.tr,
          onTap: () {
            final segments = ABLoopController.to.segments;
            if (segments.isEmpty) {
              RpSnackbar.info(message: LocaleKeys.noSegmentsToClear.tr);
              return;
            }

            // Show confirmation dialog
            Get.dialog(
              Builder(
                builder: (context) => AlertDialog(
                  backgroundColor: RpColors.gray_900,
                  title: Text(
                    LocaleKeys.dialogClearAllSegmentsTitle.tr,
                    style: const TextStyle(color: RpColors.white),
                  ),
                  content: Text(
                    LocaleKeys.dialogClearAllSegmentsMessage.tr,
                    style: const TextStyle(color: RpColors.white_300),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(LocaleKeys.cancel.tr),
                    ),
                    TextButton(
                      onPressed: () {
                        ABLoopController.to.clearSegments();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        LocaleKeys.clearAll.tr,
                        style: const TextStyle(color: RpColors.red),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),

    /// About
    RpMenuItem(
      text: LocaleKeys.menuAbout.tr,
      icon: Icons.info_outline,
      onTap: () {
        Get.dialog(const RpAboutDialog());
      },
    ),

    /// Exit
    RpMenuItem(
      text: LocaleKeys.menuExit.tr,
      icon: Icons.exit_to_app,
      onTap: () {
        WindowActionsController.to.closeWindow();
      },
    ),
  ];
}

List<RpMenuItem> _buildAudioTrackMenu(
    List<AudioTrack> availableAudioTracks, AudioTrack? currentAudioTrack) {
  List<RpMenuItem> audioMenuItems = [];
  // If no tracks are available, show a message
  if (availableAudioTracks.isEmpty) {
    audioMenuItems.add(
      RpMenuItem(
        icon: null,
        text: LocaleKeys.menuNoAdditionalTracks.tr,
        enabled: false,
        onTap: () {},
      ),
    );
    return audioMenuItems;
  }

  // Add all available audio tracks
  for (int i = 0; i < availableAudioTracks.length; i++) {
    final track = availableAudioTracks[i];
    final isSelected = currentAudioTrack?.id == track.id;
    final displayName = AudioTrackController.to.getAudioTrackDisplayName(track);

    audioMenuItems.add(
      RpMenuItem(
        icon: isSelected ? Icons.check : null,
        text: displayName,
        onTap: () async {
          try {
            await AudioTrackController.to.selectAudioTrack(track);
          } catch (e) {
            //do nothing
          }
        },
      ),
    );
  }

  return audioMenuItems;
}

ContextMenu createContextMenu() {
  return ContextMenu(
    entries: convertToContextMenuEntries(defaultMenuData),
    boxDecoration: const BoxDecoration(
      color: RpColors.gray_800,
      borderRadius: BorderRadius.zero,
    ),
    padding: EdgeInsets.zero,
  );
}

List<ContextMenuEntry> convertToContextMenuEntries(List<RpMenuItem> items) {
  return items.map((item) {
    if (item.hasSubMenu) {
      return MenuItem.submenu(
        label: item.text,
        icon: item.icon,
        items: convertToContextMenuEntries(item.subMenuItems!),
      );
    } else {
      return MenuItem(
        label: item.text,
        icon: item.icon,
        enabled: item.enabled,
        value: item.text,
        onSelected: item.onTap ?? () {},
      );
    }
  }).toList();
}
