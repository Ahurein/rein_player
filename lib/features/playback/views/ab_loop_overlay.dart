import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rein_player/common/widgets/rp_dialog.dart';
import 'package:rein_player/features/playback/controller/ab_loop_controller.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/playback/models/ab_loop_segment.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';

class ABLoopOverlay extends StatelessWidget {
  const ABLoopOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!ABLoopController.to.isABLoopOverlayVisible.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        right: 10,
        top: 60,
        width: 450,
        height: 500,
        child: Material(
          elevation: 8,
          color: RpColors.gray_900.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Toolbar
              _buildToolbar(),

              // Segments list
              Expanded(
                child: Obx(() {
                  final segments = ABLoopController.to.segments;

                  if (segments.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildSegmentsList(segments);
                }),
              ),

              // Footer with instructions
              _buildFooter(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    final videoName =
        VideoAndControlController.to.currentVideo.value?.name ?? LocaleKeys.abLoopNoVideo.tr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: RpColors.black, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.repeat, color: RpColors.accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.abLoopSegments.tr,
                  style: const TextStyle(
                    color: RpColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  videoName,
                  style: TextStyle(
                    color: RpColors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Obx(() {
            final isActive = ABLoopController.to.isABLoopActive.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? RpColors.accent.withValues(alpha: 0.2)
                    : RpColors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isActive
                    ? LocaleKeys.abLoopActive.tr
                    : LocaleKeys.abLoopInactive.tr,
                style: TextStyle(
                  color: isActive ? RpColors.accent : RpColors.white_300,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: RpColors.white, size: 18),
            onPressed: ABLoopController.to.toggleOverlay,
            tooltip: LocaleKeys.close.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RpColors.white.withValues(alpha: 0.05),
        border: const Border(
          bottom: BorderSide(color: RpColors.black, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Add segment button
          ElevatedButton.icon(
            onPressed: ABLoopController.to.addSegmentAtCurrentPosition,
            icon: const Icon(Icons.add, size: 16),
            label: Text(
                LocaleKeys.abLoopNewSegment.tr,
                style: const TextStyle(fontSize: 12),
              ),
            style: ElevatedButton.styleFrom(
              backgroundColor: RpColors.accent,
              foregroundColor: RpColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
          ),
          const SizedBox(width: 8),

          // Play/Stop toggle
          Obx(() {
            final isActive = ABLoopController.to.isABLoopActive.value;
            return ElevatedButton.icon(
              onPressed: ABLoopController.to.toggleABLoopPlayback,
              icon: Icon(isActive ? Icons.stop : Icons.play_arrow, size: 16),
              label: Text(
                  isActive
                      ? LocaleKeys.abLoopStop.tr
                      : LocaleKeys.abLoopStart.tr,
                  style: const TextStyle(fontSize: 12),
                ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive
                    ? RpColors.red.withValues(alpha: 0.8)
                    : RpColors.green.withValues(alpha: 0.8),
                foregroundColor: RpColors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
            );
          }),
          const Spacer(),

          // Import button
          IconButton(
            icon: const Icon(Icons.file_upload, size: 18),
            color: RpColors.white_300,
            onPressed: () async {
              // Will be implemented in manual_import phase
            },
            tooltip: LocaleKeys.abLoopImportPBF.tr,
          ),

          // Export button
          Obx(() {
            final hasSegments = ABLoopController.to.segments.isNotEmpty;
            return IconButton(
              icon: const Icon(Icons.file_download, size: 18),
              color: hasSegments ? RpColors.white_300 : RpColors.white_300,
              onPressed: hasSegments ? ABLoopController.to.exportToPBF : null,
              tooltip: LocaleKeys.abLoopExportPBF.tr,
            );
          }),

          // Clear all button
          Obx(() {
            final hasSegments = ABLoopController.to.segments.isNotEmpty;
            return IconButton(
              icon: const Icon(Icons.delete_sweep, size: 18),
              color: hasSegments
                  ? RpColors.red.withValues(alpha: 0.7)
                  : RpColors.white.withValues(alpha: 0.3),
              onPressed: hasSegments ? () => _showClearConfirmation() : null,
              tooltip: LocaleKeys.abLoopClearAll.tr,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.repeat_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.abLoopEmptyTitle.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.abLoopEmptyHint.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentsList(List<ABLoopSegment> segments) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: segments.length,
      itemBuilder: (context, index) {
        return _SegmentItem(
          segment: segments[index],
          index: index,
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: RpColors.black, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildKeyHint('Ctrl+L', LocaleKeys.abLoopKeyNew.tr),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 12,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
          _buildKeyHint('L', LocaleKeys.abLoopKeyToggle.tr),
          const SizedBox(width: 12),
          _buildKeyHint('[', LocaleKeys.abLoopKeyPrev.tr),
          const SizedBox(width: 12),
          _buildKeyHint(']', LocaleKeys.abLoopKeyNext.tr),
        ],
      ),
    );
  }

  Widget _buildKeyHint(String key, String action) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            key,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          action,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _showClearConfirmation() {
    final context = Get.context;
    if (context == null) return;

    RpDialog.showConfirmation(
      context: context,
      title: LocaleKeys.dialogClearAllSegmentsTitle.tr,
      message: LocaleKeys.dialogClearAllSegmentsMessage.tr,
      confirmText: LocaleKeys.clearAll.tr,
      cancelText: LocaleKeys.cancel.tr,
      confirmColor: Colors.red,
      titleIcon: const Icon(Icons.delete_sweep, color: Colors.red),
    ).then((confirmed) {
      if (confirmed == true) {
        ABLoopController.to.clearSegments();
      }
    });
  }
}

class _SegmentItem extends StatefulWidget {
  final ABLoopSegment segment;
  final int index;

  const _SegmentItem({
    required this.segment,
    required this.index,
  });

  @override
  State<_SegmentItem> createState() => _SegmentItemState();
}

class _SegmentItemState extends State<_SegmentItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => _jumpToSegment(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered
                ? RpColors.accent.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isHovered
                  ? RpColors.accent.withValues(alpha: 0.3)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Segment index
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: RpColors.accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '[${widget.index + 1}]',
                      style: const TextStyle(
                        color: RpColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Time range
                  Expanded(
                    child: Text(
                      '${widget.segment.formattedStartTime} → ${widget.segment.formattedEndTime}',
                      style: TextStyle(
                        color: RpColors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),

                  // Loop count
                  Row(
                    children: [
                      Icon(Icons.repeat,
                          size: 14,
                          color: RpColors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.segment.loopCount}×',
                        style: TextStyle(
                          color: RpColors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),

                  // Delay indicator
                  if (widget.segment.delayEnabled &&
                      widget.segment.repeatDelayMs > 0) ...[
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Icon(Icons.pause,
                            size: 14,
                            color: RpColors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          '${(widget.segment.repeatDelayMs / 1000).toStringAsFixed(1)}s',
                          style: TextStyle(
                            color: RpColors.white.withValues(alpha: 0.8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Actions (visible on hover)
                  if (_isHovered) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.play_arrow, size: 16),
                      color: RpColors.white.withValues(alpha: 0.7),
                      onPressed: _jumpToSegment,
                      tooltip: LocaleKeys.abLoopJumpToSegment.tr,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      color: RpColors.white.withValues(alpha: 0.7),
                      onPressed: _editSegment,
                      tooltip: LocaleKeys.abLoopEditSegment.tr,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 16),
                      color: RpColors.red.withValues(alpha: 0.7),
                      onPressed: _deleteSegment,
                      tooltip: LocaleKeys.abLoopDeleteSegment.tr,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ],
              ),

              // Title (if present)
              if (widget.segment.title != null &&
                  widget.segment.title!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.segment.title!,
                  style: TextStyle(
                    color: RpColors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _jumpToSegment() {
    ABLoopController.to.jumpToSegment(widget.index);
  }

  void _editSegment() {
    ABLoopController.to.showEditSegmentModal(widget.index);
  }

  void _deleteSegment() {
    ABLoopController.to.deleteSegment(widget.index);
  }
}
