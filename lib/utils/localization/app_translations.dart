import 'package:get/get.dart';

import 'translations/de.dart';
import 'translations/en.dart';
import 'translations/es.dart';
import 'translations/fr.dart';
import 'translations/ja.dart';
import 'translations/ko.dart';
import 'translations/ru.dart';
import 'translations/zh_CN.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en': EnTranslations.translations,
        'zh_CN': ZhCnTranslations.translations,
        'ja': JaTranslations.translations,
        'ko': KoTranslations.translations,
        'fr': FrTranslations.translations,
        'de': DeTranslations.translations,
        'es': EsTranslations.translations,
        'ru': RuTranslations.translations,
      };
}