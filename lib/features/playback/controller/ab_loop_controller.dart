import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:rein_player/common/widgets/rp_snackbar.dart';
import 'package:rein_player/features/playback/controller/controls_controller.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/playback/models/ab_loop_segment.dart';
import 'package:rein_player/features/playback/models/pbf_bookmark_file.dart';
import 'package:rein_player/utils/constants/rp_keys.dart';
import 'package:rein_player/utils/local_storage/rp_local_storage.dart';
import 'package:rein_player/features/playback/views/ab_loop_editor_modal.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';
import 'package:rein_player/utils/localization/tr_args.dart';
import 'package:rein_player/utils/parsers/pbf_parser.dart';

class ABLoopController extends GetxController {
  static ABLoopController get to => Get.find();

  final storage = RpLocalStorage();

  // Current video's A-B loop segments
  final RxList<ABLoopSegment> segments = <ABLoopSegment>[].obs;

  // Playback state
  final RxInt currentSegmentIndex = 0.obs;
  final RxInt currentLoopIteration = 0.obs;
  final RxBool isABLoopActive = false.obs;

  // UI visibility
  final RxBool isABLoopOverlayVisible = false.obs;

  // Internal state
  StreamSubscription? _positionSubscription;
  bool _isLooping = false;
  bool _isPausedForDelay = false;

  @override
  void onInit() {
    super.onInit();
    // Load segments when controller initializes
    final currentVideo = VideoAndControlController.to.currentVideo.value;
    if (currentVideo != null) {
      loadSegmentsForVideo(currentVideo.location);
    }
  }

  @override
  void onClose() {
    _positionSubscription?.cancel();
    super.onClose();
  }

