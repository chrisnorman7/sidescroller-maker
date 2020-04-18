import 'dart:web_audio';

import 'tts.dart';

final TextToSpeech textToSpeech = TextToSpeech();

const int audioDivider = 10;

final AudioContext audio = AudioContext();

final GainNode gain = audio.createGain();
final GainNode musicGain = audio.createGain();

const Map<String, AudioBuffer> buffers = <String, AudioBuffer>{};
