import 'dart:async';
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

String stringPromptDefaultValue;

AnchorElement issueLink;
DivElement startDiv, mainDiv;
ParagraphElement keyboardArea, message;
TextAreaElement gameJson;
FormElement stringForm;
SpanElement stringPrompt;
TextInputElement stringInput;
ButtonInputElement startButton, stringCancel;

class GetText<T> {
  GetText(
    this.book,
    {
      this.prompt,
      this.value,
      this.onok,
      this.oncancel,
      this.emptyValueToNull = true,
    }
  ) {
    prompt ??= stringPromptDefaultValue;
    onok ??= (T value) => book.message(value.toString());
    oncancel ??= () {
      stringForm.reset();
      stringForm.hidden = true;
      keyboardArea.focus();
      book.showFocus();
    };
  }

  final Book book;
  String prompt;
  final T value;
  final bool emptyValueToNull;

  void Function(T value) onok;
  void Function() oncancel;
  StreamSubscription<Event> _cancelSubscription, _onkeydownSubscription, _onsubmitSubscription;

  void dispatch() {
    _cancelSubscription = stringCancel.onClick.listen((MouseEvent e) {
      stopListening();
      oncancel();
    });
    _onkeydownSubscription = stringForm.onKeyDown.listen((KeyboardEvent e) {
      if (e.key == 'Escape') {
        e.preventDefault();
        stopListening();
        oncancel();
      }
    });
    String stringValue;
    if (T == String) {
      stringValue = value as String;
    } else {
      stringValue = value.toString();
    }
    stringInput.value = stringValue;
    stringInput.setSelectionRange(0, -1);
    stringPrompt.innerText = prompt;
    stringForm.hidden = false;
    _onsubmitSubscription = stringForm.onSubmit.listen((Event e) {
        e.preventDefault();
        stopListening();
        stringForm.hidden = true;
        book.showFocus();
        final String stringValue = stringInput.value;
        keyboardArea.focus();
        if (stringValue.isEmpty && emptyValueToNull) {
          return onok(null);
        } else if (T == num) {
          onok(num.tryParse(stringValue) as T);
        } else if (T == String) {
          onok(stringValue as T);
        } else if (T == int) {
          onok(int.tryParse(stringValue) as T);
        } else {
          throw 'Unsure how to ast as <$T>.';
        }
    });
    stringInput.focus();
  }

  void stopListening() {
    _cancelSubscription.cancel();
    _onkeydownSubscription.cancel();
    _onsubmitSubscription.cancel();
  }
}

