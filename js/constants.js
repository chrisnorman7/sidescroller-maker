this.startDiv = document.querySelector("#startDiv")
this.mainDiv = document.querySelector("#main")
this.keyboardArea = document.querySelector("#keyboardArea")
this.gameJson = document.querySelector("#gameJson")
this.startButton = document.querySelector("#startButton")
this.message = document.querySelector("#message")

function showMessage(text) {
  this.message.innerText = text
}

this.showMessage = showMessage

this.game = {}
