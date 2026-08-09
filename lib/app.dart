import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:rein_player/bindings/general_bindings.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/playback/views/video_and_controls_screen.dart';
import 'package:rein_player/features/playback/views/seek_preview_overlay.dart';
import 'package:rein_player/features/player_frame/controller/keyboard_shortcut_controller.dart';
import 'package:rein_player/features/player_frame/controller/navigation_context_controller.dart';
import 'package:rein_player/features/player_frame/controller/window_actions_controller.dart';
import 'package:rein_player/features/player_frame/controller/window_controller.dart';
import 'package:rein_player/features/player_frame/views/fullscreen_overlay.dart';
import 'package:rein_player/features/playlist/controller/playlist_controller.dart';
import 'package:rein_player/utils/constants/rp_keys.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/local_storage/rp_local_storage.dart';
import 'package:rein_player/utils/localization/app_languages.dart';
import 'package:rein_player/utils/localization/app_translations.dart';
import 'package:rein_player/utils/theme/theme.dart';

import 'features/player_frame/views/window_frame.dart';
import 'features/playlist/views/playlist_sidebar.dart';
import 'features/developer/views/developer_log_window.dart';

class RpApp extends StatelessWidget {
  final videoPlayerController = Get.put(VideoAndControlController());
  final playlistController = Get.put(PlaylistController());
  final keyboardController = Get.put(KeyboardController());
  final windowController = Get.put(WindowController());
  final navigationContextController = Get.put(NavigationContextController());
  final focus = FocusNode();

  RpApp({super.key});

  Locale _initialLocale() {
    final stored = RpLocalStorage().readData<Map>(RpKeysConstants.settingsKey);
    if (stored != null && stored[RpKeysConstants.languageKey] != null) {
      return AppLanguage.fromCode(stored[RpKeysConstants.languageKey] as String?)
          .locale;
    }
    return AppLanguage.fromDeviceLocale(Get.deviceLocale).locale;
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: GeneralBindings(),
      title: "Rein Player",
      debugShowCheckedModeBanner: false,
      darkTheme: RpAppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      translations: AppTranslations(),
      locale: _initialLocale(),
      fallbackLocale: const Locale('en'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales:
          AppLanguage.values.map((language) => language.locale).toList(),
      home: LayoutBuilder(
        builder: (context, constraints) {
          // Only render app content when window is properly sized
          if (constraints.maxWidth < 400 || constraints.maxHeight < 300) {
            return const Scaffold(
              body: SizedBox.expand(),
            );
          }

          return Stack(
            children: [
              Scaffold(
                body: GestureDetector(
                  onTap: focus.requestFocus,
                  child: KeyboardListener(
                    autofocus: true,
                    focusNode: focus,
                    onKeyEvent: keyboardController.handleKey,
                    child: FullscreenOverlay(
                      child: RpHome(playlistController: playlistController),
                    ),
                  ),
                ),
              ),
              const SeekPreviewOverlay(),
              const DeveloperLogWindow(),
            ],
          );
        },
      ),
    );
  }
}

class RpHome extends StatelessWidget {
  const RpHome({
    super.key,
    required this.playlistController,
  });

  final PlaylistController playlistController;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) =>
          WindowController.to.isDraggingOnWindow.value = true,
      onDragExited: (details) =>
          WindowController.to.isDraggingOnWindow.value = false,
      onDragDone: (DropDoneDetails details) async {
        await WindowController.to.onWindowDrop(details.files);
      },
      child: Stack(
        children: [
          /// home
          Container(
            constraints: const BoxConstraints.expand(),
            child: Column(
              children: [
                /// custom window frame
                Obx(() {
                  final isFullScreenMode =
                      WindowActionsController.to.isFullScreenMode.value;
                  return isFullScreenMode
                      ? const SizedBox.shrink()
                      : const RpWindowFrame();
                }),

                /// main content
                Expanded(
                  child: Row(
                    children: [
                      /// video and controls screen
                      const Expanded(child: RpVideoAndControlsScreen()),

                      /// slider
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onHorizontalDragUpdate:
                            playlistController.updatePlaylistWindowSizeOnDrag,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.resizeColumn,
                          child: Container(width: 2, color: RpColors.black),
                        ),
                      ),

                      /// playlist
                      Obx(() {
                        return playlistController
                                    .isPlaylistWindowOpened.value &&
                                !WindowActionsController
                                    .to.isFullScreenMode.value
                            ? const RpPlaylistSideBar()
                            : const SizedBox.shrink();
                      })
                    ],
                  ),
                )
              ],
            ),
          ),

          /// drag overlay
          Obx(() {
            if (WindowController.to.isDraggingOnWindow.value) {
              return Positioned(
                  child: Container(
                color: RpColors.dropColor,
                width: double.infinity,
              ));
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
