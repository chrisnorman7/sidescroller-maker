import 'dart:html';
import 'dart:math';
import 'dart:web_audio';

import 'constants.dart';
import 'game.dart';
import 'hotkey.dart';
import 'level.dart';
import 'line.dart';
import 'object.dart';
import 'page.dart';
import 'player.dart';
import 'scene.dart';
import 'sound.dart';
import 'utils.dart';

class Book{
  Book() {
    game = Game();
    const String activateString = 'Activate a menu item"';
    const String cancelString = 'Return to the previous menu';
    hotkeys = <String, Hotkey>{
      'ArrowUp': Hotkey(
        titleFunc: (Page page) {
          if (page.isLevel) {
            return 'Jump';
          }
          return 'Move up in a menu';
        },
        func: (Book b) => moveUp(),
      ),
      'ArrowDown': Hotkey(
        titleString: 'Move down in a menu',
        func: (Book b) => moveDown(),
      ),
      ' ': Hotkey(
        titleFunc: (Page page) {
          if (page.isLevel) {
            return 'Use a weapon';
          }
          return activateString;
        },
        func: (Book b) => shootOrActivate(),
      ),
      'ArrowRight': Hotkey(
        titleFunc: (Page page) {
          if (page.isLevel) {
            return 'Move right';
          }
          return activateString;
        },
        func: (Book b) => moveOrActivate(),
      ),
      'Enter': Hotkey(
        titleFunc: (Page page) {
          if (page.isLevel) {
            return 'Take the object at your current location';
          }
          return activateString;
        },
        func: (Book b) => takeOrActivate(),
      ),
      'ArrowLeft': Hotkey(
        titleFunc: (Page page) {
          if (page.isLevel) {
            return 'Move left';
          }
          return cancelString;
        },
        func: (Book b) => cancel(),
      ),
      'Escape': Hotkey(
        titleString: 'Return to the previous menu',
        func: (Book b) => cancel(),
      ),
      '[': Hotkey(
        titleString: 'Decrease sound volume',
        func: (Book b) => volumeDown(
          output: gain
        ),
      ),
      ']': Hotkey(
        titleString: 'Increase sound volume',
        func: (Book b) => volumeUp(
          output: gain
        ),
      ),
      '-': Hotkey(
        titleString: 'Decrease music volume',
        func: (Book b) => volumeDown(
          output: musicGain
        ),
      ),
      '=': Hotkey(
        titleString: 'Increase music volume',
        func: (Book b) => volumeUp(
          output: musicGain
        ),
      ),
      'i': Hotkey(
        titleString: 'Player inventory',
        func: (Book b) => inventory(),
      ),
      'd': Hotkey(
        titleString: 'Drop an object',
        func: (Book b) => drop(),
      ),
      'f': Hotkey(
        titleString: 'Show which way you are facing',
        func: (Book b) => showFacing(),
      ),
      'c': Hotkey(
        titleString: 'Show your current coordinate',
        func: (Book b) => showPosition(),
      ),
      'x': Hotkey(
        titleString: 'Examine object',
        func: (Book b) {
          final Level level = player.level;
          if (level == null) {
            return;
          }
          final List<LevelObject> contents = level.contents.where(
            (LevelObject item) => item.position == player.position
          ).toList();
          if (contents.isNotEmpty) {
            return examine(contents[0]);
          } else {
            const List<Line> lines = <Line>[];
            for (final LevelObject content in contents) {
              lines.add(
                Line(
                  titleString: content.object.title,
                  func: (Book b) => b.examine(content)
                )
              );
            }
            push(
              Page(
                titleString: 'Examine Object',
                lines: lines,
              )
            );
          }
        },
      ),
      '/': Hotkey(
        titleString: 'Show a list of hotkeys',
        func: (Book b) {
          push(hotkeysPage(this));
        },
      ),
    };
    for (int i = 0; i < 10; i++) {
      hotkeys[i.toString()] = Hotkey(
        titleString: 'Use the weapon in slot ${i == 0 ? 10 : i}',
        func: (Book b) {
          selectWeapon(i);
        },
      );
    }
  }

  Map<String, Hotkey> hotkeys;
  Game game;
  bool levelInPages = false;
  Scene scene;
  void Function(String) message;
  List<Page> pages = <Page>[];
  Player player = Player();

  void examine(LevelObject content) {
    final GameObject obj = content.object;
    final Map<String, String> stats = <String, String>{
      'Name': obj.title,
      'Type': objectTypeDescriptions[obj.type],
      'Health': '${content.health}',
      'Damage': '${obj.damage}',
      'Range': '${obj.range}',
    };
    const List<Line> lines = <Line>[];
    stats.forEach(
      (String name, String value) {
        lines.add(
          Line(
            titleString: '$name: $value',
            func: (Book b) => b.pop(),
          )
        );
      }
    );
    push(
      Page(
        titleString: 'Examine ${obj.title}',
        lines: lines,
      )
    );
  }

