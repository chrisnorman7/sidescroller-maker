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
    title = data['title'] as String ?? title;
    volumeChangeAmount = data['volumeChangeAmount'] as double ?? volumeChangeAmount;
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
  num volumeChangeAmount, initialVolume, initialMusicVolume;
  List<Level> levels;
  List<GameObject> objects;
  Sound moveSound, activateSound, music;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
      'title': title,
      'levels': <Map<String, dynamic>>[],
      'objects': <Map<String, dynamic>>[]
    };
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
    volumeSoundUrl = 'res/menus/volume.wav';
    moveSoundUrl = 'res/menus/move.wav';
    moveSound = Sound(url: moveSoundUrl);
    activateSoundUrl = 'res/menus/activate.wav';
    activateSound = Sound(url: activateSoundUrl);
    musicUrl = 'res/menus/music.mp3';
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
      Page(
        titleString: 'Reloading game music...',
      )
    );
    book.pop();
  }
}
