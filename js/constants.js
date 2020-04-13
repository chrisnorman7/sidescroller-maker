this.startDiv = document.querySelector("#startDiv")
this.mainDiv = document.querySelector("#main")
this.keyboardArea = document.querySelector("#keyboardArea")
this.startButton = document.querySelector("#startButton")
this.message = document.querySelector("#message")

function showMessage(text) {
  this.message.innerText = text
}

this.showMessage = showMessage
