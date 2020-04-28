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
      this.multiline = false,
    }
  ) {
    if (T != String && multiline) {
      throw 'You cannot specify multiline with a non-String value.';
    }
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
  final bool multiline;
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
        if (T == num) {
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
      titleString: 'Rename',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.titleString,
        onok: (String value) {
          if (value != level.titleString) {
            level.titleString = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
    ),
    Line(
      titleString: 'Width',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: level.size,
        onok: (int value) {
          if (value != level.size) {
            level.size = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
    ),
    Line(
      titleString: 'Start at',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: level.initialPosition,
        onok: (int value) {
          if (value != level.initialPosition) {
            level.initialPosition = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
    ),
    Line(
      titleString: 'Player speed',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: level.speed,
        onok: (int value) {
          if (value != level.speed) {
            level.speed = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
    ),
    Line(
      titleString: 'Before scene URL',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.beforeSceneUrl,
        onok: (String value) {
          if (value != level.beforeSceneUrl) {
            level.beforeSceneUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
      soundUrl: level.beforeSceneUrl,
    ),
    Line(
      titleString: 'Footstep sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.footstepUrl,
        onok: (String value) {
          if (value != level.footstepUrl) {
            level.footstepUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
      soundUrl: level.footstepUrl,
    ),
    Line(
      titleString: 'Wall sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.wallUrl,
        onok: (String value) {
          if (value != level.wallUrl) {
            level.wallUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
      soundUrl: level.wallUrl,
    ),
    Line(
      titleString: 'Turn sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.turnUrl,
        onok: (String value) {
          if (value != level.turnUrl) {
            level.turnUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
      soundUrl: level.turnUrl,
    ),
    Line(
      titleString: 'Trip sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.tripUrl,
        onok: (String value) {
          if (value != level.tripUrl) {
            level.tripUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
      soundUrl: level.tripUrl,
    ),
    Line(
      titleString: 'Ambiance',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.ambianceUrl,
        onok: (String value) {
          if (value != level.ambianceUrl) {
            level.ambianceUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
      soundUrl: level.ambianceUrl,
    ),
    Line(
      titleString: 'Level music',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.musicUrl,
        onok: (String value) {
          if (value != level.musicUrl) {
            level.musicUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
      soundUrl: level.musicUrl,
    ),
    Line(
      titleString: 'Impulse response',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.convolverUrl,
        onok: (String value) {
          if (value != level.convolverUrl) {
            level.convolverUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
    ),
    Line(
      titleString: 'Convolver volume',
      func: (Book b) => GetText<num>(
        b,
        prompt: 'New value',
        value: level.convolverVolume,
        onok: (num value) {
          if (value != level.convolverVolume) {
            level.convolverVolume = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
    ),
    Line(
      titleString: 'No weapon sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: level.noWeaponUrl,
        onok: (String value) {
          if (value != level.noWeaponUrl) {
            level.noWeaponUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch(),
      soundUrl: level.noWeaponUrl,
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
        b.game.levels.add(Level());
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
    Line(
      titleString: 'Rename',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.title,
        onok: (String value) {
          if (value != object.title) {
            object.title = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Take sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.takeUrl,
        onok: (String value) {
          if (value != object.takeUrl) {
            object.takeUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Drop sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.dropUrl,
        onok: (String value) {
          if (value != object.dropUrl) {
            object.dropUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Use sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.useUrl,
        onok: (String value) {
          if (value != object.useUrl) {
            object.useUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Not usable sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.cantUseUrl,
        onok: (String value) {
          if (value != object.cantUseUrl) {
            object.cantUseUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Hit sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.hitUrl,
        onok: (String value) {
          if (value != object.hitUrl) {
            object.hitUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Die sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.dieUrl,
        onok: (String value) {
          if (value != object.dieUrl) {
            object.dieUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Ambiance',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: object.soundUrl,
        onok: (String value) {
          if (value != object.soundUrl) {
            object.soundUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Weapon damage',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: object.damage,
        onok: (int value) {
          if (value != object.damage) {
            object.damage = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Weapon range',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: object.range,
        onok: (int value) {
          if (value != object.range) {
            object.range = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Max health',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: object.health,
        onok: (int value) {
          if (value != object.health) {
            object.health = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Position to exit from',
      func: (Book b) => GetText<int>(
        b,
        prompt: 'New value',
        value: object.targetPosition,
        onok: (int value) {
          if (value != object.targetPosition) {
            object.targetPosition = value;
            b.message('Done.');
          }
        }
      ).dispatch()
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
      titleString: 'Rename',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.title,
        onok: (String value) {
          if (value != game.title) {
            game.title = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Volume changed sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.volumeSoundUrl,
        onok: (String value) {
          if (value != game.volumeSoundUrl) {
            game.volumeSoundUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Menu move sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.moveSoundUrl,
        onok: (String value) {
          if (value != game.moveSoundUrl) {
            game.moveSoundUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Menu activate sound',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.activateSoundUrl,
        onok: (String value) {
          if (value != game.activateSoundUrl) {
            game.activateSoundUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Menu music',
      func: (Book b) => GetText<String>(
        b,
        prompt: 'New value',
        value: game.musicUrl,
        onok: (String value) {
          if (value != game.musicUrl) {
            game.musicUrl = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Volume control sensitivity',
      func: (Book b) => GetText<num>(
        b,
        prompt: 'New value',
        value: game.volumeChangeAmount,
        onok: (num value) {
          if (value != game.volumeChangeAmount) {
            game.volumeChangeAmount = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Initial sound volume',
      func: (Book b) => GetText<num>(
        b,
        prompt: 'New value',
        value: game.initialVolume,
        onok: (num value) {
          if (value != game.initialVolume) {
            game.initialVolume = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
    Line(
      titleString: 'Initial music volume',
      func: (Book b) => GetText<num>(
        b,
        prompt: 'New value',
        value: game.initialMusicVolume,
        onok: (num value) {
          if (value != game.initialMusicVolume) {
            game.initialMusicVolume = value;
            b.message('Done.');
          }
        }
      ).dispatch()
    ),
  ];
  return Page(
    titleFunc: (Book b) => 'Configure ${game.title}',
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
  book.message = (String text) => message.innerText = text;
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
