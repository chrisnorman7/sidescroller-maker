import 'book.dart';
import 'constants.dart';
import 'level.dart';
import 'music.dart';
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
      final Level level = Level.fromJson(this, levelData as Map<String, dynamic>);
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
    if (data.containsKey('title')) {
      title = data['title'] as String;
    }
    if (data.containsKey('volumeSoundUrl')) {
      volumeSoundUrl = data['volumeSoundUrl'] as String;
    }
    if (data.containsKey('moveSoundUrl')) {
      moveSoundUrl = data['moveSoundUrl'] as String;
    }
    if (data.containsKey('activateSoundUrl')) {
      activateSoundUrl = data['activateSoundUrl'] as String;
    }
    if (data.containsKey('musicUrl')) {
      musicUrl = data['musicUrl'] as String;
    }
    if (data.containsKey('musicFadeout')) {
      musicFadeout = data['musicFadeout'] as num;
    }
    if (data.containsKey('volumeChangeAmount')) {
      volumeChangeAmount = data['volumeChangeAmount'] as num;
    }
    if (data.containsKey('initialVolume')) {
      initialVolume = data['initialVolume'] as num;
    }
    if (data.containsKey('initialMusicVolume')) {
      initialMusicVolume = data['initialMusicVolume'] as num;
    }
    if (data.containsKey('menuSearchTimeout')) {
      menuSearchTimeout = data['menuSearchTimeout'] as int;
    }
    if (data.containsKey('searchSuccessUrl')) {
      searchSuccessUrl = data['searchSuccessUrl'] as String;
    }
    if (data.containsKey('searchFailUrl')) {
      searchFailUrl = data['searchFailUrl'] as String;
    }
    resetVolumes();
  }

  String title;
  String volumeSoundUrl;
  String moveSoundUrl;
  String activateSoundUrl;
  String musicUrl;
  num musicFadeout;
  num volumeChangeAmount;
  num initialVolume;
  num initialMusicVolume;
  int menuSearchTimeout;
  String searchSuccessUrl;
  String searchFailUrl;

  List<Level> levels;
  List<GameObject> objects;
  Sound moveSound, activateSound, searchFailSound, searchSuccessSound;
  Music music;

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
    data['musicFadeout'] = musicFadeout;
    data['volumeChangeAmount'] = volumeChangeAmount;
    data['initialVolume'] = initialVolume;
    data['initialMusicVolume'] = initialMusicVolume;
    data['menuSearchTimeout'] = menuSearchTimeout;
    data['searchSuccessUrl'] = searchSuccessUrl;
    data['searchFailUrl'] = searchFailUrl;
    return data;
  }

  void reset() {
    stopMusic();
    moveSound = Sound(url: moveSoundUrl);
    activateSound = Sound(url: activateSoundUrl);
    searchFailSound = Sound(url:searchFailUrl);
    searchSuccessSound = Sound(url: searchSuccessUrl);
    levels = <Level>[];
    objects = <GameObject>[];
    title = 'Untitled Game';
    volumeSoundUrl = 'res/menus/volume.wav';
    moveSoundUrl = 'res/menus/move.wav';
    activateSoundUrl = 'res/menus/activate.wav';
    musicUrl = 'res/menus/music.mp3';
    musicFadeout = 0.5;
    volumeChangeAmount = 0.05;
    initialVolume = 0.5;
    initialMusicVolume = 0.25;
    menuSearchTimeout = 400;
    searchSuccessUrl = 'res/menus/searchsuccess.wav';
    searchFailUrl = 'res/menus/searchfail.wav';
    resetVolumes();
  }

  void resetVolumes() {
    mainVolume = initialVolume;
    mainGain.gain.value = initialVolume;
    musicVolume = initialMusicVolume;
    if (music != null) {
      music.output.gain.value = initialMusicVolume;
    }
  }

  void stopMusic() {
    if (music != null) {
      final num when = audio.currentTime + (musicFadeout * 10);
      music.stop(when);
      music.output.gain.setTargetAtTime(0.0, audio.currentTime, musicFadeout);
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
