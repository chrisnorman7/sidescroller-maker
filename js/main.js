/* globals Book, game, gameJson, keyboardArea, Line, mainDiv, Page, startAudio, startButton, startDiv */

const book = new Book()

startButton.onclick = () => {
  startAudio()
  startDiv.hidden = true
  mainDiv.hidden = false
  keyboardArea.focus()
  book.push(
    new Page(
      {
        title: "Main Menu",
        dismissible: false,
        lines: [
          new Line(
            "Set Game Name", () => {
              game.title = prompt("Enter a new name", game.title || "Untitled Game")
            }
          ),
          new Line(
            "Copy Game JavaScript", () => {
              gameJson.value = `const game = ${JSON.stringify(game)}`
              gameJson.select()
              gameJson.setSelectionRange(0, -1)
              document.execCommand("copy")
            }
          ),
          new Line(
            "Reset Game", () => {
              if (confirm("Are you sure you want to reset the game?")) {
                for (let name of [
                  "title",
                  "objects",
                  "monsters",
                  "levels",
                  "weapons",
                ]) {
                  delete game[name]
                }
              }
            }
          ),
        ]
      }
    )
  )
}

window.onload = () => {
  mainDiv.hidden = true
}

keyboardArea.onkeydown = (e) => {
  const key = e.key
  if (key == "ArrowUp") {
    book.moveUp()
  } else if (key == "ArrowDown") {
    book.moveDown()
  } else if ([" ", "ArrowRight", "Enter"].includes(key)) {
    book.activate()
  } else if (key == "ArrowLeft") {
    book.cancel()
  } else if (key == "[") {
    gain.gain.value = Math.max(0.0, gain.gain.value - 0.05)
    showMessage(`Volume: ${Math.floor(gain.gain.value * 100)}%.`)
  } else if (key == "]") {
    gain.gain.value = Math.min(1.0, gain.gain.value + 0.05)
    showMessage(`Volume: ${Math.floor(gain.gain.value * 100)}%.`)
  } else {
    return null
  }
  e.stopPropagation()
}
