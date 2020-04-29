import 'dart:web_audio';

import 'object.dart';
import 'tts.dart';

const int audioDivider = 10;

final AudioContext audio = AudioContext();

final TextToSpeech textToSpeech = TextToSpeech();

final GainNode soundGain = audio.createGain();
final GainNode ambianceGain = audio.createGain();
final GainNode mainGain = audio.createGain();

Map<String, AudioBuffer> buffers = <String, AudioBuffer>{};

final GameObject fists = GameObject();

num musicVolume = 0.5;
num mainVolume = 0.5;