Page editLevelMenu(Level level) {
  final List<Line> lines = <Line>[
    Line(
      titleString: 'Play',
      func: (Book b) => level.play(
        book: b
      )
    ),
    Line(
      titleFunc: (Book b) => 'Rename (${level.titleString ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.titleString,
        onok: (String value) {
          if (value != level.titleString) {
            level.titleString = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Width (${level.size ?? "Not set"})',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: level.size,
        onok: (int value) {
          if (value != level.size) {
            level.size = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Start at (${level.initialPosition ?? "Not set"})',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: level.initialPosition,
        onok: (int value) {
          if (value != level.initialPosition) {
            level.initialPosition = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Player speed (${level.speed ?? "Not set"})',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: level.speed,
        onok: (int value) {
          if (value != level.speed) {
            level.speed = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Jump duration (${level.jumpDuration ?? "Not set"})',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: level.jumpDuration,
        onok: (int value) {
          if (value != level.jumpDuration) {
            level.jumpDuration = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Before jump sound (${level.beforeJumpUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.beforeJumpUrl,
        onok: (String value) {
          if (value != level.beforeJumpUrl) {
            level.beforeJumpUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.beforeJumpUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Jump sound (${level.jumpUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.jumpUrl,
        onok: (String value) {
          if (value != level.jumpUrl) {
            level.jumpUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.jumpUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Land sound (${level.landUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.landUrl,
        onok: (String value) {
          if (value != level.landUrl) {
            level.landUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.landUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Cancel jump sound (${level.cancelJumpUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.cancelJumpUrl,
        onok: (String value) {
          if (value != level.cancelJumpUrl) {
            level.cancelJumpUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.cancelJumpUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Before level scene (${level.beforeSceneUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.beforeSceneUrl,
        onok: (String value) {
          if (value != level.beforeSceneUrl) {
            level.beforeSceneUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.beforeSceneUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Footstep sound (${level.footstepUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.footstepUrl,
        onok: (String value) {
          if (value != level.footstepUrl) {
            level.footstepUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.footstepUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Wall sound (${level.wallUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.wallUrl,
        onok: (String value) {
          if (value != level.wallUrl) {
            level.wallUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.wallUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Turn sound (${level.turnUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.turnUrl,
        onok: (String value) {
          if (value != level.turnUrl) {
            level.turnUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.turnUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Trip sound (${level.tripUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.tripUrl,
        onok: (String value) {
          if (value != level.tripUrl) {
            level.tripUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.tripUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Ambiance (${level.ambianceUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.ambianceUrl,
        onok: (String value) {
          if (value != level.ambianceUrl) {
            level.ambianceUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.ambianceUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Level music (${level.musicUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.musicUrl,
        onok: (String value) {
          if (value != level.musicUrl) {
            level.musicUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.musicUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Impulse response (${level.convolverUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.convolverUrl,
        onok: (String value) {
          if (value != level.convolverUrl) {
            level.convolverUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Convolver volume (${level.convolverVolume ?? "Not set"})',
      func: (Book b) => GetText<num>(
        b,
        prompt: 'New value',
        value: level.convolverVolume,
        onok: (num value) {
          if (value != level.convolverVolume) {
            level.convolverVolume = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'No weapon sound (${level.noWeaponUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.noWeaponUrl,
        onok: (String value) {
          if (value != level.noWeaponUrl) {
            level.noWeaponUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => level.noWeaponUrl,
    ),
    Line(
      titleString: 'Delete',
      func: (Book b) => b.push(
        confirmPage(
          title: 'Are you sure you want to delete "${level.titleString}"?',
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
  ];
  return Page(
    titleFunc: (Book b) => 'Edit ${level.titleString}',
    lines: lines,
    playDefaultSounds: false,
  );
}

Page levelsMenu(Book b) {
  final List<Line> lines = <Line>[
    Line(
      titleString: 'Add Level',
      func: (Book b) {
        b.game.levels.add(Level(b.game));
        b.pop();
        b.push(levelsMenu(b));
      }
    )
  ];
  for (final Level level in b.game.levels) {
    lines.add(
      Line(
        titleFunc: (Book b) => level.titleString,
        func: (Book b) => b.push(
          editLevelMenu(level)
        )
      )
    );
  }
  return Page(
    titleFunc: (Book b) => 'Levels (${b.game.levels.length})',
    lines: lines
  );
}

Page editObjectMenu(GameObject object) {
  final List<Line> lines = <Line>[
    CheckboxLine(
      () => object.airborn,
      (Book b, bool value) {
        object.airborn = value;
        b.showFocus();
      },
      titleFunc: (Book b) => 'Airborn object (${object.airborn ? "Airborn" : "Grounded"})',
    ),
    Line(
      titleFunc: (Book b) => 'Rename (${object.title ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.title,
        onok: (String value) {
          if (value != object.title) {
            object.title = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Take sound (${object.takeUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.takeUrl,
        onok: (String value) {
          if (value != object.takeUrl) {
            object.takeUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => object.takeUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Drop sound (${object.dropUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.dropUrl,
        onok: (String value) {
          if (value != object.dropUrl) {
            object.dropUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => object.dropUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Use sound (${object.useUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.useUrl,
        onok: (String value) {
          if (value != object.useUrl) {
            object.useUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => object.useUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Not usable sound (${object.cantUseUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.cantUseUrl,
        onok: (String value) {
          if (value != object.cantUseUrl) {
            object.cantUseUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => object.cantUseUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Hit sound (${object.hitUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.hitUrl,
        onok: (String value) {
          if (value != object.hitUrl) {
            object.hitUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => object.hitUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Die sound (${object.dieUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.dieUrl,
        onok: (String value) {
          if (value != object.dieUrl) {
            object.dieUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => object.dieUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Ambiance (${object.soundUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.soundUrl,
        onok: (String value) {
          if (value != object.soundUrl) {
            object.soundUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => object.soundUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Weapon damage (${object.damage ?? "Not set"})',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: object.damage,
        onok: (int value) {
          if (value != object.damage) {
            object.damage = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Weapon range (${object.range ?? "Not set"})',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: object.range,
        onok: (int value) {
          if (value != object.range) {
            object.range = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Max health (${object.health ?? "Not set"})',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: object.health,
        onok: (int value) {
          if (value != object.health) {
            object.health = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Exit position (${object.targetPosition ?? "Not set"})',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: object.targetPosition,
        onok: (int value) {
          if (value != object.targetPosition) {
            object.targetPosition = value;
            b.showFocus();
          }
        }
      ).dispatch(),
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
      titleFunc: (Book b) => 'Target Level (${object.targetLevel == null ? "not set" : object.targetLevel.titleString})',
      func: (Book b) {
        final List<Line> lines = <Line>[];
        for (final Level level in b.game.levels) {
          lines.add(
            Line(
              titleFunc: (Book b) => '${object.targetLevel == level ? "* " : ""}${level.titleString}',
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
          object.contains,
          (void Function() after) {
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
    playDefaultSounds: false,
  );
}

Page objectsMenu(
  List<GameObject> objects,
  void Function(void Function() after) addObject,
  {
    void Function(GameObject) editObject
  }
) {
  assert(addObject != null, 'addObject must not be null.');
  final List<Line> lines = <Line>[
    Line(
      titleString: 'Add Object',
      func: (Book b) => addObject(() {
        b.pop();
        final Page page = objectsMenu(
          objects , addObject,
          editObject: editObject
        );
        page.focus = objects.length;
        b.push(page);
      })
    )
  ];
  for (final GameObject obj in objects) {
    lines.add(
      Line(
        titleFunc: (Book b) => obj.title,
        func: (Book b) => editObject(obj)
      )
    );
  }
  return Page(
    titleFunc: (Book b) => 'Objects (${objects.length})',
    lines: lines
  );
}

Page gameMenu(Game game) {
  final List<Line> lines = <Line>[
    Line(
      titleFunc: (Book b) => 'Rename (${game.title ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.title,
        onok: (String value) {
          if (value != game.title) {
            game.title = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Volume changed sound (${game.volumeSoundUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.volumeSoundUrl,
        onok: (String value) {
          if (value != game.volumeSoundUrl) {
            game.volumeSoundUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => game.volumeSoundUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Menu move sound (${game.moveSoundUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.moveSoundUrl,
        onok: (String value) {
          if (value != game.moveSoundUrl) {
            game.moveSoundUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => game.moveSoundUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Menu activate sound (${game.activateSoundUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.activateSoundUrl,
        onok: (String value) {
          if (value != game.activateSoundUrl) {
            game.activateSoundUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => game.activateSoundUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Menu music (${game.musicUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.musicUrl,
        onok: (String value) {
          if (value != game.musicUrl) {
            game.musicUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => game.musicUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Music fadeout multiplier (${game.musicFadeout ?? "Not set"})',
      func: (Book b) => GetText<num>(
        b,
        prompt: 'New value',
        value: game.musicFadeout,
        onok: (num value) {
          if (value != game.musicFadeout) {
            game.musicFadeout = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Volume control sensitivity (${game.volumeChangeAmount ?? "Not set"})',
      func: (Book b) => GetText<num>(
        b,
        prompt: 'New value',
        value: game.volumeChangeAmount,
        onok: (num value) {
          if (value != game.volumeChangeAmount) {
            game.volumeChangeAmount = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Initial sound volume (${game.initialVolume ?? "Not set"})',
      func: (Book b) => GetText<num>(
        b,
        prompt: 'New value',
        value: game.initialVolume,
        onok: (num value) {
          if (value != game.initialVolume) {
            game.initialVolume = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Initial music volume (${game.initialMusicVolume ?? "Not set"})',
      func: (Book b) => GetText<num>(
        b,
        prompt: 'New value',
        value: game.initialMusicVolume,
        onok: (num value) {
          if (value != game.initialMusicVolume) {
            game.initialMusicVolume = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Menu search timeout (${game.menuSearchTimeout ?? "Not set"})',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: game.menuSearchTimeout,
        onok: (int value) {
          if (value != game.menuSearchTimeout) {
            game.menuSearchTimeout = value;
            b.showFocus();
          }
        }
      ).dispatch(),
    ),
    Line(
      titleFunc: (Book b) => 'Search succeeded (${game.searchSuccessUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.searchSuccessUrl,
        onok: (String value) {
          if (value != game.searchSuccessUrl) {
            game.searchSuccessUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => game.searchSuccessUrl,
    ),
    Line(
      titleFunc: (Book b) => 'Search failed (${game.searchFailUrl ?? "Not set"})',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.searchFailUrl,
        onok: (String value) {
          if (value != game.searchFailUrl) {
            game.searchFailUrl = value;
            b.showFocus();
          }
        }
      ).dispatch(),
      soundUrl: (Book b) => game.searchFailUrl,
    ),
  ];
  return Page(
    titleFunc: (Book b) => 'Configure ${game.title}',
    lines: lines,
    playDefaultSounds: false,
  );
}

void main() {
      final Book book = Book();
      book.message = (String text) => message.innerText = text;
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
        if (mainGain == null) {
          soundVolume = 'Sound output not present';
        } else {
          soundVolume = mainGain.gain.value.toStringAsFixed(2);
        }
        if (game.music == null) {
          musicVolume = 'Music output not present';
        } else {
          musicVolume = game.music.output.gain.value.toStringAsFixed(2);
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
            if (book.game.objects.isEmpty) {
              return book.message('There are no objects you can spawn.');
            }
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
  startDiv.hidden = false;
  book.message('Finished loading.');
  startButton.onClick.listen(
    (MouseEvent e) {
      startAudio();
      startDiv.hidden = true;
      mainDiv.hidden = false;
      keyboardArea.focus();
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
                  b.game.objects,
                  (void Function() after) => GetText<String>(
                    b,
                    prompt: 'Object name',
                    onok: (String value) {
                      if (value.isNotEmpty) {
                        final GameObject obj = GameObject();
                        obj.title = value;
                        book.game.objects.add(obj);
                        after();
                      }
                    }
                  ).dispatch(),
                  editObject: (GameObject object) => b.push(
                    editObjectMenu(object)
                  )
                )
              )
            ),
            Line(
              titleString: 'Configure Game',
              func: (Book b) => b.push(
                gameMenu(b.game)
              )
            ),
            Line(
              titleString: 'JSON',
              func: (Book b) => b.push(
                Page(
                  titleString: 'JSON Menu',
                  lines: <Line>[
                    Line(
                      titleString: 'Load Game JSON',
                      func: (Book b) => b.push(
                        confirmPage(
                          title: 'Are you sure you want to reset your game and load from JSON?',
                          okTitle: 'Yes',
                          cancelTitle: 'No',
                          onok: (Book b) {
                            b.pop();
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
                        const JsonEncoder jsonEncoder = JsonEncoder.withIndent('  ');
                        final String json = jsonEncoder.convert(data);
                        gameJson.value = json;
                        gameJson.select();
                        gameJson.setSelectionRange(0, -1);
                        document.execCommand('copy');
                        keyboardArea.focus();
                        b.message('JSON copied.');
                      }
                    ),
                  ]
                )
              ),
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
                throw Exception('Error intentionally thrown by user.');
              }
            ),
          ],
        )
      );
    }
  );
  fists.type = ObjectTypes.weapon;
  fists.title = 'Fists';
}
