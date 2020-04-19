import 'dart:convert';
import 'dart:html';

import 'book.dart';
import 'constants.dart';
import 'game.dart';
import 'level.dart';
import 'line.dart';
import 'object.dart';
import 'page.dart';
import 'player.dart';
import 'utils.dart';

String stringPromptDefaultValue, textPromptDefaultValue;

AnchorElement issueLink;
DivElement startDiv, mainDiv;
ParagraphElement keyboardArea, message;
TextAreaElement gameJson, textInput;
FormElement stringForm, textForm;
SpanElement stringPrompt, textPrompt;
TextInputElement stringInput;
ButtonInputElement startButton, stringCancel, textCancel;

void getText(
  {
    Book book,
    String prompt,
    String value = '',
    bool multiline = false,
    void Function(
      {
        String value,
        Book book,
      }
    ) onok,
    void Function(
      {
        FormElement form,
        Book book,
      }
    ) oncancel,
  }
) {
  if (prompt == null) {
    if (multiline) {
      prompt = textPromptDefaultValue;
    } else {
      prompt = stringPromptDefaultValue;
    }
  }
  onok ??= (
    {
      String value,
      Book book
    }
  ) => book.message(value);
  oncancel ??= (
    {
      FormElement form,
      Book book,
    }
  ) {
    form.reset();
    form.hidden = true;
    keyboardArea.focus();
    book.showFocus();
  };
  FormElement form;
  SpanElement promptElement;
  dynamic inputElement;
  ButtonInputElement cancelElement;
  if (multiline) {
    form = textForm;
    promptElement = textPrompt;
    inputElement = textInput;
    cancelElement = textCancel;
  } else {
    form = stringForm;
    promptElement = stringPrompt;
    inputElement = stringInput;
    cancelElement = stringCancel;
  }
  cancelElement.onClick.listen(
    (MouseEvent e) => oncancel(
      form: form,
      book: book
    )
  );
  form.onKeyDown.listen(
    (KeyboardEvent e) {
      if (e.key == 'Escape') {
        e.preventDefault();
        oncancel(
          form: form,
          book: book
        );
      }
    }
  );
  inputElement.value = value;
  inputElement.setSelectionRange(0, -1);
  promptElement.innerText = prompt;
  form.hidden = false;
  form.onSubmit.listen(
    (Event e) {
      e.preventDefault();
      form.hidden = true;
      book.showFocus();
      onok(
        value: inputElement.value as String,
        book: book
      );
      keyboardArea.focus();
    }
  );
  inputElement.focus();
}

Page editLevelMenu(
  {
    Book b,
    Level level,
  }
) {
  final List<Line> lines = <Line>[
    Line(
      titleString: 'Rename',
      func: (Book b) => getText(
        book: b,
        prompt: 'Enter new level name',
        value: level.title,
        onok: (
          {
            String value,
            Book book
          }
        ) {
          if (value.isNotEmpty && value != level.title) {
            level.title = value;
            book.message('Level renamed.');
          }
        }
      )
    ),
    Line(
      titleString: 'Play',
      func: (Book b) => level.play(
        book: b
      )
    ),
  ];
  lines.add(
    Line(
      titleString: 'Delete',
      func: (Book b) => b.push(
        confirmPage(
          title: 'Are you sure you want to delete "${level.title}"?',
          okTitle: 'Yes',
          cancelTitle: 'No',
          onok: (Book b) {
            final int index = b.game.levels.indexOf(level);
            b.game.levels.removeAt(index);
            for (int i = 0; i < 2; i++) {
              b.pop();
            }
            b.push(levelsMenu(b));
            b.message('Level deleted.');
          }
        )
      )
    )
  );
  return Page(
    titleFunc: (Book b) => 'Edit ${level.title}',
    lines: lines
  );
}

Page levelsMenu(Book b) {
  final List<Line> lines = <Line>[
    Line(
      titleString: 'Add Level',
      func: (Book b) {
        b.game.levels.add(Level());
        b.pop();
        b.push(levelsMenu(b));
      }
    )
  ];
  for (final Level level in b.game.levels) {
    lines.add(
      Line(
        titleFunc: (Book b) => level.title,
        func: (Book b) => b.push(
          editLevelMenu(
            level: level
          )
        )
      )
    );
  }
  return Page(
    titleFunc: (Book b) => 'Levels (${b.game.levels.length})',
    lines: lines
  );
}