  /// Load segments for a specific video from storage
  void loadSegmentsForVideo(String videoPath) {
    try {
      final allSegments =
          storage.readData<Map>(RpKeysConstants.abLoopSegmentsKey);
      if (allSegments == null) {
        segments.clear();
        return;
      }

      final videoSegments = allSegments[videoPath] as List?;
      if (videoSegments == null || videoSegments.isEmpty) {
        segments.clear();
        return;
      }

      // Parse segments from JSON
      final parsedSegments = videoSegments
          .map((json) => ABLoopSegment.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by sequence index
      parsedSegments.sort((a, b) => a.sequenceIndex.compareTo(b.sequenceIndex));

      segments.value = parsedSegments;
    } catch (e) {
      segments.clear();
    }
  }

  /// Auto-load PBF file if it exists alongside the video
  Future<void> autoLoadPBFForVideo(String videoPath) async {
    final pbfPath = PBFParser.getPBFPathForVideo(videoPath);
    final file = File(pbfPath);

    if (await file.exists()) {
      try {
        final pbf = await PBFParser.parseFile(pbfPath);
        segments.value = pbf.segments;
        await _saveSegmentsToStorage(videoPath);

        RpSnackbar.success(
          title: LocaleKeys.snackABLoopsLoaded.tr,
          message: LocaleKeys.snackSegmentsLoadedFrom
              .trArgsFmt([pbf.segments.length, path.basename(pbfPath)]),
        );

        // Auto-start playback if segments exist
        if (segments.isNotEmpty) {
          startABLoopPlayback();
        }
      } catch (e) {
        RpSnackbar.error(
          message: LocaleKeys.snackFailedLoadPBF.trArgsFmt([e.toString()]),
        );
      }
    } else {
      loadSegmentsForVideo(videoPath);
      
      // Auto-start if segments exist in storage
      if (segments.isNotEmpty && !isABLoopActive.value) {
        startABLoopPlayback();
      }
    }
  }

  /// Add a new segment
  Future<void> addSegment(ABLoopSegment segment) async {
    try {
      final video = VideoAndControlController.to.currentVideo.value;
      if (video == null) {
        RpSnackbar.warning(message: LocaleKeys.noVideoPlaying.tr);
        return;
      }

      // Reindex the segment
      final newSegment = segment.copyWith(sequenceIndex: segments.length);
      segments.add(newSegment);

      // Sort by start time
      segments.sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));

      // Re-index all segments
      _reindexSegments();

      await _saveSegmentsToStorage(video.location);

      RpSnackbar.success(
        title: LocaleKeys.snackSegmentAdded.tr,
        message: LocaleKeys.snackSegmentAddedMsg
            .trArgsFmt([newSegment.formattedStartTime]),
      );
    } catch (e) {
      RpSnackbar.error(message: LocaleKeys.snackFailedAddSegment.tr);
    }
  }

  /// Add segment at current position - opens editor modal
  void addSegmentAtCurrentPosition() {
    final position = ControlsController.to.videoPosition.value;
    if (position == null) {
      RpSnackbar.warning(message: LocaleKeys.snackUnableGetPosition.tr);
      return;
    }

    // Open editor modal for configuration
    showAddSegmentModal();
  }

  /// Show modal to add new segment
  void showAddSegmentModal() {
    final context = Get.context;
    if (context == null) return;

    Get.dialog(
      const ABLoopEditorModal(),
    );
  }

  /// Show modal to edit existing segment
  void showEditSegmentModal(int index) {
    final context = Get.context;
    if (context == null) return;

    if (index < 0 || index >= segments.length) return;

    Get.dialog(
      ABLoopEditorModal(
        segment: segments[index],
        segmentIndex: index,
      ),
    );
  }

  /// Update an existing segment
  Future<void> updateSegment(int index, ABLoopSegment segment) async {
    try {
      if (index < 0 || index >= segments.length) return;

      segments[index] = segment;

      // Re-sort and re-index
      segments.sort((a, b) => a.startTimeMs.compareTo(b.startTimeMs));
      _reindexSegments();

      final video = VideoAndControlController.to.currentVideo.value;
      if (video != null) {
        await _saveSegmentsToStorage(video.location);
      }

      RpSnackbar.success(message: LocaleKeys.snackSegmentUpdated.tr);
    } catch (e) {
      RpSnackbar.error(message: LocaleKeys.snackFailedUpdateSegment.tr);
    }
  }

  /// Delete a segment
  Future<void> deleteSegment(int index) async {
    try {
      if (index < 0 || index >= segments.length) return;

      final segment = segments[index];
      segments.removeAt(index);

      // Re-index remaining segments
      _reindexSegments();

      final video = VideoAndControlController.to.currentVideo.value;
      if (video != null) {
        await _saveSegmentsToStorage(video.location);
      }

      RpSnackbar.success(
        title: LocaleKeys.snackSegmentDeleted.tr,
        message: LocaleKeys.snackSegmentDeletedMsg
            .trArgsFmt([segment.formattedStartTime]),
      );

      // Stop playback if no segments left
      if (segments.isEmpty && isABLoopActive.value) {
        stopABLoopPlayback();
      }
    } catch (e) {
      RpSnackbar.error(message: 'Failed to delete segment');
    }
  }

  /// Clear all segments
  Future<void> clearSegments() async {
    try {
      segments.clear();

      final video = VideoAndControlController.to.currentVideo.value;
      if (video != null) {
        await _saveSegmentsToStorage(video.location);
      }

      if (isABLoopActive.value) {
        stopABLoopPlayback();
      }

      RpSnackbar.success(
        title: LocaleKeys.snackSegmentsCleared.tr,
        message: LocaleKeys.snackSegmentsClearedMsg.tr,
      );
    } catch (e) {
      RpSnackbar.error(message: LocaleKeys.snackFailedClearSegments.tr);
    }
  }

  /// Import segments from a PBF file
  Future<void> importFromPBF(String filePath) async {
    try {
      final pbf = await PBFParser.parseFile(filePath);
      final video = VideoAndControlController.to.currentVideo.value;

      if (video == null) {
        RpSnackbar.warning(message: LocaleKeys.noVideoPlaying.tr);
        return;
      }

      segments.value = pbf.segments;
      await _saveSegmentsToStorage(video.location);

      RpSnackbar.success(
        title: LocaleKeys.snackImportSuccessful.tr,
        message: LocaleKeys.snackImportSuccessfulMsg
            .trArgsFmt([pbf.segments.length]),
      );

      // Auto-start playback
      if (segments.isNotEmpty) {
        startABLoopPlayback();
      }
    } catch (e) {
      RpSnackbar.error(
        message: LocaleKeys.snackFailedImportPBF.trArgsFmt([e.toString()]),
      );
    }
  }

  /// Export segments to a PBF file
  Future<void> exportToPBF([String? filePath]) async {
    try {
      if (segments.isEmpty) {
        RpSnackbar.warning(message: LocaleKeys.snackNoSegmentsToExport.tr);
        return;
      }

      final video = VideoAndControlController.to.currentVideo.value;
      if (video == null) {
        RpSnackbar.warning(message: LocaleKeys.noVideoPlaying.tr);
        return;
      }

      String exportPath;
      if (filePath != null) {
        exportPath = filePath;
      } else {
        // Prompt user to save file
        final result = await FilePicker.platform.saveFile(
          dialogTitle: LocaleKeys.snackExportABLoopsTitle.tr,
          fileName: '${path.basenameWithoutExtension(video.location)}.pbf',
          type: FileType.custom,
          allowedExtensions: ['pbf'],
        );

        if (result == null) return;
        exportPath = result;
      }

      final pbf = PBFBookmarkFile(
        videoPath: video.location,
        segments: segments,
      );

      await PBFParser.exportToFile(pbf, exportPath);

      RpSnackbar.success(
        title: LocaleKeys.snackExportSuccessful.tr,
        message: LocaleKeys.snackExportSuccessfulMsg
            .trArgsFmt([path.basename(exportPath)]),
      );
    } catch (e) {
      RpSnackbar.error(
        message: LocaleKeys.snackFailedExportPBF.trArgsFmt([e.toString()]),
      );
    }
  }

  /// Start A-B loop playback
  void startABLoopPlayback() {
    if (segments.isEmpty) {
      RpSnackbar.info(message: LocaleKeys.snackNoABLoopSegments.tr);
      return;
    }

    isABLoopActive.value = true;
    currentSegmentIndex.value = 0;
    currentLoopIteration.value = 0;

    // Jump to first segment
    final firstSegment = segments[0];
    VideoAndControlController.to.player.seek(firstSegment.startTime);

    // Start monitoring position
    _startPositionMonitoring();

    RpSnackbar.info(
      message: LocaleKeys.snackABLoopStarted.trArgsFmt([segments.length]),
    );
  }

  /// Stop A-B loop playback
  void stopABLoopPlayback() {
    isABLoopActive.value = false;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _isPausedForDelay = false;

    RpSnackbar.info(message: LocaleKeys.snackABLoopStopped.tr);
  }

  /// Toggle A-B loop playback
  void toggleABLoopPlayback() {
    if (isABLoopActive.value) {
      stopABLoopPlayback();
    } else {
      startABLoopPlayback();
    }
  }

  /// Toggle overlay visibility
  void toggleOverlay() {
    isABLoopOverlayVisible.value = !isABLoopOverlayVisible.value;
  }

  /// Jump to next segment
  Future<void> jumpToNextSegment() async {
    if (segments.isEmpty) {
      RpSnackbar.info(message: LocaleKeys.snackNoSegments.tr);
      return;
    }

    currentSegmentIndex.value =
        (currentSegmentIndex.value + 1) % segments.length;
    currentLoopIteration.value = 0;

    final segment = segments[currentSegmentIndex.value];
    await VideoAndControlController.to.player.seek(segment.startTime);

    RpSnackbar.info(
      message:
          LocaleKeys.snackJumpedToSegment.trArgsFmt([currentSegmentIndex.value + 1]),
    );
  }

  /// Jump to previous segment
  Future<void> jumpToPreviousSegment() async {
    if (segments.isEmpty) {
      RpSnackbar.info(message: LocaleKeys.snackNoSegments.tr);
      return;
    }

    currentSegmentIndex.value =
        (currentSegmentIndex.value - 1 + segments.length) % segments.length;
    currentLoopIteration.value = 0;

    final segment = segments[currentSegmentIndex.value];
    await VideoAndControlController.to.player.seek(segment.startTime);

    RpSnackbar.info(
      message:
          LocaleKeys.snackJumpedToSegment.trArgsFmt([currentSegmentIndex.value + 1]),
    );
  }

  /// Jump to specific segment
  Future<void> jumpToSegment(int index) async {
    if (index < 0 || index >= segments.length) return;

    currentSegmentIndex.value = index;
    currentLoopIteration.value = 0;

    final segment = segments[index];
    await VideoAndControlController.to.player.seek(segment.startTime);
  }

  // Private methods

  void _startPositionMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = VideoAndControlController.to.player.stream.position
        .listen(_onPositionUpdate);
  }

  void _onPositionUpdate(Duration position) {
    if (!isABLoopActive.value || segments.isEmpty || _isLooping) return;
    if (_isPausedForDelay) return;

    final segment = segments[currentSegmentIndex.value];
    final posMs = position.inMilliseconds;

    // Check if we've reached segment end
    if (posMs >= segment.endTimeMs) {
      currentLoopIteration.value++;

      if (currentLoopIteration.value < segment.loopCount) {
        // More loops remaining - loop back to start
        _loopBack(segment);
      } else {
        // Segment complete - move to next
        _nextSegment();
      }
    }
  }

  Future<void> _loopBack(ABLoopSegment segment) async {
    _isLooping = true;

    try {
      if (segment.delayEnabled && segment.repeatDelayMs > 0) {
        // Pause on last frame for delay duration
        _isPausedForDelay = true;
        await VideoAndControlController.to.player.pause();
        await Future.delayed(Duration(milliseconds: segment.repeatDelayMs));
        await VideoAndControlController.to.player.seek(segment.startTime);
        await VideoAndControlController.to.player.play();
        _isPausedForDelay = false;
      } else {
        // No delay - immediately loop back
        await VideoAndControlController.to.player.seek(segment.startTime);
      }
    } finally {
      _isLooping = false;
    }
  }

  Future<void> _nextSegment() async {
    _isLooping = true;

    try {
      currentSegmentIndex.value =
          (currentSegmentIndex.value + 1) % segments.length;
      currentLoopIteration.value = 0;
      await VideoAndControlController.to.player
          .seek(segments[currentSegmentIndex.value].startTime);
    } finally {
      _isLooping = false;
    }
  }

  void _reindexSegments() {
    for (int i = 0; i < segments.length; i++) {
      segments[i] = segments[i].copyWith(sequenceIndex: i);
    }
  }

  Future<void> _saveSegmentsToStorage(String videoPath) async {
    try {
      final allSegments =
          storage.readData<Map>(RpKeysConstants.abLoopSegmentsKey) ?? {};

      // Convert segments to JSON
      final segmentsJson = segments.map((s) => s.toJson()).toList();

      allSegments[videoPath] = segmentsJson;
      await storage.saveData(RpKeysConstants.abLoopSegmentsKey, allSegments);
    } catch (e) {
      // do nothing
    }
  }
}
