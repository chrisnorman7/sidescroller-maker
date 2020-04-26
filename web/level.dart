import 'dart:html';
import 'dart:web_audio';

import 'book.dart';
import 'constants.dart';
import 'game.dart';
import 'object.dart';
import 'page.dart';
import 'player.dart';
import 'sound.dart';
import 'utils.dart';

enum LevelDirections {
  backwards,
  either,
  forwards,
}

const Map<LevelDirections, int> levelDirectionConvertions = <LevelDirections, int>{
  LevelDirections.backwards: -1,
  LevelDirections.either: 0,
  LevelDirections.forwards: 1,
};

class LevelObject {
  LevelObject(
    {
      this.level,
      this.object,
      this.position,
    }
  ) {
    health = object.health;
  }

  LevelObject.fromJson(
    {
      this.level,
      Map<String, int> data,
      Game game,
    }
  ) {
    object = game.objects[data['objectIndex']];
    health = object.health;
    position = data['position'];
  }

  Level level;
  GameObject object;
  int position, health;
  PannerNode panner;
  Sound sound, hit, dieSound, drop;

  Map<String, int> toJson(
    {
      Game game
    }
  ) {
    return <String, int>{
      'objectIndex': game.objects.indexOf(object),
      'position': position
    };
  }

  void spawn() {
    final GameObject obj = object;
    panner = audio.createPanner();
    panner.maxDistance = 10;
    panner.rolloffFactor = 6;
    panner.connectNode(gain);
    move(position);
    if (obj.soundUrl != null) {
      sound = Sound(
        url:obj.soundUrl,
        loop: true,
        output: panner
      );
      sound.play(url: obj.soundUrl);
    }
    drop = Sound(
      url: obj.dropUrl,
      output: panner
    );
    hit = Sound(
      url:obj.hitUrl,
      output: panner
    );
    dieSound = Sound(
      url: obj.dieUrl,
      output: panner
    );
  }

  void destroy() {
    level.contents.remove(this);
    silence(
      disconnectPanner: true
    );
  }

  void silence(
    {
      bool disconnectPanner = false
    }
  ) {
    if (disconnectPanner) {
      panner.disconnect();
      panner = null;
    }
    if (sound != null) {
      sound.stop();
    }
  }

  void move(int p) {
    position = p;
    panner.positionX.value = position / audioDivider;
  }

  void die(Book book) {
    silence();
    level.contents.remove(this);
    if (object.dieUrl != null) {
      level.deadObjects.add(this);
      dieSound.onEnded = (Event e) {
        final int index = level.deadObjects.indexOf(this);
        if (index != -1) {
          level.deadObjects.remove(this);
        }
      };
      dieSound.play(url: object.dieUrl);
    }
    final List<String> titles = <String>[];
    for (final GameObject containedObject in object.contains) {
      containedObject.drop(
        level: level,
        position: position
      );
      titles.add(containedObject.title);
    }
    if (titles.isNotEmpty) {
      level.trip.play(url: level.tripUrl);
      book.message(
        englishList(
          items: titles
        )
        );
    }
  }
}

class NearestObject {
  NearestObject(
    {
      this.content,
      this.distance,
    }
  );

  LevelObject content;
  int distance;
}

class Level extends Page {
  Level() {
    focus = -1;
    isLevel = true;
    deadObjects = <LevelObject>[];
    contents = <LevelObject>[];
    titleString = 'Untitled Level';
    numericProperties = <String, String>{
      'size': 'The width of the level',
      'initialPosition': "The position the player should start at if they didn't get here via an exit",
      'speed': 'How often (in milliseconds) the player can move',
      'convolverVolume': 'The volume of the impulse response'
    };
    size = 200;
    initialPosition = 0;
    speed = 100;
    urls = <String, String>{
      'beforeSceneUrl': 'Scene to play before the level starts',
      'musicUrl': 'Background music',
      'ambianceUrl': 'Level Ambiance',
      'footstepUrl': 'Footstep sound',
      'wallUrl': 'Wall sound',
      'turnUrl': 'Turning sound',
      'tripUrl': 'Object discovery sound',
      'convolverUrl': 'Impulse response',
      'noWeaponUrl': 'Empty weapons slot'
    };
    beforeScene = Sound(
      url: beforeSceneUrl,
    );
    music = Sound(
      url: musicUrl,
    );
    ambiance = Sound(
      url: ambianceUrl
    );
    footstepUrl = 'res/footsteps/stone.wav';
    footstep = Sound(
      url: footstepUrl,
    );
    wallUrl = 'res/level/wall.wav';
    wall = Sound(
      url: wallUrl
    );
    turnUrl = 'res/level/turn.wav';
    turn = Sound(
      url: turnUrl
    );
    tripUrl = 'res/level/trip.wav';
    trip = Sound(
      url: tripUrl
    );
    convolverVolume = 0.5;
    noWeaponUrl = 'res/level/noweapon.wav';
    noWeapon = Sound(
      url: noWeaponUrl,
    );
  }

