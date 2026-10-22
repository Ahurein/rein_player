import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rein_player/features/playback/controller/subtitle_controller.dart';
import 'package:rein_player/features/playback/controller/video_and_controls_controller.dart';
import 'package:rein_player/features/settings/controller/subtitle_styling_controller.dart';

/// Renders the primary subtitle at the bottom and the secondary subtitle
/// at the top. Replaces media_kit's built-in SubtitleView, which joins both
/// lines into a single block at the bottom.
class RpSubtitleOverlay extends StatelessWidget {
  const RpSubtitleOverlay({super.key});

  // same reference size media_kit uses to scale subtitle text
  static const _referenceWidth = 1920.0;
  static const _referenceHeight = 1080.0;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (VideoAndControlController.to.currentVideoUrl.isEmpty) {
        return const SizedBox.shrink();
      }

      final subtitleController = SubtitleController.to;
      final stylingController = SubtitleStylingController.to;
      final style = stylingController.getSubtitleTextStyle();
      final textAlign = stylingController.settings.value.textAlign;
      final bottomPadding = stylingController.getSubtitlePadding();
      final primary = subtitleController.primaryText.value;
      final secondary = subtitleController.secondaryText.value;

      return Positioned.fill(
        child: IgnorePointer(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.of(context).textScaler.scale(1.0) *
                  sqrt(((constraints.maxWidth * constraints.maxHeight) /
                          (_referenceWidth * _referenceHeight))
                      .clamp(0.0, 1.0));
              final textScaler = TextScaler.linear(scale);

              return Stack(
                fit: StackFit.expand,
                children: [
                  if (secondary.isNotEmpty)
                    Container(
                      alignment: Alignment.topCenter,
                      padding: EdgeInsets.only(
                        top: 24,
                        left: bottomPadding.left,
                        right: bottomPadding.right,
                      ),
                      child: Text(
                        secondary,
                        style: style,
                        textAlign: textAlign,
                        textScaler: textScaler,
                      ),
                    ),
                  if (primary.isNotEmpty)
                    Container(
                      alignment: Alignment.bottomCenter,
                      padding: bottomPadding,
                      child: Text(
                        primary,
                        style: style,
                        textAlign: textAlign,
                        textScaler: textScaler,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}
