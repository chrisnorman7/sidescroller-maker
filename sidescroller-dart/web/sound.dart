import 'dart:html';
import 'dart:typed_data';
import 'dart:web_audio';

import 'package:http/http.dart' as http;

import 'constants.dart';

Future<AudioBuffer> getBuffer(
  {
    String url,
  }
) async {
  if (buffers.containsKey(url) == false){
    final http.Response response = await http.get(url);
    buffers[url] = await audio.decodeAudioData(response.body as ByteBuffer);
  }
  return buffers[url];
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
    _output = output;
  }

  String _url;
  bool _loop;
  AudioNode _output;
  AudioBuffer _buffer;
  AudioBufferSourceNode _source;
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
    _source = audio.createBufferSource();
    if (onEnded != null) {
      _source.onEnded.listen(onEnded);
    }
    _source.loop = _loop;
    _source.buffer = _buffer;
    _source.connectNode(_output);
    _source.start(0);
  }

  void stop() {
    if (_source != null) {
      _source.disconnect();
      _source = null;
    }
  }

  Future<void> play(
    {
      String url
    }
  ) async {
    if (url!= _url) {
      stop();
      if (url == null) {
        return;
      }
      _buffer = null;
    }
    _url = url;
    _buffer ??= await getBuffer(
      url: url
    );
    playBuffer(
      buffer: _buffer
    );
  }
}
