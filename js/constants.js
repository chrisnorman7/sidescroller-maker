/* globals Book, Game */

this.startDiv = document.querySelector("#startDiv")
this.mainDiv = document.querySelector("#main")
this.keyboardArea = document.querySelector("#keyboardArea")
this.gameJson = document.querySelector("#gameJson")
this.startButton = document.querySelector("#startButton")
this.message = document.querySelector("#message")

this.game = new Game()

this.book = new Book()

this.levelSounds = {
  "footstep": "Footstep sound",
  "wall": "Wall sound",
  "ambience": "Background sound",
  "music": "Background music",
  "convolver": "Impulse",
  "beforeScene": "Audio to play before the level can be played",
  "afterScene": "The audio which should be played after the level has been completed",
}

this.levelNumericPropertyNames = [
  "size",
  "speed"
]
