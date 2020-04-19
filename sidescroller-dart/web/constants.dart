import 'dart:web_audio';

import 'tts.dart';

const int audioDivider = 10;

final AudioContext audio = AudioContext();

final TextToSpeech textToSpeech = TextToSpeech();

final GainNode gain = audio.createGain();
final GainNode musicGain = audio.createGain();

const Map<String, AudioBuffer> buffers = <String, AudioBuffer>{};
