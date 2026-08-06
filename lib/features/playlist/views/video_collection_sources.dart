import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/rp_colors.dart';
import '../../../utils/localization/locale_keys.dart';

class RpVideoCollectionSources extends StatelessWidget {
  const RpVideoCollectionSources({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RpColors.gray_900,
      child: Row(
        children: [
          InkWell(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 13),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(width: 1, color: RpColors.black),
                  right: BorderSide(width: 0.5, color: RpColors.black),
                  bottom: BorderSide(width: 1, color: RpColors.black),
                ),
              ),
              child: Center(
                child: Text(
                  LocaleKeys.menuPlaylist.tr,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(color: RpColors.black_300),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
