let audio = null
let gain = null
window.AudioContext = window.AudioContext || window.webkitAudioContext

const buffers = {}

function startAudio() {
  audio = new AudioContext()
  gain = audio.createGain()
  gain.gain.value = 0.5
  gain.connect(audio.destination)
  const music = new Sound("/res/music/start.wav")
  music.play()
}

class Sound {
  constructor(url, loop) {
    this.buffer = null
    this.stop = false
    this.url = url
    this.onended = null
    if (loop === undefined) {
      loop = false
    }
    this.loop = loop
  }

  getBuffer() {
    let xhr = new XMLHttpRequest()
    xhr.open("GET", this.url)
    xhr.responseType = "arraybuffer"
    xhr.onload = () => {
      audio.decodeAudioData(xhr.response).then(
        (buffer) => {
          this.playBuffer(buffer)
        }
      )
    }
    xhr.send()
  }

  playBuffer(buffer) {
    if (buffer === undefined) {
      buffer = this.buffer
    } else {
      this.buffer = buffer
      buffers[this.url] = buffer
    }
    if (!this.stop) {
      const source = audio.createBufferSource()
      source.onended = this.onended
      source.loop = this.loop
      source.buffer = buffer
      source.connect(gain)
      source.start(0)
    }
  }

  play() {
    if (this.buffer === null) {
      this.getBuffer()
    } else {
      this.playBuffer()
    }
  }
}

this.startAudio = startAudio
this.Sound = Sound