  SpeechSynthesisUtterance speak(
    {
      String text,
      bool interrupt = false,
    }
  ) {
    if (interrupt) {
      window.speechSynthesis.cancel();
    }
    final SpeechSynthesisUtterance u = SpeechSynthesisUtterance(text);
    u.voice = textToSpeech.voice;
    u.rate = textToSpeech.rate;
    window.speechSynthesis.speak(u);
    return u;
  }

  void push(Page page) {
    if (page.isLevel) {
      levelInPages = true;
      game.stopMusic();
    } else {
      if (game.music == null && !levelInPages) {
        game.music = Sound(
          url: game.musicUrl,
          loop: true,
          output: musicGain
        );
        game.music.play(url: game.musicUrl);
      }
    }
    pages.add(page);
    showFocus();
  }

  Page pop() {
    final Page oldPage = pages.removeLast(); // Remove the last page from the list.
    if (oldPage.isLevel) {
      levelInPages = false;
    }
    if (pages.isNotEmpty) {
      final Page page = pages.removeLast(); // Pop the next one too, so we can push it again.
      push(page);
    }
    return oldPage;
  }

  Page getPage() {
    if (pages.isNotEmpty) {
      return pages[pages.length - 1];
    }
    return null;
  }

  int getFocus() {
    final Page page = getPage();
    if (page == null) {
      return null;
    }
    return page.focus;
  }

  void showFocus() {
    final Page page = getPage();
    if (page == null) {
      throw 'First push a page.';
    } else if (page.focus == -1) {
      message(page.getTitle(this));
    } else if (!page.isLevel) {
      final Line line = page.getLine();
      game.moveSound.play(url: game.moveSoundUrl);
      message(line.getTitle(this));
    }
  }

  void moveUp() {
    final Page page = getPage();
    if (page == null) {
      return; // There"s probably no pages.
    } else if (page.isLevel) {
      player.level.jump(this);
    } else {
      final int focus = getFocus();
      if (focus == -1) {
        return; // Do nothing.
      }
      page.focus --;
      showFocus();
    }
  }

  void moveDown() {
    final Page page = getPage();
    if (page == null || page.isLevel) {
      return; // There"s either no pages, or we're in a level where there's no down key mapped.
    }
    final int focus = getFocus();
    if (focus == (page.lines.length - 1)) {
      return; // Can't move up any further.
    }
    page.focus++;
    showFocus();
  }

  void takeOrActivate() {
    final Page page = getPage();
    if (!page.isLevel) {
      return activate();
    }
    final Level level = player.level;
    for (final LevelObject content in level.contents) {
      if (content.position == player.position) {
        final GameObject obj = content.object;
        if (<ObjectTypes>[ObjectTypes.object, ObjectTypes.weapon].contains(obj.type)) {
          player.carrying.add(obj);
          obj.take.play(url: obj.takeUrl);
          content.destroy();
          message('${obj.title} taken.');
        } else if (obj.type == ObjectTypes.exit) {
          if (obj.targetLevel == null) {
            obj.cantUse.play(url: obj.cantUseUrl,);
          } else {
            level.leave(this);
            playScene(
              url: obj.useUrl,
              onfinish: (Book b) {
                obj.targetLevel.play(
                  book: b,
                  position: obj.targetPosition
                );
              }
            );
          }
        } else {
          message('You cannot take ${obj.title}.');
        }
        break; // Take one object at a time.
      }
    }
  }

  void moveOrActivate() {
    final Page page = getPage();
    if (page.isLevel) {
      final Level level = player.level;
      level.right(this);
    } else {
      activate();
    }
  }

  void activate() {
    final Page page = getPage();
    if (page == null) {
      return; // Can"t do anything with no page.
    }
    final Line line = page.getLine();
    if (line == null) {
      return; // They are probably looking at the title.
    }
    game.activateSound.play(url: game.activateSoundUrl);
    line.func(this);
  }

  void cancel() {
    final Page page = getPage();
    if (page == null || !page.dismissible) {
      return; // No page, or the page can"t be dismissed that easily.
    } else if (page.isLevel) {
      final Level level = player.level;
      level.left(this);
    } else {
      pop();
    }
  }

  void setVolume(
    {
      num value,
      GainNode output
    }
  ) {
    output.gain.value = value;
    if (game.volumeSoundUrl != null) {
      Sound(
        url: game.volumeSoundUrl,
        output: output
      ).play(url: game.volumeSoundUrl);
    }
    message('${(output.gain.value * 100).round()}%.');
  }

