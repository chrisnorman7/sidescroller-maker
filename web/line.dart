import 'book.dart';

class Line {
  Line(
    {
      this.titleString,
      this.titleFunc,
      this.func,
      this.soundUrl,
    }
  );
  
  String titleString;
  String Function(Book) titleFunc, soundUrl;
  void Function(Book) func;

  String getTitle(Book book) {
    if (titleString == null) {
      return titleFunc(book);
    }
    return titleString;
  }
}
