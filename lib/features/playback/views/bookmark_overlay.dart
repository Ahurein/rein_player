import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rein_player/common/widgets/rp_dialog.dart';
import 'package:rein_player/features/playback/controller/bookmark_controller.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/playback/models/video_bookmark.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';
import 'package:rein_player/utils/localization/tr_args.dart';

class BookmarkOverlay extends StatelessWidget {
  const BookmarkOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!BookmarkController.to.isBookmarkOverlayVisible.value) {
        return const SizedBox.shrink();
      }

      return Positioned(
        right: 10,
        top: 60,
        width: 380,
        height: 450,
        child: Material(
          elevation: 8,
          color: RpColors.gray_900.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Bookmarks list
              Expanded(
                child: Obx(() {
                  final bookmarks = BookmarkController.to.bookmarks;

                  if (bookmarks.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildBookmarksList(bookmarks);
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
          const Icon(Icons.bookmark, color: RpColors.accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleKeys.bookmarkTitle.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  videoName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              Obx(() {
                final count = BookmarkController.to.bookmarks.length;
                if (count > 0) {
                  return IconButton(
                    icon: const Icon(Icons.delete_sweep,
                        color: Colors.white, size: 18),
                    onPressed: () => _showClearConfirmation(),
                    tooltip: LocaleKeys.bookmarkClearAllTooltip.tr,
                  );
                }
                return const SizedBox.shrink();
              }),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                onPressed: BookmarkController.to.toggleBookmarkOverlay,
                tooltip: LocaleKeys.close.tr,
              ),
            ],
          ),
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
              Icons.bookmark_border,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              LocaleKeys.bookmarkEmptyTitle.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.bookmarkEmptyHint.tr,
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

  Widget _buildBookmarksList(List<VideoBookmark> bookmarks) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        return _BookmarkItem(
          bookmark: bookmarks[index],
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
          _buildKeyHint('Ctrl+B', LocaleKeys.bookmarkKeyAdd.tr),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 12,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(width: 12),
          _buildKeyHint('B', LocaleKeys.bookmarkKeyNext.tr),
          const SizedBox(width: 12),
          _buildKeyHint('Shift+B', LocaleKeys.bookmarkKeyPrevious.tr),
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
      title: LocaleKeys.dialogClearAllBookmarksTitle.tr,
      message: LocaleKeys.dialogClearAllBookmarksMessage.tr,
      confirmText: LocaleKeys.clearAll.tr,
      cancelText: LocaleKeys.cancel.tr,
      confirmColor: Colors.red,
      titleIcon: const Icon(Icons.delete_sweep, color: Colors.red),
    ).then((confirmed) {
      if (confirmed == true) {
        final video = VideoAndControlController.to.currentVideo.value;
        if (video != null) {
          BookmarkController.to.clearBookmarksForVideo(video.location);
        }
      }
    });
  }
}

class _BookmarkItem extends StatefulWidget {
  final VideoBookmark bookmark;
  final int index;

  const _BookmarkItem({
    required this.bookmark,
    required this.index,
  });

  @override
  State<_BookmarkItem> createState() => _BookmarkItemState();
}

class _BookmarkItemState extends State<_BookmarkItem> {
  bool _isHovered = false;
  bool _isEditing = false;
  late TextEditingController _nameController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bookmark.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => _jumpToBookmark(),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          child: Row(
            children: [
              // Timestamp
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: RpColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.bookmark.formattedTimestamp,
                  style: const TextStyle(
                    color: RpColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name (editable)
              Expanded(
                child: _isEditing ? _buildNameEditor() : _buildNameDisplay(),
              ),

              // Actions (visible on hover)
              if (_isHovered) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.play_arrow, size: 16),
                  color: Colors.white.withValues(alpha: 0.7),
                  onPressed: _jumpToBookmark,
                  tooltip: LocaleKeys.bookmarkJumpToTooltip.tr,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  color: Colors.white.withValues(alpha: 0.7),
                  onPressed: _startEditing,
                  tooltip: LocaleKeys.bookmarkEditNameTooltip.tr,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 16),
                  color: Colors.red.withValues(alpha: 0.7),
                  onPressed: _deleteBookmark,
                  tooltip: LocaleKeys.bookmarkDeleteTooltip.tr,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameDisplay() {
    final displayName = widget.bookmark.name.isEmpty
        ? LocaleKeys.bookmarkDefaultName.trArgs([widget.index + 1])
        : widget.bookmark.name;

    return Text(
      displayName,
      style: TextStyle(
        color: widget.bookmark.name.isEmpty
            ? Colors.white.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.9),
        fontSize: 13,
        fontStyle:
            widget.bookmark.name.isEmpty ? FontStyle.italic : FontStyle.normal,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildNameEditor() {
    return TextField(
      controller: _nameController,
      focusNode: _focusNode,
      autofocus: true,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: LocaleKeys.bookmarkEnterName.tr,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 13,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: RpColors.accent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: RpColors.accent, width: 2),
        ),
      ),
      onSubmitted: (_) => _saveEdit(),
      onEditingComplete: _saveEdit,
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    _focusNode.requestFocus();
  }

  void _saveEdit() {
    setState(() {
      _isEditing = false;
    });
    final newName = _nameController.text.trim();
    if (newName != widget.bookmark.name) {
      BookmarkController.to.updateBookmarkName(widget.index, newName);
    }
  }

  void _jumpToBookmark() {
    BookmarkController.to.jumpToBookmark(widget.index);
  }

  void _deleteBookmark() {
    BookmarkController.to.deleteBookmark(widget.index);
  }
}
