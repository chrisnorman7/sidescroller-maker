import 'dart:async';
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
  LevelObject(this.level, this.object, this.position) {
    health = object.health;
  }

  LevelObject.fromJson(this.level, Map<String, int> data) {
    object = level.game.objects[data['objectIndex']];
    health = object.health;
    position = data['position'];
  }

  Level level;
  GameObject object;
  int position, health;
  PannerNode panner;
  Sound sound, hit, dieSound, drop;

  Map<String, int> toJson() {
    return <String, int>{
      'objectIndex': level.game.objects.indexOf(object),
      'position': position
    };
  }

  void spawn() {
    panner = audio.createPanner();
    panner.maxDistance = 10;
    panner.rolloffFactor = 6;
    panner.connectNode(soundGain);
    move(position);
    if (object.soundUrl != null) {
      sound = Sound(
        url:object.soundUrl,
        loop: true,
        output: panner
      );
      sound.play(url: object.soundUrl);
    }
    drop = Sound(
      url: object.dropUrl,
      output: panner
    );
    hit = Sound(
      url:object.hitUrl,
      output: panner
    );
    dieSound = Sound(
      url: object.dieUrl,
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
  Level(this.game) {
    reset();
  }

  Level.fromJson(this.game, Map<String, dynamic> data) {
    reset();
    for (final dynamic contentDataJson in data['contents']) {
      final Map<String, int> contentData = <String, int>{
        'objectIndex': contentDataJson['objectIndex'] as int,
        'position': contentDataJson['position'] as int,
      };
      final LevelObject content = LevelObject.fromJson(this, contentData);
      contents.add(content);
    }
    if (data.containsKey('titleString')) {
      titleString = data['titleString'] as String;
    }
    if (data.containsKey('size')) {
      size = data['size'] as int;
    }
    if (data.containsKey('initialPosition')) {
      initialPosition = data['initialPosition'] as int;
    }
    if (data.containsKey('speed')) {
      speed = data['speed'] as int;
    }
    if (data.containsKey('jumpDuration')) {
      jumpDuration = data['jumpDuration'] as int;
    }
    if (data.containsKey('beforeJumpUrl')) {
      beforeJumpUrl = data['beforeJumpUrl'] as String;
    }
    if (data.containsKey('jumpUrl')) {
      jumpUrl = data['jumpUrl'] as String;
    }
    if (data.containsKey('landUrl')) {
      landUrl = data['landUrl'] as String;
    }
    if (data.containsKey('cancelJumpUrl')) {
      cancelJumpUrl = data['cancelJumpUrl'] as String;
    }
    if (data.containsKey('beforeSceneUrl')) {
      beforeSceneUrl = data['beforeSceneUrl'] as String;
    }
    if (data.containsKey('footstepUrl')) {
      footstepUrl = data['footstepUrl'] as String;
    }
    if (data.containsKey('wallUrl')) {
      wallUrl = data['wallUrl'] as String;
    }
    if (data.containsKey('turnUrl')) {
      turnUrl = data['turnUrl'] as String;
    }
    if (data.containsKey('tripUrl')) {
      tripUrl = data['tripUrl'] as String;
    }
    if (data.containsKey('ambianceUrl')) {
      ambianceUrl = data['ambianceUrl'] as String;
    }
    if (data.containsKey('musicUrl')) {
      musicUrl = data['musicUrl'] as String;
    }
    if (data.containsKey('convolverUrl')) {
      convolverUrl = data['convolverUrl'] as String;
    }
    if (data.containsKey('convolverVolume')) {
      convolverVolume = data['convolverVolume'] as num;
    }
    if (data.containsKey('noWeaponUrl')) {
      noWeaponUrl = data['noWeaponUrl'] as String;
    }
  }

  int size;
  int initialPosition;
  int speed;
  int jumpDuration;
  String beforeJumpUrl;
  String jumpUrl;
  String landUrl;
  String cancelJumpUrl;
  String beforeSceneUrl;
  String footstepUrl;
  String wallUrl;
  String turnUrl;
  String tripUrl;
  String ambianceUrl;
  String musicUrl;
  String convolverUrl;
  num convolverVolume;
  String noWeaponUrl;

  bool loading = false;
  Game game;
  List<LevelObject> contents, deadObjects;
  Sound beforeJumpSound, jumpSound, landSound, cancelJumpSound, beforeScene, music, ambiance, footstep, wall, turn, trip, noWeapon;
  ConvolverNode convolver;
  GainNode convolverGain;
  Timer jumpTimer;
  LevelDirections jumpPlan;

  Map<String, dynamic> toJson(
    {
      Game game,
    }
  ) {
    final Map<String, dynamic> data = <String, dynamic>{
      'contents': <Map<String, int>>[],
    };
    for (final LevelObject content in contents) {
      data['contents'].add(
        content.toJson()
      );
    }
    data['titleString'] = titleString;
    data['size'] = size;
    data['initialPosition'] = initialPosition;
    data['speed'] = speed;
    data['jumpDuration'] = jumpDuration;
    data['beforeJumpUrl'] = beforeJumpUrl;
    data['jumpUrl'] = jumpUrl;
    data['landUrl'] = landUrl;
    data['cancelJumpUrl'] = cancelJumpUrl;
    data['beforeSceneUrl'] = beforeSceneUrl;
    data['footstepUrl'] = footstepUrl;
    data['wallUrl'] = wallUrl;
    data['turnUrl'] = turnUrl;
    data['tripUrl'] = tripUrl;
    data['ambianceUrl'] = ambianceUrl;
    data['musicUrl'] = musicUrl;
    data['convolverUrl'] = convolverUrl;
    data['convolverVolume'] = convolverVolume;
    data['noWeaponUrl'] = noWeaponUrl;
    return data;
  }

  void reset() {
    isLevel = true;
    deadObjects = <LevelObject>[];
    contents = <LevelObject>[];
    titleString = 'Untitled Level';
    size = 200;
    initialPosition = 0;
    speed = 200;
    jumpDuration = 1500;
    beforeJumpUrl = 'res/level/beforejump.wav';
    jumpUrl = 'res/level/jump.wav';
    landUrl = 'res/level/land.wav';
    cancelJumpUrl = 'res/level/land.wav';
    beforeSceneUrl = 'res/level/beforescene.wav';
    footstepUrl = 'res/footsteps/stone.wav';
    wallUrl = 'res/level/wall.wav';
    turnUrl = 'res/level/turn.wav';
    tripUrl = 'res/level/trip.wav';
    ambianceUrl = 'res/level/amb/forest.wav';
    musicUrl = null;
    convolverUrl = 'res/impulses/EchoThiefImpulseResponseLibrary/Underground/TunnelToHell.wav';
    convolverVolume = 0.5;
    noWeaponUrl = 'res/level/noweapon.wav';
    beforeJumpSound = Sound(
      url: beforeJumpUrl,
      output: soundGain
    );
    jumpSound = Sound(
      url: jumpUrl,
      output: soundGain
    );
    landSound = Sound(
      url: landUrl,
      output: soundGain
    );
    cancelJumpSound = Sound(
      url: cancelJumpUrl,
      output: soundGain
    );
    beforeScene = Sound(
      url: beforeSceneUrl,
    );
    music = Sound(
      url: musicUrl,
    );
    ambiance = Sound(
      url: ambianceUrl,
      loop: true,
      output: mainGain
    );
    footstep = Sound(
      url: footstepUrl,
    );
    wall = Sound(
      url: wallUrl
    );
    turn = Sound(
      url: turnUrl
    );
    trip = Sound(
      url: tripUrl
    );
    noWeapon = Sound(
      url: noWeaponUrl,
    );
  }

  NearestObject nearestObject(
    {
      int position,
      LevelDirections direction = LevelDirections.either,
    }
  ) {
    NearestObject obj;
    for (final LevelObject content in contents) {
      if (direction == LevelDirections.either || (direction == LevelDirections.forwards && content.position >= position) || (direction == LevelDirections.backwards && content.position <= position)) {
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
    final Player player = book.player;
    if (loading || player.airborn) {
      // Don't do anything while the scene plays or while they're already airborn.
    } else if (jumpPlan == null) {
      jumpPlan = LevelDirections.either;
      beforeJumpSound.play(url: beforeJumpUrl);
    } else {
      final int jumpStarted = timestamp();
      final LevelDirections direction = jumpPlan;
      jumpPlan = null;
      jumpSound.play(url: jumpUrl);
      player.airborn = true;
      jumpTimer = Timer.periodic(
        Duration(milliseconds: speed),
        (Timer t) {
          if ((timestamp() - jumpStarted) >= jumpDuration) {
            player.airborn = false;
            landSound.play(url: landUrl);
            t.cancel();
            jumpTimer = null;
          } else {
            if (direction != LevelDirections.either) {
              move(book, direction, performChecks: false, silent: true);
            }
          }
        }
      );
    }
  }

  void left(Book book) {
    move(book, LevelDirections.backwards);
  }

  void right(Book book) {
    move(book, LevelDirections.forwards);
  }

  void move(
    Book book, LevelDirections direction,
    {
      bool performChecks= true,
      bool silent = false,
    }
  ) {
    final Player player = book.player;
    final int time = timestamp();
    if (performChecks && (loading || player.airborn || (time - player.lastMoved) < speed)) {
      // Don't do anything while the scene plays, while they're already airborn, or if they can't move again yet.
    } else if (jumpPlan == LevelDirections.either) {
      // They want to jump in the given direction.
      jumpPlan = direction;
      jump(book);
    } else {
      final int position = player.position + levelDirectionConvertions[direction];
      player.lastMoved = time;
      if (position < 0 || position > size) {
        wall.play(url: wallUrl);
      } else {
        book.setPlayerPosition(position);
        if (direction != player.facing) {
          turnPlayer(player, direction: direction);
        }
        if (!silent) {
          footstep.play(url: footstepUrl);
        }
      }
    }
  }

  void turnPlayer(
    Player player,
    {LevelDirections direction}
  ) {
    if (direction == null) {
      if (player.facing == LevelDirections.forwards) {
        direction = LevelDirections.backwards;
      } else {
        direction = LevelDirections.forwards;
      }
    }
    if (player.facing != LevelDirections.either && direction != player.facing) {
      turn.play(url: turnUrl);
    }
    player.facing = direction;
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
    book.player.lastMoved = 0;
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
    if (convolverUrl == null) {
      convolver = null;
    } else {
      loading = true;
      loadBuffer(
        url: convolverUrl,
        done: (AudioBuffer buffer) {
          convolver = audio.createConvolver();
          convolver.buffer = buffer;
          convolverGain = audio.createGain();
          convolverGain.gain.value = convolverVolume;
          convolver.connectNode(convolverGain);
          convolverGain.connectNode(mainGain);
          soundGain.connectNode(convolver);
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
      convolver.disconnect();
      convolver = null;
      convolverGain.disconnect();
      convolverGain = null;
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
