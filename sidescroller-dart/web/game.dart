import 'dart:mirrors';

import 'book.dart';
import 'constants.dart';
import 'level.dart';
import 'object.dart';
import 'page.dart';
import 'sound.dart';

class Game {
  Game() {
    reset();
  }

  Game.fromJson(
    {
      Map<String, dynamic> data
    }
  ) {
    reset();
    final InstanceMirror reflection = reflect(this);
    title = data['title'] as String ?? title;
    volumeChangeAmount = data['volumeChangeAmount'] as double ?? volumeChangeAmount;
    urls.forEach(
      (String key, String description) {
        final String value = data[key] as String;
        if (value != null) {
          reflection.setField(key as Symbol, value);
        }
      }
    );
    numericProperties.forEach(
      (String key, String description) {
        final double value = data[key] as double;
        if (value != null) {
          reflection.setField(key as Symbol, value);
        }
      }
    );
    for (final Map<String, dynamic> objectData in data['objects'] as List<Map<String, dynamic>>) {
      final GameObject obj = GameObject.fromJson(
        data: objectData
      );
      objects.add(obj);
    }
    for (final Map<String, dynamic> levelData in data['levels'] as List<Map<String, dynamic>>) {
      final Level level = Level.fromJson(
        data: levelData,
        game: this
      );
      levels.add(level);
    }
    for (final GameObject obj in objects) {
      if (obj.targetLevelIndex != null) {
        obj.targetLevel = levels[obj.targetLevelIndex];
      }
      for (final int index in obj.containedObjectIndices) {
        obj.contains.add(objects[index]);
      }
    }
    resetVolumes();
  }


  String title, volumeSoundUrl, moveSoundUrl, activateSoundUrl, musicUrl;
  double volumeChangeAmount, initialVolume, initialMusicVolume;
  List<Level> levels;
  List<GameObject> objects;
  Sound moveSound, activateSound, music;
  Map<String, String> urls, numericProperties;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'title': title,
      'levels': <Map<String, dynamic>>[],
      'objects': <Map<String, dynamic>>[]
    };
    final InstanceMirror reflection = reflect(this);
    urls.forEach(
      (String key, String description) {
        final InstanceMirror field = reflection.getField(key as Symbol);
        data[key] = field.reflectee as String;
      }
    );
    numericProperties.forEach(
      (String key, String description) {
        final InstanceMirror field = reflection.getField(key as Symbol);
        data[key] = field.reflectee as double;
      }
    );
    for (final Level level in levels) {
      data['levels'].add(
        level.toJson(
          game: this
        )
      );
    }
    for (final GameObject object in objects) {
      data['objects'].add(
        object.toJson(
          game: this
        )
      );
    }
    return data;
  }

  void reset() {
    stopMusic();
    urls = <String, String>{
      volumeSoundUrl: 'Volume change sound',
      moveSoundUrl: 'Menu navigation sound',
      activateSoundUrl: 'Activate sound',
      musicUrl: 'Menu music'
    };
    volumeSoundUrl = 'res/menus/volume.wav';
    moveSoundUrl = 'res/menus/move.wav';
    moveSound = Sound(url: moveSoundUrl);
    activateSoundUrl = 'res/menus/activate.wav';
    activateSound = Sound(url: activateSoundUrl);
    musicUrl = 'res/menus/music.mp3';
    numericProperties = <String, String>{
      'volumeChangeAmount': 'Volume key sensitivity',
      'initialVolume': 'Initial volume',
      'initialMusicVolume': 'Initial music volume',
    };
    volumeChangeAmount = 0.05;
    initialVolume = 0.5;
    initialMusicVolume = 0.25;
    title = 'Untitled Game';
    levels = <Level>[];
    objects = <GameObject>[];
    resetVolumes();
  }

  void resetVolumes() {
    gain.gain.value = initialVolume;
    musicGain.gain.value = initialMusicVolume;
  }

  void stopMusic() {
    if (music != null) {
      music.stop();
      music = null;
    }
  }

  void reloadMusic(Book book) {
    stopMusic();
    book.push(
      page: Page(
        titleString: 'Reloading game music...',
      )
    );
    book.pop();
  }
}