  void volumeUp(
    {
      GainNode output,
    }
  ) {
    output ??= gain;
    setVolume(
      value: min(1.0, output.gain.value + game.volumeChangeAmount),
      output: output,
    );
  }

  void volumeDown(
    {
      GainNode output,
    }
  ) {
    output ??= gain;
    setVolume(
      value: max(0.0, output.gain.value - game.volumeChangeAmount) as double,
      output: output
    );
  }

  void inventory() {
    if (player.level == null) {
      return; // They're not in a level.
    }
    if (player.carrying.isNotEmpty) {
      final List<Line> lines = <Line>[];
      for (final GameObject obj in player.carrying) {
        lines.add(
          Line(
            titleString: obj.title,
            func: (Book b) {
              b.pop();
              b.message('Using ${obj.title}.');
            },
          )
        );
      }
      push(
        Page(
          titleString: 'Inventory',
          lines: lines,
        )
      );
    } else {
      message("You aren't carrying anything.");
    }
  }

  void drop() {
    final Level level = player.level;
    if (level == null) {
      return;
    }
    if (player.carrying.isNotEmpty) {
      final List<Line> lines = <Line>[];
      for (final GameObject obj in player.carrying) {
        lines.add(
          Line(
            titleString: obj.title,
            func: (Book b) {
              final Player player = b.player;
              player.carrying.remove(obj);
              obj.drop(
                level: level,
                position: player.position,
              );
              b.pop();
              message('${obj.title} dropped.');
            }
          )
        );
      }
      push(
        Page(
          titleString: 'Choose something to drop',
          lines: lines,
        )
      );
    } else {
      message('You have nothing to drop.');
    }
  }

  void showFacing() {
    if (player.level == null) {
      return;
    }
    String direction;
    if (player.facing == LevelDirections.backwards) {
      direction = 'backwards';
    } else if (player.facing == LevelDirections.forwards) {
      direction = 'forwards';
    } else if (player.facing == LevelDirections.either) {
      direction = 'both ways at once';
    } else {
      direction = 'the wrong way';
    }
    message('You are facing $direction.');
  }

  void showPosition() {
    if (player.level == null) {
      return;
    }
    message('Position: ${player.position}.');
  }

  void onkeydown(KeyboardEvent e) {
    final String key = e.key;
    if (scene != null) {
      if (key == 'Enter') {
        scene.done(null);
      }
      return;
    }
    final Hotkey hotkey = hotkeys[key];
    if (hotkey != null) {
      final Function func = hotkey.func;
      e.preventDefault();
      func(this);
    }
  }

  void setPlayerPosition(int position) {
    final Level level = player.level;
    player.position = position;
    audio.listener.positionX.value = position / audioDivider;
    final List<LevelObject> contents = level.contents.where(
      (LevelObject content) => content.position == position
    ).toList();
    if (contents.isNotEmpty) {
      final List<String> objectTitles = <String>[];
      for (final LevelObject content in contents) {
        objectTitles.add(content.object.title);
      }
      level.trip.play(url: level.tripUrl);
      message(
        englishList(
          items: objectTitles,
        )
      );
    }
  }

  void selectWeapon(int index) {
    final Level level = player.level;
    if (level == null) {
      return;
    }
    if (index == 0) {
      index = 9;
    } else {
      index -= 1;
    }
    final List<GameObject> weapons = <GameObject>[fists];
    for (final GameObject obj in player.carrying) {
      if (obj.type == ObjectTypes.weapon) {
        weapons.add(obj);
      }
    }
    try {
      final GameObject weapon = weapons[index];
      player.weapon = weapon;
      message(weapon.title);
    }
    on RangeError {
      level.noWeapon.play(url: level.noWeaponUrl);
    }
  }

  Scene playScene(
    {
      String url,
      void Function(Book) onfinish,
    }
  ) {
    scene = Scene(
      book: this,
      url: url,
      onfinish: onfinish
    );
    scene.sound.play(url: url);
    return scene;
  }

  void shootOrActivate() {
    final Level level = player.level;
    if (level == null) {
      return activate();
    }
    player.weapon ??= fists;
    final GameObject weapon = player.weapon;
    final NearestObject nearestObject = level.nearestObject(
      position: player.position,
      direction: player.facing
    );
    if (nearestObject != null) {
      final LevelObject content = nearestObject.content;
      final GameObject obj = content.object;
      final int distance = nearestObject.distance;
      if (distance <= weapon.range) {
        weapon.use.play(url: weapon.useUrl);
        content.hit.play(url: obj.hitUrl);
        content.health -= randint(
          end: weapon.damage
        );
        if (content.health < 0) {
          content.die(this);
        }
      }
    }
  }
}
