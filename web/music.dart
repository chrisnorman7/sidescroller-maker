import 'dart:html';
import 'dart:web_audio';

import 'constants.dart';
import 'sound.dart';

class Music {
  Music(String url) {
    output = audio.createGain();
    output.gain.value = musicVolume;
    output.connectNode(audio.destination);
    source = audio.createBufferSource();
    source.loop = true;
    source.connectNode(output);
    loadBuffer(
      url: url,
      done: setBuffer
    );
  }

  GainNode output;
  AudioBufferSourceNode source;

  void setBuffer(AudioBuffer buffer) {
    if (source != null) {
      source.buffer = buffer;
      source.start();
    }
  }

  void stop(num when) {
    try {
      source.stop(when);
    }
    on DomException {
      // Music can't be stopped if it's not already been started.
    }
    finally {
      source.disconnect();
      source = null;
    }
  }
}