Page editObjectMenu(
  {
    GameObject object,
  }
) {
  final List<Line> lines = <Line>[
    Line(
      titleString: 'Rename',
      func: (Book b) => getText(
        book: b,
        prompt: 'New title',
        value: object.title,
        onok: (
          {
            String value,
            Book book,
          }
        ) {
          if (value.isNotEmpty) {
            object.title = value;
          }
          book.showFocus();
        }
      )
    ),
    Line(
      titleFunc: (Book b) => 'Set Type (${objectTypeDescriptions[object.type]})',
      func: (Book b) {
        final List<Line> lines = <Line>[];
        for (final ObjectTypes member in ObjectTypes.values) {
          final String description = objectTypeDescriptions[member];
          lines.add(
            Line(
              titleFunc: (Book b) => '${object.type == member ? "* " : ""}$description',
              func: (Book b) {
                object.type = member;
                b.pop();
                b.message('Type changed.');
              }
            )
          );
        }
        b.push(
          Page(
            titleString: 'Set Object Type',
            lines: lines,
          )
        );
      }
    ),
    Line(
      titleFunc: (Book b) => 'Target Level (${object.targetLevel == null ? "not set" : object.targetLevel.title})',
      func: (Book b) {
        final List<Line> lines = <Line>[];
        for (final Level level in b.game.levels) {
          lines.add(
            Line(
              titleFunc: (Book b) => '${object.targetLevel == level ? "8 " : ""}${level.title}',
              func: (Book b) {
                object.targetLevel = level;
                b.pop();
                b.message('Level set.');
              }
            )
          );
        }
        b.push(
          Page(
            titleString: 'Set exit destination',
            lines: lines
          )
        );
      }
    ),
    Line(
      titleFunc: (Book b) => 'Contained Objects (${object.contains.length})',
      func: (Book b) => b.push(
        objectsMenu(
          objects: object.contains,
          addObject: (
            {
              Book book,
              void Function() after,
            }
          ) {
            final List<Line> objectLines = <Line>[];
            for (final GameObject o in b.game.objects) {
              objectLines.add(
                Line(
                  titleString: o.title,
                  func: (Book b) {
                    object.contains.add(o);
                    b.pop();
                    after();
                  }
                )
              );
            }
            b.push(
              Page(
                titleString: 'Select Object',
                lines: objectLines,
              )
            );
          },
        )
      )
    ),
  ];
  return Page(
    titleFunc: (Book b) => 'Edit ${object.title}',
    lines: lines,
  );
}

Page objectsMenu(
  {
    List<GameObject> objects,
    void Function({Book book, void Function() after}) addObject,
    void Function({GameObject object}) editObject
  }
) {
  final List<Line> lines = <Line>[
    Line(
      titleString: 'Add Object',
      func: (Book b) => addObject(
        book: b,
        after: () {
          b.pop();
          final Page page = objectsMenu(
            objects: objects ,
            addObject: addObject,
            editObject: editObject
          );
          page.focus = objects.length;
          b.push(page);
        }
      )
    )
  ];
  for (final GameObject obj in objects) {
    lines.add(
      Line(
        titleFunc: (Book b) => obj.title,
        func: (Book b) => editObject(
          object: obj
        )
      )
    );
  }
  return Page(
    titleFunc: (Book b) => 'Objects (${objects.length})',
    lines: lines
  );
}

Page gameMenu(
  {
    Game game
  }
) {
  final List<Line> lines = <Line>[
    Line(
      titleString: 'Rename',
      func: (Book b) => getText(
        book: b,
        prompt: 'Enter a new name',
        value: game.title,
        onok: (
          {
            String value,
            Book book,
          }
        ) {
          if (value.isEmpty) {
            value = game.title;
          }
          game.title = value;
        }
      )
    ),
  ];
  return Page(
    titleString: 'Game Menu',
    lines: lines
  );
}

