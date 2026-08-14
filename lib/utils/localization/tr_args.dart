import 'package:get/get.dart';

extension TrArgs on String {
  /// Localizes this key and substitutes [args] into `%s`, `%d`, `%1$s`,
  /// `%1$d` style placeholders present in the translation string.
  String trArgsFmt(List<Object> args) {
    var result = tr;
    if (args.isNotEmpty) {
      result = result
          .replaceFirst('%s', args.first.toString())
          .replaceFirst('%d', args.first.toString());
    }
    for (var i = 0; i < args.length; i++) {
      result = result
          .replaceFirst('%${i + 1}\$s', args[i].toString())
          .replaceFirst('%${i + 1}\$d', args[i].toString());
    }
    return result;
  }
}
