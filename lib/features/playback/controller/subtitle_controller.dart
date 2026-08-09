import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
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
  String currentSubtitleContent = "";

  @override
  void onInit() async {
    super.onInit();
    final settingsData = await storage.readData(RpKeysConstants.settingsKey);
    if (settingsData != null) {
      final settings = Settings.fromJson((settingsData));
      isSubtitleEnabled.value = settings.isSubtitleEnabled;
    }
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
      final file = File(filePath);
      final content = await file.readAsString();
      log(content);

      final extension = filePath.split(".").last.toLowerCase();
      if (extension == "srt" ||
          extension == "vtt" ||
          extension == "ass" ||
          extension == "ssa") {
        currentSubtitleContent = content;
        isSubtitleEnabled.value = true;
        await player.setSubtitleTrack(SubtitleTrack.data(content));
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
  }

  /// toggle subtitle
  void toggleSubtitle() async {
    if (isSubtitleEnabled.value) {
      isSubtitleEnabled.value = false;
      await disableSubtitle();
    } else {
      isSubtitleEnabled.value = true;
      if (currentSubtitleContent.isNotEmpty) {
        await player
            .setSubtitleTrack(SubtitleTrack.data(currentSubtitleContent));
      } else {
        await player.setSubtitleTrack(SubtitleTrack.auto());
      }
    }
    final settings = SettingsController.to.settings;
    settings.isSubtitleEnabled = isSubtitleEnabled.value;
    await storage.saveData(RpKeysConstants.settingsKey, settings.toJson());
  }
}
