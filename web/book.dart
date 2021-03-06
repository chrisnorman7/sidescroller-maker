import 'dart:html';
import 'dart:web_audio';

import 'constants.dart';
import 'game.dart';
import 'hotkey.dart';
import 'level.dart';
import 'line.dart';
import 'music.dart';
import 'object.dart';
import 'page.dart';
import 'player.dart';
import 'scene.dart';
import 'sound.dart';
import 'utils.dart';

enum OutputTypes {
  main,
  music,
}

class Book{
  Book() {
    game = Game();
    const String activateString = 'Activate a menu item';
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
        titleFunc: (Page page) => page.isLevel ? 'Cancel jump' : 'Move down in a menu',
        func: (Book b) => moveDown(),
      ),
      ' ': Hotkey(
        titleString: 'Use a weapon',
        func: (Book b) => shoot(),
        levelOnly: true,
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
          String description = activateString;
          if (page.isLevel) {
            description = 'Take the object at your current location';
          }
          return description + ' or cancel a playing scene';
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
        func: (Book b) => volumeDown(OutputTypes.main),
      ),
      ']': Hotkey(
        titleString: 'Increase sound volume',
        func: (Book b) => volumeUp(OutputTypes.main),
      ),
      '-': Hotkey(
        titleString: 'Decrease music volume',
        func: (Book b) => volumeDown(OutputTypes.music),
      ),
      '=': Hotkey(
        titleString: 'Increase music volume',
        func: (Book b) => volumeUp(OutputTypes.music),
      ),
      'i': Hotkey(
        titleString: 'Player inventory',
        func: (Book b) => inventory(),
        levelOnly: true,
      ),
      'd': Hotkey(
        titleString: 'Drop an object',
        func: (Book b) => drop(),
        levelOnly: true,
      ),
      'f': Hotkey(
        titleString: 'Show which way you are facing',
        func: (Book b) => showFacing(),
        levelOnly: true,
      ),
      't': Hotkey(
        titleString: 'Turn to face the other way',
        func: (Book b) => b.player.level.turnPlayer(b.player),
        levelOnly: true,
      ),
      'c': Hotkey(
        titleString: 'Show your current coordinate',
        func: (Book b) => showPosition(),
        levelOnly: true,
      ),
      'n': Hotkey(
        titleString: 'Show the nearest object or monster',
        func: (Book b) {
          final NearestObject nearestObject = player.level.nearestObject(
            position: player.position,
            direction: player.facing
          );
          if (nearestObject == null) {
            message('Nothing visible in that direction.');
          } else {
            final GameObject obj = nearestObject.content.object;
            message('${obj.title} is ${obj.airborn ? "airborn " : ""}at ${nearestObject.distance} metres.');
          }
        },
        levelOnly: true,
      ),
      'x': Hotkey(
        titleString: 'Examine object',
        func: (Book b) {
          final Level level = player.level;
          final List<LevelObject> contents = level.contents.where(
            (LevelObject item) => item.position == player.position
          ).toList();
          if (contents.isEmpty) {
            return b.message('There is nothing nearby to examine.');
          } else if (contents.length == 1) {
            return examine(contents[0]);
          } else {
            final List<Line> lines = <Line>[];
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
        levelOnly: true,
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
        levelOnly: true,
      );
    }
  }

