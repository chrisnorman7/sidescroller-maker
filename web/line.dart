import 'book.dart';
import 'constants.dart';

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
  TitleFunctionType titleFunc, soundUrl;
  BookFunctionType func;

  String getTitle(Book book) {
    if (titleString == null) {
      return titleFunc(book);
    }
    return titleString;
  }
}
