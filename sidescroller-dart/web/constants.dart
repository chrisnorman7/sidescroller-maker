import 'dart:html';
import 'dart:web_audio';

import 'book.dart';
import 'tts.dart';

final Element issueLink = querySelector('#issueLink');
final Element startDiv = querySelector('#startDiv');
final Element mainDiv = querySelector('main');
final Element keyboardArea = querySelector('#keyboardArea');
final Element gameJson = querySelector('#gameJson');
final Element startButton = querySelector('#startButton');
final Element message = querySelector('#message');
final Book book = Book();

final Element stringForm = querySelector('#stringForm');
final Element stringPrompt = querySelector('#stringPrompt');
final String stringPromptDefaultValue = stringPrompt.innerText;
final Element stringInput = document.querySelector('#stringInput');
final Element stringCancel = querySelector('#stringCancel');

final Element textForm = querySelector('#textForm');
final Element textPrompt = querySelector('#textPrompt');
final String textPromptDefaultValue = textPrompt.innerText;
final Element textInput = querySelector('#textInput');
final Element textCancel = querySelector('#textCancel');

final TextToSpeech textToSpeech = TextToSpeech();

const int audioDivider = 10;

final AudioContext audio = AudioContext();

final GainNode gain = audio.createGain();
final GainNode musicGain = audio.createGain();

const Map<String, AudioBuffer> buffers = <String, AudioBuffer>{};
