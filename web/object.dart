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
  }

  GameObject.fromJson(
    {
      Map<String, dynamic>data
    }
  ) {
    reset();
    type = ObjectTypes.values[data['type'] as int];
    airborn = data['airborn'] as bool;
    targetLevelIndex = data['targetLevelIndex'] as int;
    for (final dynamic containedObjectIndexData in data['contains']) {
      final int containedObjectIndex = containedObjectIndexData as int;
      containedObjectIndices.add(containedObjectIndex);
    }
    if (data.containsKey('title')) {
      title = data['title'] as String;
    }
    if (data.containsKey('takeUrl')) {
      takeUrl = data['takeUrl'] as String;
    }
    if (data.containsKey('dropUrl')) {
      dropUrl = data['dropUrl'] as String;
    }
    if (data.containsKey('useUrl')) {
      useUrl = data['useUrl'] as String;
    }
    if (data.containsKey('cantUseUrl')) {
      cantUseUrl = data['cantUseUrl'] as String;
    }
    if (data.containsKey('hitUrl')) {
      hitUrl = data['hitUrl'] as String;
    }
    if (data.containsKey('dieUrl')) {
      dieUrl = data['dieUrl'] as String;
    }
    if (data.containsKey('soundUrl')) {
      soundUrl = data['soundUrl'] as String;
    }
    if (data.containsKey('damage')) {
      damage = data['damage'] as int;
    }
    if (data.containsKey('range')) {
      range = data['range'] as int;
    }
    if (data.containsKey('health')) {
      health = data['health'] as int;
    }
    if (data.containsKey('targetPosition')) {
      targetPosition = data['targetPosition'] as int;
    }
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
  bool airborn;

  Map<String, dynamic> toJson(
    {
      Game game
    }
  ) {
    final Map<String, dynamic>data = <String, dynamic>{
      'type': type.index,
      'contains': <int>[],
      'airborn': airborn,
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
    airborn = false;
    type = ObjectTypes.object;
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
    final LevelObject content = LevelObject(level, this, position);
    level.contents.add(content);
    content.spawn();
    if (!silent) {
      content.drop.play(url: dropUrl);
    }
  }
}
