import 'book.dart';
import 'constants.dart';
import 'sound.dart';

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

class CheckboxLine extends Line {
  CheckboxLine(
    bool Function() getValue,
    void Function(Book, bool) setValue,
    {
      String titleString,
      TitleFunctionType titleFunc,
      String enableUrl = 'res/menus/enable.wav',
      String disableUrl = 'res/menus/disable.wav',
    }
  ): super(
    titleString: titleString,
    titleFunc: titleFunc,
    func: (Book b) {
      final bool oldValue = getValue();
      final bool newValue = !oldValue;
      final String soundUrl = newValue ? enableUrl : disableUrl;
      Sound().play(url: soundUrl);
      setValue(b, newValue);
    },
  );
}
