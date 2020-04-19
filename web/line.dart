import 'book.dart';

class Line {
  Line(
    {
      this.titleString,
      this.titleFunc,
      this.func,
    }
  );
  
  String titleString;
  String Function(Book) titleFunc;
  void Function(Book) func;

  String getTitle(Book book) {
    if (titleString == null) {
      return titleFunc(book);
    }
    return titleString;
  }
}
