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
    for (final dynamic objectData in data['objects']) {
      final GameObject obj = GameObject.fromJson(
        data: objectData as Map<String, dynamic>
      );
      objects.add(obj);
    }
    for (final dynamic levelData in data['levels']) {
      final Level level = Level.fromJson(
        data: levelData as Map<String, dynamic>,
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
    title = data['title'] as String;
    volumeSoundUrl = data['volumeSoundUrl'] as String;
    moveSoundUrl = data['moveSoundUrl'] as String;
    activateSoundUrl = data['activateSoundUrl'] as String;
    musicUrl = data['musicUrl'] as String;
    volumeChangeAmount = data['volumeChangeAmount'] as num;
    initialVolume = data['initialVolume'] as num;
    initialMusicVolume = data['initialMusicVolume'] as num;
    resetVolumes();
  }

  String title;
  String volumeSoundUrl;
  String moveSoundUrl;
  String activateSoundUrl;
  String musicUrl;
  num volumeChangeAmount;
  num initialVolume;
  num initialMusicVolume;

  List<Level> levels;
  List<GameObject> objects;
  Sound moveSound, activateSound, music;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{
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
    data['title'] = title;
    data['volumeSoundUrl'] = volumeSoundUrl;
    data['moveSoundUrl'] = moveSoundUrl;
    data['activateSoundUrl'] = activateSoundUrl;
    data['musicUrl'] = musicUrl;
    data['volumeChangeAmount'] = volumeChangeAmount;
    data['initialVolume'] = initialVolume;
    data['initialMusicVolume'] = initialMusicVolume;
    return data;
  }

  void reset() {
    stopMusic();
    moveSound = Sound(url: moveSoundUrl);
    activateSound = Sound(url: activateSoundUrl);
    levels = <Level>[];
    objects = <GameObject>[];
    title = 'Untitled Game';
    volumeSoundUrl = 'res/menus/volume.wav';
    moveSoundUrl = 'res/menus/move.wav';
    activateSoundUrl = 'res/menus/activate.wav';
    musicUrl = 'res/menus/music.mp3';
    volumeChangeAmount = 0.05;
    initialVolume = 0.5;
    initialMusicVolume = 0.25;
    resetVolumes();
  }

  void resetVolumes() {
    mainGain.gain.value = initialVolume;
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
