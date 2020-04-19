import 'book.dart';
import 'page.dart';

class Hotkey {
  Hotkey(
    {
      this.titleString,
      this.titleFunc,
      this.func,
    }
  );

  String titleString;
  String Function(Page) titleFunc;
  void Function(Book) func;

  String getTitle(
    {
      Page page,
    }
  ) {
    if (titleString == null) {
      return titleFunc(page);
    }
    return titleString;
  }
}
