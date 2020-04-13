/* globals gain, showMessage, Sound, volumeChangeAmount */

function setVolume(v) {
  const volumeSound = new Sound("/res/volume.wav")
  gain.gain.value = v
  volumeSound.play()
  showMessage(`${Math.floor(gain.gain.value * 100)}%.`)
}

this.setVolume = setVolume

function volumeUp() {
  setVolume(Math.min(1.0, gain.gain.value + volumeChangeAmount))
}

this.volumeUp = volumeUp

function volumeDown() {
  setVolume(Math.max(0.0, gain.gain.value - volumeChangeAmount))
}

this.volumeDown = volumeDown
