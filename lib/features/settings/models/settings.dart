import 'package:rein_player/utils/constants/rp_enums.dart';
import 'package:rein_player/utils/constants/rp_keys.dart';
import 'package:rein_player/utils/localization/app_languages.dart';

class Settings {
  bool isSubtitleEnabled;
  PlaylistType playlistType;
  DoubleClickAction doubleClickAction;
  PlaylistLoadBehavior playlistLoadBehavior;
  PlaylistEndBehavior playlistEndBehavior;
  AppLanguage language;

  Settings({
    this.isSubtitleEnabled = true,
    this.playlistType = PlaylistType.defaultPlaylistType,
    this.doubleClickAction = DoubleClickAction.toggleWindowSize,
    this.playlistLoadBehavior = PlaylistLoadBehavior.clearAndReplace,
    this.playlistEndBehavior = PlaylistEndBehavior.showHomeScreen,
    this.language = AppLanguage.english,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    PlaylistType savedPlaylistType = PlaylistType.values.byName(
        json[RpKeysConstants.playlistTypeStorageKey] ??
            PlaylistType.defaultPlaylistType.name);

    DoubleClickAction savedDoubleClickAction = DoubleClickAction.values.byName(
        json[RpKeysConstants.doubleClickActionKey] ??
            DoubleClickAction.toggleWindowSize.name);

    PlaylistLoadBehavior savedPlaylistLoadBehavior = PlaylistLoadBehavior.values.byName(
        json[RpKeysConstants.playlistLoadBehaviorKey] ??
            PlaylistLoadBehavior.clearAndReplace.name);

    PlaylistEndBehavior savedPlaylistEndBehavior = PlaylistEndBehavior.values.byName(
        json[RpKeysConstants.playlistEndBehaviorKey] ??
            PlaylistEndBehavior.showHomeScreen.name);

    return Settings(
      isSubtitleEnabled:
          json[RpKeysConstants.subtitleEnabledStorageKey] as bool? ?? false,
      playlistType: savedPlaylistType,
      doubleClickAction: savedDoubleClickAction,
      playlistLoadBehavior: savedPlaylistLoadBehavior,
      playlistEndBehavior: savedPlaylistEndBehavior,
      language: AppLanguage.fromCode(json[RpKeysConstants.languageKey] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      RpKeysConstants.subtitleEnabledStorageKey: isSubtitleEnabled,
      RpKeysConstants.playlistTypeStorageKey: playlistType.name,
      RpKeysConstants.doubleClickActionKey: doubleClickAction.name,
      RpKeysConstants.playlistLoadBehaviorKey: playlistLoadBehavior.name,
      RpKeysConstants.playlistEndBehaviorKey: playlistEndBehavior.name,
      RpKeysConstants.languageKey: language.code,
    };
  }

  Map<String, dynamic> defaultSettings() {
    return toJson();
  }
}