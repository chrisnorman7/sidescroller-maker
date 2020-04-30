import 'level.dart';
import 'object.dart';

class Player {
  Player() {
    airborn = false;
    facing = LevelDirections.either;
    health = 100;
    lastMoved = 0;
    carrying = <GameObject>[];
  }

  int position, health, lastMoved;
  Level level;
  LevelDirections facing;
  List<GameObject> carrying;
  GameObject weapon;
  bool airborn;
}
