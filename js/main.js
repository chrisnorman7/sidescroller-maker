/* globals book, game, gameJson, hotkeys, keyboardArea, Line, mainDiv, Page, startAudio, startButton, startDiv */

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
  const func = hotkeys[key]
  if (func !== undefined) {
    e.stopPropagation()
    func()
  }
}
