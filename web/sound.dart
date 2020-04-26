import 'dart:html';
import 'dart:typed_data';
import 'dart:web_audio';

import 'constants.dart';

void loadBuffer(
  {
    String url,
    void Function(AudioBuffer) done,
  }
) {
  if (url == null) {
    throw 'The url argument cannot be null.';
  }
  if (buffers.containsKey(url)){
    return done(buffers[url]);
  }
  final HttpRequest xhr = HttpRequest();
  xhr.responseType = 'arraybuffer';
  xhr.open('GET', url);
  xhr .onLoad.listen(
    (ProgressEvent e) async {
      try {
        final AudioBuffer buffer = await audio.decodeAudioData(xhr.response as ByteBuffer);
        buffers[url] = buffer;
        done(buffer);
      }
      catch(e) {
        throw 'Failed to get "$url": $e';
      }
    }
  );
  xhr.send();
}

class Sound {
  Sound (
    {
      String url,
      bool loop,
      AudioNode output,
    }
  ) {
    _url = url;
    _loop = loop;
    _output = output ?? gain;
  }

  String _url;
  bool _loop;
  AudioNode _output;
  AudioBuffer _buffer;
  AudioBufferSourceNode source;
  void Function (Event) onEnded;

  void playBuffer(
    {
      AudioBuffer buffer
    }
  ) {
    if (buffer == null) {
      buffer = _buffer;
    } else {
      _buffer = buffer;
      buffers[_url] = _buffer;
    }
    source = audio.createBufferSource();
    if (onEnded != null) {
      source.onEnded.listen(onEnded);
    }
    source.loop = _loop;
    source.buffer = _buffer;
    source.connectNode(_output);
    source.start(0);
  }

  void stop() {
    if (source != null) {
      source.disconnect();
      source = null;
    }
  }

  void play(
      {
        String url
      }
  ) {
    if (url!= _url) {
      stop();
      _buffer = null;
    }
    if (url == null) {
      return;
    }
    _url = url;
    if (_buffer == null) {
      loadBuffer(
        url: url,
        done: (AudioBuffer buffer) => playBuffer(
          buffer: buffer
        )
      );
    } else {
      playBuffer(buffer:_buffer);
    }
  }
}
