import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:rein_player/common/widgets/rp_snackbar.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/settings/controller/settings_controller.dart';
import 'package:rein_player/utils/constants/rp_keys.dart';
import 'package:rein_player/utils/local_storage/rp_local_storage.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';

import '../../settings/models/settings.dart';

class SubtitleController extends GetxController {
  static SubtitleController get to => Get.find();

  final storage = RpLocalStorage();

  final player = VideoAndControlController.to.videoPlayerController.player;

  RxBool isSubtitleEnabled = false.obs;

  /// mpv id of the selected primary track ("" when none). media_kit does not
  /// report it for external tracks, so it is read from mpv's "sid".
  final RxString currentPrimaryTrackId = "".obs;

  /// last primary track, re-selected when subtitles are toggled back on
  String _lastPrimaryTrackId = "";

  /// secondary subtitle (rendered at the top, like PotPlayer)
  RxBool isSecondarySubtitleEnabled = false.obs;
  String secondarySubtitleLanguage = "";
  final RxString currentSecondaryTrackId = "".obs;
  final RxList<SubtitleTrack> availableSubtitleTracks = <SubtitleTrack>[].obs;

  /// current subtitle lines from mpv: sub-text and secondary-sub-text
  final RxString primaryText = "".obs;
  final RxString secondaryText = "".obs;

  /// set when a new file is opened; cleared by the first track-list of
  /// that file, which arms [_pendingSecondaryAutoSelect]
  bool _awaitingNewMediaTracks = false;

  /// pick the preferred secondary track once playback of the new file starts
  bool _pendingSecondaryAutoSelect = false;

  @override
  void onInit() async {
    super.onInit();
    _setupSubtitleListeners();
    final settingsData = await storage.readData(RpKeysConstants.settingsKey);
    if (settingsData != null) {
      final settings = Settings.fromJson((settingsData));
      isSubtitleEnabled.value = settings.isSubtitleEnabled;
      isSecondarySubtitleEnabled.value = settings.isSecondarySubtitleEnabled;
      secondarySubtitleLanguage = settings.secondarySubtitleLanguage;
    }
  }

  void _setupSubtitleListeners() {
    player.stream.subtitle.listen((lines) {
      primaryText.value = lines.isNotEmpty ? lines[0].trim() : "";
      secondaryText.value = lines.length > 1 ? lines[1].trim() : "";
    });

    player.stream.tracks.listen((tracks) {
      availableSubtitleTracks.value = tracks.subtitle
          .where((track) => track.id != 'auto' && track.id != 'no')
          .toList();
      _refreshPrimaryTrackId();
      if (_awaitingNewMediaTracks) {
        _awaitingNewMediaTracks = false;
        _pendingSecondaryAutoSelect = isSecondarySubtitleEnabled.value;
      }
    });

    // track-list arrives before mpv has picked the primary track, so the
    // secondary one is chosen only once playback has actually started
    player.stream.position.listen((position) {
      if (_pendingSecondaryAutoSelect && position > Duration.zero) {
        _pendingSecondaryAutoSelect = false;
        _refreshPrimaryTrackId().then((_) => _autoSelectSecondaryTrack());
      }
    });
  }

  Future<void> _refreshPrimaryTrackId() async {
    final native = _nativePlayer;
    if (native == null) return;
    final sid = await native.getProperty('sid');
    currentPrimaryTrackId.value = int.tryParse(sid) != null ? sid : "";
    if (currentPrimaryTrackId.value.isNotEmpty) {
      _lastPrimaryTrackId = currentPrimaryTrackId.value;
    }
  }

  NativePlayer? get _nativePlayer {
    final platform = player.platform;
    return platform is NativePlayer ? platform : null;
  }

