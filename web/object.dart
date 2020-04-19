import 'game.dart';
import 'level.dart';
import 'sound.dart';

enum ObjectTypes {
  object,
  aggressiveMonster,
  peacefulMonster,
  weapon,
  exit,
}

const Map<ObjectTypes, String> objectTypeDescriptions = <ObjectTypes, String>{
  ObjectTypes.object: 'An object which can be picked up by the player',
  ObjectTypes.aggressiveMonster: 'A monster which will attack the player',
  ObjectTypes.peacefulMonster: 'A monster which will ignore the player',
  ObjectTypes.weapon: 'A weapon which can be wielded',
  ObjectTypes.exit: 'An exit to another level'
};

class GameObject {
  GameObject() {
    type = ObjectTypes.object;
    urls = <String, String>{
      'soundUrl': 'The sound constantly played by this object',
      'takeUrl': 'The sound played when picking up this object',
      'dropUrl': 'The sound that is played when this object is dropped',
      'hitUrl': 'The sound that is heard when this object is hit',
      'useUrl': 'The sound that is played when this object is used or fired',
      'cantUseUrl': "The sound to be played when this object can't be used",
      'dieUrl': 'The sound played when this object is killed or destroyed',
    };
    takeUrl = 'res/objects/take.wav';
    take = Sound(url: takeUrl);
    soundUrl = 'res/objects/object.wav';
    dropUrl = 'res/objects/drop.wav';
    hitUrl = 'res/objects/hit.wav';
    useUrl = 'res/weapons/punch.wav';
    use = Sound(url: useUrl);
    cantUseUrl = 'res/objects/cantuse.wav';
    cantUse = Sound(url: cantUseUrl);
    dieUrl = 'res/objects/die.wav';
    numericProperties = <String, String>{
      'damage': 'The amount of damage dealt by this weapon',
      'range': 'The range of this weapon',
      'health': 'The initial health of this object',
      'targetPosition': 'The position the player should be in after using this exit',
    };
    damage = 2;
    range = 1;
    health = 1;
    targetPosition = 0;
    contains = <GameObject>[];
    containedObjectIndices = <int>[];
  }

  GameObject.fromJson(
    {
      Map<String, dynamic>data
    }
  ) {
    title = data['title'] as String ?? title;
    type = ObjectTypes.values[data['type'] as int];
    targetLevelIndex = data['targetLevelIndex'] as int;
    containedObjectIndices = data['contains'] as List<int>;
  }

  String title, takeUrl, soundUrl, dropUrl, hitUrl, useUrl, cantUseUrl, dieUrl;
  ObjectTypes type;
  Sound take, use, cantUse;
  Level targetLevel;
  int targetLevelIndex, damage, range, health, targetPosition;
  Map<String, String> urls, numericProperties;
  List<GameObject> contains;
  List<int> containedObjectIndices;

  Map<String, dynamic> toJson(
    {
      Game game
    }
  ) {
    final Map<String, dynamic>data = <String, dynamic>{
      'title': title,
      'type': type.index,
      'contains': <int>[]
    };
    if (targetLevel == null) {
      data['targetLevelIndex'] = null;
    } else {
      data['targetLevelIndex'] = game.levels.indexOf(targetLevel);
    }
    for (final GameObject containedObject in contains) {
      data['contains'].add(game.objects.indexOf(containedObject));
    }
    return data;
  }

  void drop(
    {
      Level level,
      int position,
      bool silent = false,
    }
  ) {
    final LevelObject content = LevelObject(
      level: level,
      object: this,
      position: position
    );
    level.contents.add(content);
    content.spawn();
    if (!silent) {
      content.drop.play(url: dropUrl);
    }
  }
}
