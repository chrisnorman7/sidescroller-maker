import 'book.dart';

class Line{
  Line(
    {
      this.titleString,
      this.titleFunc,
      this.func,
    }
  );

  final String titleString;
  void Function(Book) func;
  String Function(Book) titleFunc;
}