  /// load subtitle from file system
  void loadSubtitle() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt', 'ass', 'ssa'],
      allowMultiple: false,
    );

    if (result != null) {
      String filePath = result.files.single.path!;

      final extension = filePath.split(".").last.toLowerCase();
      if (extension == "srt" ||
          extension == "vtt" ||
          extension == "ass" ||
          extension == "ssa") {
        isSubtitleEnabled.value = true;
        // loading by path lets the track be named after the file in menus
        await player.setSubtitleTrack(
            SubtitleTrack.uri(filePath, title: p.basename(filePath)));
        await _refreshPrimaryTrackId();
        RpSnackbar.success(
          title: LocaleKeys.snackSubtitleLoaded.tr,
          message: LocaleKeys.snackSubtitleLoadedMsg.tr,
        );
      } else {
        RpSnackbar.error(
          message: LocaleKeys.snackSubtitleFormatError.tr,
        );
      }
    }
  }

  Future<void> disableSubtitle() async {
    await player.setSubtitleTrack(SubtitleTrack.no());
    currentPrimaryTrackId.value = "";
  }

  /// select an embedded (or already added) track as the primary subtitle
  Future<void> selectPrimaryTrack(SubtitleTrack track) async {
    await player.setSubtitleTrack(SubtitleTrack(track.id, null, null));
    await _refreshPrimaryTrackId();
    // mpv takes the track out of the secondary slot if it was there
    if (currentSecondaryTrackId.value == track.id) {
      currentSecondaryTrackId.value = "";
      secondaryText.value = "";
    }
    if (!isSubtitleEnabled.value) {
      isSubtitleEnabled.value = true;
      final settings = SettingsController.to.settings;
      settings.isSubtitleEnabled = true;
      await storage.saveData(RpKeysConstants.settingsKey, settings.toJson());
    }
  }

  /// toggle subtitle
  void toggleSubtitle() async {
    if (isSubtitleEnabled.value) {
      isSubtitleEnabled.value = false;
      await disableSubtitle();
    } else {
      isSubtitleEnabled.value = true;
      // re-select by id instead of re-adding the file, which would
      // create a duplicate track every time
      final lastIsAvailable = availableSubtitleTracks
          .any((track) => track.id == _lastPrimaryTrackId);
      await player.setSubtitleTrack(lastIsAvailable
          ? SubtitleTrack(_lastPrimaryTrackId, null, null)
          : SubtitleTrack.auto());
      await _refreshPrimaryTrackId();
    }
    final settings = SettingsController.to.settings;
    settings.isSubtitleEnabled = isSubtitleEnabled.value;
    await storage.saveData(RpKeysConstants.settingsKey, settings.toJson());
  }

  /// load secondary subtitle from file system and show it via secondary-sid
  Future<void> loadSecondarySubtitle() async {
    final native = _nativePlayer;
    if (native == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt', 'ass', 'ssa'],
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    try {
      // "auto" adds the track without making it the primary one
      await native
          .command(['sub-add', filePath, 'auto', p.basename(filePath)]);

      // the added track is appended to the end of mpv's track-list
      final count = int.parse(await native.getProperty('track-list/count'));
      String? trackId;
      for (int i = count - 1; i >= 0; i--) {
        if (await native.getProperty('track-list/$i/type') == 'sub') {
          trackId = await native.getProperty('track-list/$i/id');
          break;
        }
      }
      if (trackId == null) return;

      await _setSecondaryTrack(trackId, language: "");
      RpSnackbar.success(
        title: LocaleKeys.snackSecondarySubtitleLoaded.tr,
        message: LocaleKeys.snackSecondarySubtitleLoadedMsg.tr,
      );
    } catch (e) {
      RpSnackbar.error(message: LocaleKeys.snackSecondarySubtitleError.tr);
    }
  }

  /// use an embedded (or already added) subtitle track as secondary
  Future<void> selectSecondaryTrack(SubtitleTrack track) async {
    await _setSecondaryTrack(track.id, language: track.language ?? "");
  }

  Future<void> disableSecondarySubtitle() async {
    await _nativePlayer?.setProperty('secondary-sid', 'no');
    currentSecondaryTrackId.value = "";
    secondaryText.value = "";
    isSecondarySubtitleEnabled.value = false;
    await _saveSecondarySettings();
  }

  /// called before a new file is opened: mpv keeps the numeric
  /// secondary-sid across files, which would point at an unrelated track
  Future<void> resetTracksForNewMedia() async {
    _lastPrimaryTrackId = "";
    await _nativePlayer?.setProperty('secondary-sid', 'no');
    currentSecondaryTrackId.value = "";
    secondaryText.value = "";
    _pendingSecondaryAutoSelect = false;
    _awaitingNewMediaTracks = true;
  }

  Future<void> _setSecondaryTrack(String trackId,
      {required String language}) async {
    final native = _nativePlayer;
    if (native == null) return;

    await native.setProperty('secondary-sid', trackId);
    currentSecondaryTrackId.value = trackId;
    isSecondarySubtitleEnabled.value = true;
    secondarySubtitleLanguage = language;
    _pendingSecondaryAutoSelect = false;
    await _saveSecondarySettings();
  }

  /// pick the first track matching the saved secondary language
  Future<void> _autoSelectSecondaryTrack() async {
    if (secondarySubtitleLanguage.isEmpty) return;
    // never reuse the primary track: mpv would move it to the secondary
    // slot and the bottom subtitle would disappear
    final primaryId = currentPrimaryTrackId.value;
    SubtitleTrack? match;
    for (final track in availableSubtitleTracks) {
      if (track.language == secondarySubtitleLanguage &&
          track.id != primaryId) {
        match = track;
        break;
      }
    }
    if (match == null) return;

    await _nativePlayer?.setProperty('secondary-sid', match.id);
    currentSecondaryTrackId.value = match.id;
  }

  Future<void> _saveSecondarySettings() async {
    final settings = SettingsController.to.settings;
    settings.isSecondarySubtitleEnabled = isSecondarySubtitleEnabled.value;
    settings.secondarySubtitleLanguage = secondarySubtitleLanguage;
    await storage.saveData(RpKeysConstants.settingsKey, settings.toJson());
  }

  String getSubtitleTrackDisplayName(SubtitleTrack track) {
    final parts = <String>[];
    if (track.title?.isNotEmpty == true) {
      parts.add(track.title!);
    }
    // media_kit tags tracks it adds itself with language "auto"
    if (track.language?.isNotEmpty == true && track.language != 'auto') {
      parts.add(track.language!);
    }
    parts.add('#${track.id}');
    return parts.join(' - ');
  }
}
