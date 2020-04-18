import 'page.dart';

class Hotkey {
  Hotkey(
    {
      this.descriptionString,
      this.descriptionFunc,
      this.func,
    }
  );

  String getDescription(
    {
      Page page
    }
  ) {
    if (descriptionFunc == null) {
      return descriptionString;
    }
    return descriptionFunc(page);
  }

  final String descriptionString;
  String Function(Page) descriptionFunc;
  void Function() func;
}
