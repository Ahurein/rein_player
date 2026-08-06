import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rein_player/common/widgets/rp_snackbar.dart';
import 'package:rein_player/utils/constants/rp_colors.dart';
import 'package:rein_player/utils/constants/app_info.dart';
import 'package:rein_player/utils/localization/locale_keys.dart';
import 'package:rein_player/utils/localization/tr_args.dart';
import 'package:url_launcher/url_launcher.dart';

class RpAboutDialog extends StatefulWidget {
  const RpAboutDialog({super.key});

  @override
  State<RpAboutDialog> createState() => _RpAboutDialogState();
}

class _RpAboutDialogState extends State<RpAboutDialog> {
   String _version = AppInfo.version;
   String _buildNumber = AppInfo.buildNumber;
  final String _description = AppInfo.description;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      // do nothing
    }
  }

  Future<void> _openGitHub() async {
    try {
      await launchUrl(Uri.parse(AppInfo.repository));
    } catch (e) {
      RpSnackbar.error(message: LocaleKeys.snackErrorLaunchingUrl.trArgsFmt([e]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: RpColors.gray_900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/reinplayer.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to icon if image fails to load
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: RpColors.gray_800,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.play_circle_outline,
                        size: 48,
                        color: RpColors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // App Name
              Text(
                AppInfo.appName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: RpColors.white,
                    ),
              ),
              const SizedBox(height: 8),

              // Version
              Text(
                LocaleKeys.aboutVersion.trArgsFmt([
                  '$_version${_buildNumber.isNotEmpty ? '+$_buildNumber' : ''}'
                ]),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: RpColors.white_300,
                    ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                _description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: RpColors.white_50,
                    ),
              ),
              const SizedBox(height: 16),

              // GitHub Link
              InkWell(
                onTap: _openGitHub,
                child: Text(
                  LocaleKeys.aboutViewOnGitHub.tr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade400,
                      ),
                ),
              ),
              const SizedBox(height: 16),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RpColors.accent,
                    foregroundColor: RpColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(LocaleKeys.close.tr),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
