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
    reset();
    title = null;
    takeUrl = 'res/objects/take.wav';
    dropUrl = 'res/objects/drop.wav';
    useUrl = 'res/weapons/punch.wav';
    cantUseUrl = 'res/objects/cantuse.wav';
    hitUrl = 'res/objects/hit.wav';
    dieUrl = 'res/objects/die.wav';
    soundUrl = 'res/objects/object.wav';
    damage = 2;
    range = 1;
    health = 3;
    targetPosition = 0;
  }

  GameObject.fromJson(
    {
      Map<String, dynamic>data
    }
  ) {
    reset();
    type = ObjectTypes.values[data['type'] as int];
    targetLevelIndex = data['targetLevelIndex'] as int;
    for (final dynamic containedObjectIndexData in data['contains']) {
      final int containedObjectIndex = containedObjectIndexData as int;
      containedObjectIndices.add(containedObjectIndex);
    }
    title = data['title'] as String;
    takeUrl = data['takeUrl'] as String;
    dropUrl = data['dropUrl'] as String;
    useUrl = data['useUrl'] as String;
    cantUseUrl = data['cantUseUrl'] as String;
    hitUrl = data['hitUrl'] as String;
    dieUrl = data['dieUrl'] as String;
    soundUrl = data['soundUrl'] as String;
    damage = data['damage'] as int;
    range = data['range'] as int;
    health = data['health'] as int;
    targetPosition = data['targetPosition'] as int;
  }

  String title;
  String takeUrl;
  String dropUrl;
  String useUrl;
  String cantUseUrl;
  String hitUrl;
  String dieUrl;
  String soundUrl;
  int damage;
  int range;
  int health;
  int targetPosition;

  ObjectTypes type;
  Sound take, use, cantUse;
  Level targetLevel;
  int targetLevelIndex;
  List<GameObject> contains;
  List<int> containedObjectIndices;

  Map<String, dynamic> toJson(
    {
      Game game
    }
  ) {
    final Map<String, dynamic>data = <String, dynamic>{
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
    data['title'] = title;
    data['takeUrl'] = takeUrl;
    data['dropUrl'] = dropUrl;
    data['useUrl'] = useUrl;
    data['cantUseUrl'] = cantUseUrl;
    data['hitUrl'] = hitUrl;
    data['dieUrl'] = dieUrl;
    data['soundUrl'] = soundUrl;
    data['damage'] = damage;
    data['range'] = range;
    data['health'] = health;
    data['targetPosition'] = targetPosition;
    return data;
  }
  
  void reset() {
    type = ObjectTypes.object;
    take = Sound(url: takeUrl);
    use = Sound(url: useUrl);
    cantUse = Sound(url: cantUseUrl);
    contains = <GameObject>[];
    containedObjectIndices = <int>[];
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
