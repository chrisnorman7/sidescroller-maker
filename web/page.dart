import 'dart:html';

import 'book.dart';
import 'constants.dart';
import 'hotkey.dart';
import 'line.dart';

class Page {
  Page(
    {
      this.titleString,
      this.titleFunc,
      this.lines = const <Line>[],
      this.dismissible = true,
      this.playDefaultSounds = true,
    }
  );

  bool isLevel = false, playDefaultSounds;
  final bool dismissible;
  int focus = -1;
  final List<Line> lines;
  String titleString;
  TitleFunctionType titleFunc;
  
  String getTitle(Book book) {
    if (titleString == null) {
      return titleFunc(book);
    }
    return titleString;
  }

  Line getLine() {
    if (focus == -1) {
      return null;
    }
    return lines[focus];
  }
}

Page confirmPage(
  {
    String title = 'Are you sure?',
    String okTitle = 'OK',
    String cancelTitle = 'Cancel',
    BookFunctionType onok,
    BookFunctionType oncancel ,
  }
) {
  final List<Line> lines = <Line>[
    Line(
      titleString: okTitle,
      func: onok ?? (Book b) => b.pop(),
    ),
    Line(
      titleString: cancelTitle,
      func: oncancel ?? (Book b) => b.pop(),
    )
  ];
  return Page(
    titleString: title,
    lines: lines,
  );
}

Page voicesPage() {
  final List<Line> lines = <Line>[];
  final List<SpeechSynthesisVoice>voices = window.speechSynthesis.getVoices()
  ..sort(
    (SpeechSynthesisVoice a, SpeechSynthesisVoice b) => a.name.toUpperCase().compareTo(b.name.toUpperCase())
  );
  for (final SpeechSynthesisVoice voice in voices) {
    lines.add(
      Line(
        titleFunc: (Book b) => '${(voice == textToSpeech.voice) ? "* " : ""}${voice.name}${voice.defaultValue ? " (Default)" : ""}',
        func: (Book b) {
          textToSpeech.voice = voice;
          b.pop();
        }
      )
    );
  }
  return Page(
    titleString: 'Available Voices',
    lines: lines
  );
}

Page ratePage() {
  final List<Line> lines = <Line>[
    Line(
      titleString: 'Decrease',
      func: (Book b) {
        textToSpeech.rate -= 0.1;
        b.pop();
      }
    ),
    Line(
      titleString: 'Increase',
      func: (Book b) {
        textToSpeech.rate += 0.1;
        b.pop();
      }
    ),
  ];
  return Page(
    titleFunc: (Book b) => 'Voice Rate ($textToSpeech.rate)',
    lines: lines,
  );
}

Page ttsSettingsPage() {
  final List<Line> lines = <Line>[
    Line(
      titleFunc: (Book b) => 'Change Voice (${textToSpeech.voice == null ? "not set" : textToSpeech.voice.name})',
      func: (Book b) => b.push(voicesPage())
    ),
    Line(
      titleFunc: (Book b) => 'Change Rate (${textToSpeech.rate})',
      func: (Book b) => b.push(ratePage())
    ),
  ];
  return Page(
    titleString: 'Configure TTS',
    lines: lines
  );
}

Page hotkeysPage(Book book) {
  const Map<String, String> hotkeyConvertions = <String, String>{
    ' ': 'Spacebar',
  };
  final List<Line> lines = <Line>[];
  book.hotkeys.forEach(
    (String key, Hotkey hotkey) {
      String keyString = key;
      if (hotkeyConvertions.containsKey(keyString)) {
        keyString = hotkeyConvertions[keyString];
      }
      lines.add(
        Line(
          titleFunc: (Book b) => '$keyString: ${hotkey.getTitle(b.getPage())}',
          func: (Book b) {
            b.pop();
            hotkey.func(b);
          }
        )
      );
    }
  );
  return Page(
    titleString: 'Hotkeys',
    lines: lines,
  );
}
