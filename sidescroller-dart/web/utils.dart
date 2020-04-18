import 'dart:math';
import 'dart:web_audio';

import 'constants.dart';

final Random random = Random();

String englishList(
  {
    List<String> items,
    String andString = ', and ',
    String sepString = ', ',
    String emptyString = 'nothing'
  }
) {
  if (items.isEmpty) {
    return emptyString;
  }
  if (items.length == 1) {
    return items[0];
  }
  String string = '';
  final int lastIndex = items.length - 1;
  final int penultimateIndex = lastIndex - 1;
  for (int i = 0; i < items.length; i++) {
    final String item = items[i];
    string += item;
    if (i == penultimateIndex) {
      string += andString;
    } else if (i != lastIndex) {
      string += sepString;
    }
  }
  return string;
}

int randint(
  {
    int end,
    int start = 0,
  }
) {
  return random.nextInt(end) + start;
}

int distanceBetween(
  {
    int a,
    int b
  }
) {
  return (max(a, b) - min(a, b)).round();
}

void startAudio() {
  audio.listener.setOrientation(0, 0, -1, 0, 1, 0);
  audio.listener.positionZ.value = -1;
  for (final GainNode g in <GainNode>[gain, musicGain]) {
    g.gain.value = 0.5;
    g.connectNode(audio.destination);
  }
  // const music = new Sound("res/music/start.wav")
  // music.play()
}

int timestamp() {
  return DateTime.now().millisecondsSinceEpoch;
}