  Level.fromJson(
    {
      Map<String, dynamic> data,
      Level level,
      Game game,
    }
  ) {
    titleString = data['titleString'] as String ?? titleString;
    for (final Map<String, int> contentData in data['contents'] as List<Map<String, int>>) {
      final LevelObject content = LevelObject.fromJson(
        level: level,
        data: contentData,
        game: game
      );
      level.contents.add(content);
    }
  }

  bool loading = false;
  String beforeSceneUrl, musicUrl, ambianceUrl, footstepUrl, wallUrl, turnUrl, tripUrl, convolverUrl, noWeaponUrl ;
  List<LevelObject> contents, deadObjects;
  Map<String, String> urls, numericProperties;
  int size, initialPosition, speed;
  double convolverVolume;
  Sound beforeScene, music, ambiance, footstep, wall, turn, trip, noWeapon;
  ConvolverNode convolver;
  GainNode convolverGain;

  Map<String, dynamic> toJson(
    {
      Game game,
    }
  ) {
    final Map<String, dynamic> data = <String, dynamic>{
      'titleString': titleString,
      'contents': <Map<String, int>>[],
    };
    for (final LevelObject content in contents) {
      data['contents'].add(
        content.toJson(
          game: game
        )
      );
    }
    return data;
  }

  NearestObject nearestObject(
    {
      int position,
      LevelDirections direction = LevelDirections.either,
    }
  ) {
    NearestObject obj;
    for (final LevelObject content in contents) {
      if ((direction == LevelDirections.forwards && content.position >= position) || (direction == LevelDirections.backwards && content.position <= position)) {
        final int distance = distanceBetween(
          a: position,
          b: content.position
        );
        if (obj == null || distance < obj.distance) {
          obj = NearestObject(
            content: content,
            distance: distance
          );
        }
      }
    }
    return obj;
  }

  void jump(Book book) {
    if (loading) {
      return;
    }
    book.message('Jumping.');
  }

  void left(Book book) {
    move(
      book: book,
      direction: LevelDirections.backwards
    );
  }

  void right(Book book) {
    move(
      book: book,
      direction: LevelDirections.forwards
    );
  }

  void move(
    {
      Book book,
      LevelDirections direction
    }
  ) {
    if (loading) {
      return;
    }
    final Player player = book.player;
    final int time = timestamp();
    if ((time - player.lastMoved) > speed) {
      final int position = player.position + levelDirectionConvertions[direction];
      if (position < 0 || position > size) {
        wall.play(url: wallUrl);
      } else {
        book.setPlayerPosition(position);
        if (direction != player.facing) {
          if (player.facing != LevelDirections.either) {
            turn.play(url: turnUrl);
          }
          player.facing = direction;
        }
        footstep.play(url: footstepUrl);
      }
    }
  }

  void finalise(
    {
      Book book,
      int position,
    }
  ) {
    book.push(this);
    ambiance.play(url: ambianceUrl);
    loadContents();
    book.setPlayerPosition(position);
  }

  void play(
    {
      Book book,
      int position,
    }
  ) {
    position ??= initialPosition;
    book.player.level = this;
    if (convolverUrl != null) {
      loading = true;
      loadBuffer(
        url: convolverUrl,
        done: (AudioBuffer buffer) {
          convolver = audio.createConvolver();
          convolver.buffer = buffer;
          gain.connectNode(convolver);
          convolverGain = audio.createGain();
          convolverGain.gain.value = convolverVolume;
          convolver.connectNode(convolverGain);
          convolverGain.connectNode(audio.destination);
        }
      );
    }
    if (beforeSceneUrl == null) {
      finalise(
        book: book,
        position: position,
      );
    } else {
      book.playScene(
        url: beforeSceneUrl,
        onfinish: (Book b) => finalise(
          book: b,
          position: position,
        )
      );
    }
  }

  void loadContents() {
    for (final LevelObject content in contents) {
      content.spawn();
    }
    loading = false;
  }

  void leave(Book book) {
    book.player.level = null;
    book.pop();
    if (convolver != null) {
      gain.disconnect(convolver);
      convolverGain.disconnect();
      convolver.disconnect();
      convolverGain = null;
      convolver = null;
    }
    for (final LevelObject content in contents) {
      content.silence(
        disconnectPanner: true
      );
    }
    for (final LevelObject corpse in deadObjects) {
      corpse.destroy();
    }
    ambiance.stop();
  }
}
