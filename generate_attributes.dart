import 'dart:io';
import 'package:mustache/mustache.dart';

class Attribute<T> {
  Attribute(
    this.name,
    this.description,
    {
      this.value,
      this.initialise = true
    }
  );

  final String name, description;
  final Object type = T;
  final T value;
  final bool initialise;

  String get stringValue {
    if (value == null) {
      return 'null';
    } else if (type == String) {
      return "'$value'";
    }
    return value.toString();
  }
  
  String get declaration {
    String result = '$type $name';
    if (value != null) {
      result = '$result = $stringValue';
    }
    return '$result;';
  }
}

Map<String, List<Attribute<dynamic>>> attributes = <String, List<Attribute<dynamic>>>{
  'web/game.dart': <Attribute<dynamic>>[
    Attribute<String>(
      'title', 'Game Title',
      value: 'Untitled Game'
    ),
    Attribute<String>(
      'volumeSoundUrl', 'Volume changed sound',
      value: 'res/menus/volume.wav'
    ),
    Attribute<String>(
      'moveSoundUrl', 'Menu move sound',
      value: 'res/menus/move.wav'
    ),
    Attribute<String>(
      'activateSoundUrl', 'Menu activate sound',
      value: 'res/menus/activate.wav'
      ),
    Attribute<String>(
      'musicUrl', 'Menu music',
      value: 'res/menus/music.mp3'
    ),
    Attribute<num>(
      'volumeChangeAmount', 'Volume control sensitivity',
      value: 0.05
    ),
    Attribute<num>(
      'initialVolume', 'Initial sound volume',
      value: 0.5
    ),
    Attribute<num>(
      'initialMusicVolume', 'Initial music volume',
      value: 0.25
    ),
  ],
  'web/level.dart': <Attribute<dynamic>>[
    Attribute<String>(
      'titleString', 'Name',
      value: 'Untitled Level', initialise: false
    ),
    Attribute<int>(
      'size', 'Width',
      value: 200
    ),
    Attribute<int>(
      'initialPosition', 'Start at',
      value: 0
    ),
    Attribute<int>(
      'speed', 'Player speed',
      value: 400
    ),
    Attribute<String>(
      'beforeSceneUrl', 'Before scene URL'
    ),
    Attribute<String>(
      'footstepUrl', 'Footstep sound',
      value: 'res/footsteps/stone.wav'
    ),
    Attribute<String>(
      'wallUrl', 'Wall sound',
      value: 'res/level/wall.wav'
    ),
    Attribute<String>(
      'turnUrl', 'Turn sound',
      value: 'res/level/turn.wav'
    ),
    Attribute<String>(
      'tripUrl', 'Trip sound',
      value: 'res/level/trip.wav'
    ),
    Attribute<String>(
      'ambianceUrl', 'Ambiance'
    ),
    Attribute<String>(
      'musicUrl', 'Level music'
    ),
    Attribute<String>(
      'convolverUrl', 'Impulse response',
      value: 'res/impulses/EchoThiefImpulseResponseLibrary/Underground/TunnelToHell.wav'
    ),
    Attribute<num>(
      'convolverVolume', 'Convolver volume',
      value: 0.5
    ),
    Attribute<String>(
      'noWeaponUrl', 'No weapon sound',
      value: 'res/level/noweapon.wav'
    ),
  ],
  'web/object.dart': <Attribute<dynamic>>[
    Attribute<int>(
      'targetPosition', 'Position to exit from',
      value: 0
    ),
    Attribute<String>(
      'title', 'Name'
    ),
    Attribute<String>(
      'takeUrl', 'Take sound',
      value: 'res/objects/take.wav'
    ),
    Attribute<String>(
      'dropUrl', 'Drop sound',
      value: 'res/objects/drop.wav'
    ),
    Attribute<String>(
      'useUrl', 'Use sound',
      value: 'res/weapons/punch.wav'
    ),
    Attribute<String>(
      'cantUseUrl', "Can't use sound",
      value: 'res/objects/cantuse.wav'
    ),
    Attribute<String>(
      'hitUrl', 'Hit sound',
      value: 'res/objects/hit.wav'
    ),
    Attribute<String>(
      'dieUrl', 'Die sound',
      value:'res/objects/die.wav', 
    ),
    Attribute<String>(
      'soundUrl', 'Ambiance',
      value: 'res/objects/object.wav'
    ),
    Attribute<int>(
      'damage', 'Weapon damage',
      value: 2
    ),
    Attribute<int>(
      'range', 'Weapon range',
      value: 1
    ),
    Attribute<int>(
      'health', 'Max health',
      value: 3
    ),
  ]
};

void main() {
  final Map<String, List<Map<String, dynamic>>> allAttributes = <String, List<Map<String, dynamic>>>{};
  attributes.forEach(
    (String filename, List<Attribute<dynamic>> classAttributes) {
      final List<Map<String, dynamic>> variablesData = <Map<String, dynamic>>[];
      for (final Attribute<dynamic> attribute in classAttributes) {
        variablesData.add(<String, dynamic>{
          'name': attribute.name,
          'type': attribute.type.toString(),
          'value': attribute.stringValue,
          'declaration': attribute.declaration,
          'initialise': attribute.initialise,
        });
      }
      allAttributes[filename] = variablesData;
    }
  );
  allAttributes.forEach(
    (String filename, List<Map<String, dynamic>> attributesList) {
      final File templateFile = File('$filename.mustache');
      print('Reading file $filename.');
      if (!templateFile.existsSync()) {
        return print('File $filename does not exist.');
      }
      final String templateContents = templateFile.readAsStringSync();
      final Template template = Template(templateContents, htmlEscapeValues : false);
      final String source = template.renderString(
        <String, dynamic>{
          'variables': attributesList,
          'attributes': allAttributes,
        }
      );
      final File sourceFile = File(filename);
      sourceFile.writeAsString(source);
      print('Wrote file $filename.');
    }
  );
}