void main() {
  final Book book = Book();
  issueLink = querySelector('#issueLink') as AnchorElement;
  startDiv = querySelector('#startDiv') as DivElement;
  mainDiv = querySelector('#main') as DivElement;
  keyboardArea = querySelector('#keyboardArea') as ParagraphElement;
  gameJson = querySelector('#gameJson') as TextAreaElement;
  startButton = querySelector('#startButton') as ButtonInputElement;
  message = querySelector('#message') as ParagraphElement;
  stringForm = querySelector('#stringForm') as FormElement;
  stringPrompt = querySelector('#stringPrompt') as SpanElement;
  stringPromptDefaultValue = stringPrompt.innerText;
  stringInput = document.querySelector('#stringInput') as TextInputElement;
  stringCancel = querySelector('#stringCancel') as ButtonInputElement;
  final Element textForm = querySelector('#textForm');
  textPrompt = querySelector('#textPrompt') as SpanElement;
  textPromptDefaultValue = textPrompt.innerText;
  textInput = querySelector('#textInput') as TextAreaElement;
  textCancel = querySelector('#textCancel') as ButtonInputElement;
  for (final Element e in <Element>[mainDiv, stringForm, textForm]) {
    if (e == null) {
      throw Exception('Check selectors and try again.');
    }
    e.hidden = true;
  }
  final String issueUrl = issueLink.href;
  issueLink.onClick.listen(
    (MouseEvent e) {
      issueLink.href = issueUrl; // Fallback in case something breaks
      String title, soundVolume, musicVolume;
      String body = '';
      try {
        Player player;
        Game game;
        if (book == null) {
          title = 'before start button has been clicked';
        } else {
          game = book.game;
          player = book.player;
          if (game == null) {
            title = 'with a null game';
          } else {
            final Page page = book.getPage();
            if (page == null) {
              title = 'with no page pushed';
            } else {
              String type, lineTitle;
              if (page.isLevel) {
                type = 'level';
                String facing;
                if (player.facing == LevelDirections.forwards) {
                  facing = 'forwards';
                } else if (player.facing == LevelDirections.backwards) {
                  facing = 'backwards';
                } else if (player.facing == LevelDirections.either) {
                  facing = 'either way';
                } else {
                  facing = player.facing.toString();
                }
                lineTitle = 'at position ${player.position}, facing $facing';
              } else {
                final Line line = page.getLine();
                type = 'page';
                if (line == null) {
                  lineTitle = 'not focussed on any particular line';
                } else {
                  lineTitle = 'focussed on a line called "${line.getTitle(book)}"';
                }
              }
              title = 'with a ${book.pages.length} deep $type called "${page.getTitle(book)}", $lineTitle';
            }
          }
        }
        if (gain == null) {
          soundVolume = 'Sound output not present';
        } else {
          soundVolume = gain.gain.value.toStringAsFixed(2);
        }
        if (musicGain == null) {
          musicVolume = 'Music output not present';
        } else {
          musicVolume = musicGain.gain.value.toStringAsFixed(2);
          String presentString = 'present';
          if (game.music == null || game.music.source == null) {
            presentString = 'not $presentString';
          }
          musicVolume += ' (music $presentString)';
        }
        final Map<String, String> stats = <String, String>{
          'Sound volume': soundVolume,
          'Music volume': musicVolume,
          'Languages': englishList(
            items: window.navigator.languages
          ),
          'Platform': window.navigator.platform ?? 'Unknown',
        };
        if (player != null) {
          final List<String> carrying = <String>[];
          for (final GameObject obj in player.carrying) {
            carrying.add(obj.title);
          }
          stats['Player health'] = player.health.toString();
          stats['Player carrying'] = englishList(
            items: carrying,
          );
          String weaponTitle = 'Unarmed';
          if (player.weapon != null) {
            weaponTitle = player.weapon.title;
          }
          stats['Weapon'] = weaponTitle;
        }
        stats.forEach(
          (String key, String value) => body += '\n$key: $value'
        );
        body += '\n\nSteps to reproduce:\n1. \n2. \n3. \n';
        title = 'Problem $title';
      } catch(e) {
        title = 'Issue while running onclick handler';
        body = 'Error: ${e.message}';
      }
      issueLink.href = '$issueUrl?title=${Uri.encodeQueryComponent(title)}&body=${Uri.encodeQueryComponent(body)}';
    }
  );
  keyboardArea.onKeyDown.listen(
    (KeyboardEvent e) {
      if (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey ) {
        return; // Don't work with modifiers.
      }
      try {
        final Page page = book.getPage();
        if (page.isLevel) {
          final Level level = book.player.level;
          if (e.key == 'Escape') {
            return book.player.level.leave(book);
          } else if (e.key == 'o') {
            final List<Line> lines = <Line>[];
            for (final GameObject obj in book.game.objects) {
              lines.add(
                Line(
                  titleString: obj.title,
                  func: (Book b) {
                    obj.drop(
                      level: level,
                      position: b.player.position,
                      silent: true,
                    );
                    b.pop();
                  }
                )
              );
            }
            return book.push(
              Page(
                titleString: 'Add Object',
                lines: lines,
              )
            );
          }
        }
        book.onkeydown(e);
      } catch(e) {
        book.message(e.toString(),);
        rethrow;
      }
    }
  );
  startButton.onClick.listen(
    (MouseEvent e) {
      startAudio();
      startDiv.hidden = true;
      mainDiv.hidden = false;
      keyboardArea.focus();
      book.message = (String text) => message.innerText = text;
      book.push(
        Page(
          titleString: 'Main Menu',
          dismissible: false,
          lines: <Line>[
            Line(
              titleString: 'Levels',
              func: (Book b) => b.push(levelsMenu(b))
            ),
            Line(
              titleString: 'Objects and Monsters',
              func: (Book b) => b.push(
                objectsMenu(
                  objects: b.game.objects,
                  addObject: (
                    {
                      Book book,
                      void Function() after
                    }
                  ) => getText(
                    book: b,
                    prompt: 'Enter the name for the new object',
                    onok: (
                      {
                        String value,
                        Book book
                      }
                    ) {
                      if (value.isNotEmpty) {
                        final GameObject obj = GameObject();
                        obj.title = value;
                        book.game.objects.add(obj);
                        after();
                      }
                    }
                  ),
                  editObject: (
                    {
                      Book book,
                      GameObject object
                    }
                  ) => book.push(
                    editObjectMenu(
                      object: object
                    )
                  )
                )
              )
            ),
            Line(
              titleString: 'Configure Game',
              func: (Book b) => b.push(
                gameMenu(
                  game: b.game
                )
              )
            ),
            Line(
              titleString: 'Load Game JSON',
              func: (Book b) => b.push(
                confirmPage(
                  title: 'Are you sure you want to reset your game and load from JSON?',
                  onok: (Book b) {
                    b.pop();
                    final Map<String, dynamic> data = jsonDecode(gameJson.value) as Map<String, dynamic>;
                    b.game.stopMusic();
                    b.game = Game.fromJson(
                      data: data
                    );
                    b.game.reloadMusic(b);
                    b.message('Game loaded.');
                  }
                )
              )
            ),
            Line(
              titleString: 'Copy Game JSON',
              func: (Book b) {
                final Map<String, dynamic> data = b.game.toJson();
                final String json = jsonEncode(data);
                gameJson.value = json;
                gameJson.select();
                gameJson.setSelectionRange(0, -1);
                document.execCommand('copy');
                keyboardArea.focus();
                b.message('JSON copied.');
              }
            ),
            Line(
              titleString: 'Reset Game',
              func: (Book b) => b.push(
                confirmPage(
                  title: 'Are you sure you want to reset the game?',
                  onok: (Book b) {
                    b.game.reset();
                    b.pop();
                    b.message('Game reset.');
                  }
                )
              )
            ),
            Line(
              titleString: 'TTS Settings',
              func: (Book b) => b.push(ttsSettingsPage())
            ),
            Line(
              titleString: 'Throw an Error',
              func: (Book b) {
                b.pop();
                throw Exception('Error intentionally thrown by user.');
              }
            ),
          ],
        )
      );
    }
  );
}
