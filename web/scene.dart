import 'dart:html';

import 'book.dart';
import 'sound.dart';

class Scene {
  Scene(
    {
      this.book,
      this.url,
      this.onfinish,
    }
  ) {
    completed = false;
    sound = Sound(
      url: url
    );
    sound.onEnded = done;
  }

  void done(Event e) {
    if (completed) {
      return;
    }
    completed = true;
    book.scene = null;
    sound.stop();
    onfinish(book);
  }
  
  bool completed = false;
  Sound sound;
  final Book book;
  final String url;
  void Function(Book) onfinish;
}