  String searchString;
  int lastSearchTime;
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
      'Name': '${obj.title}${obj.airborn ? " (Airborn)" : ""}',
      'Type': objectTypeDescriptions[obj.type],
      'Health': '${content.health}',
      'Damage': '${obj.damage}',
      'Range': '${obj.range}',
    };
    final List<Line> lines = <Line>[];
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
    lastSearchTime = 0;
    if (page.isLevel) {
      levelInPages = true;
      game.stopMusic();
    } else {
      if (game.music == null && !levelInPages) {
        game.music = Music(game.musicUrl);
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
      String url;
      if (line.soundUrl != null) {
        url = line.soundUrl(this);
      } else if (page.playDefaultSounds) {
        url = game.moveSoundUrl;
      }
      game.moveSound.stop();
      if (url != null) {
        game.moveSound.play(url: url);
      }
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
    if (page == null) {
      return; // There"s no pages.
    } else if (page.isLevel) {
      if (!player.airborn) {
        final Level level = player.level;
        level.jumpPlan = null;
        level.cancelJumpSound.play(url: level.cancelJumpUrl);
      }
    } else {
      final int focus = getFocus();
      if (focus == (page.lines.length - 1)) {
        return; // Can't move down any further.
      }
      page.focus++;
      showFocus();
    }
    }

  void takeOrActivate() {
    if (scene != null) {
      return scene.done(null);
    }
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

  void adjustVolume(OutputTypes outputType, num adjust) {
    num start;
    if (outputType == OutputTypes.main) {
      start = mainVolume;
    } else {
      start = musicVolume;
    }
    start += adjust;
    if (start < 0.0) {
      start = 0;
    } else if (start > 1.0) {
      start = 1.0;
    }
    if (game.volumeSoundUrl != null) {
      final GainNode output = audio.createGain();
      output.connectNode(audio.destination);
      output.gain.value = start;
      final Sound beep = Sound(
        url: game.volumeSoundUrl,
        output: output
      );
      beep.onEnded = (Event event) {
        beep.stop();
        output.disconnect();
      };
      beep.play(url: game.volumeSoundUrl);
    }
    setVolume(outputType, start);
  }

  void setVolume(OutputTypes outputType, num value) {
    GainNode output;
    if (outputType == OutputTypes.main) {
      mainVolume = value;
      output = mainGain; // That's the final destination.
    } else {
      musicVolume = value;
      if (game.music != null) {
        output = game.music.output;
      }
    }
    if (output != null) {
      output.gain.value = value;
    }
    message('${(value * 100).round()}%.');
  }

  void volumeUp(OutputTypes outputType) {
    adjustVolume(outputType, game.volumeChangeAmount);
  }

  void volumeDown(OutputTypes outputType) {
    adjustVolume(outputType, -game.volumeChangeAmount);
  }

  void inventory() {
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
    String direction;
    if (player.facing == LevelDirections.backwards) {
      direction = 'backwards';
    } else if (player.facing == LevelDirections.forwards) {
      direction = 'forwards';
    } else if (player.facing == LevelDirections.either) {
      direction = 'in no particular direction';
    } else {
      direction = 'the wrong way';
    }
    message('You are facing $direction.');
  }

  void showPosition() {
    message('Position: ${player.position}.');
  }

  void onkeydown(KeyboardEvent e) {
    if (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey ) {
      return; // Don't work with modifiers.
    }
    final String key = e.key;
    final Hotkey hotkey = hotkeys[key];
    if (hotkey == null || (hotkey.levelOnly && (player.level == null || getPage() != player.level))) {
      if (key.length == 1) { // Don't search with number pad keys for example.
        handleSearch(key);
      } else {
        return; // Don't preventDefault, so tab key keeps on working.
      }
    } else {
      hotkey.func(this);
    }
    e.preventDefault();
  }

  void handleSearch(String term) {
    final Page page = getPage();
    if (page == null || page.isLevel) {
      return; // Don't search in levels or when there is no page.
    }
    final int now = timestamp();
    if ((now - lastSearchTime) >= game.menuSearchTimeout) {
      searchString = '';
    }
    lastSearchTime = now;
    searchString += term.toLowerCase();
    final int index = page.lines.indexWhere(
      (Line entry) => entry.getTitle(this).toLowerCase().startsWith(searchString)
    );
    if (index == -1) {
      game.searchSuccessSound.stop();
      game.searchFailSound.play(url: game.searchFailUrl);
    } else {
      game.searchFailSound.stop();
      game.searchSuccessSound.play(url: game.searchSuccessUrl);
      page.focus = index;
      showFocus();
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
      BookFunctionType onfinish,
    }
  ) {
    game.stopMusic();
    scene = Scene(
      book: this,
      url: url,
      onfinish: onfinish
    );
    scene.sound.play(url: url);
    return scene;
  }

  void shoot() {
    final Level level = player.level;
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
      if (obj.airborn == player.airborn && distance <= weapon.range) {
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
