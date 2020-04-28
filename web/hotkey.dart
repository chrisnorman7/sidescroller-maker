import 'book.dart';
import 'page.dart';

class Hotkey {
  Hotkey(
    {
      this.titleString,
      this.titleFunc,
      this.func,
      this.levelOnly = false,
    }
  );

  String titleString;
  String Function(Page) titleFunc;
  void Function(Book) func;
  bool levelOnly;

  String getTitle(Page page,) {
    if (titleString == null) {
      return titleFunc(page);
    }
    return titleString;
  }
}
