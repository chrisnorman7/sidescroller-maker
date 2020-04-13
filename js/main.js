/* globals book, game, gameJson, keyboardArea, Level, Line, mainDiv, message, Page, Sound, startAudio, startButton, startDiv */

function EditLevelMenu(b, level) {
  return new Page(
    {
      title: () => `Edit ${level.title}`,
      lines: [
        new Line(
          "Rename", (b) => {
            const title = prompt("Enter new level name", level.title)
            if (title && title != level.title) {
              level.title = title
              b.message("Level renamed.")
            }
          }
        ),
        new Line(
          () => `Edit Size (${level.size})`, (b) => {
            let size = Number(prompt("Enter new size", level.size), 0)
            if (isNaN(size)) {
              b.message("Invalid number.")
            } else {
              level.size = size
            }
          }
        ),
      ]
    }
  )
}

function LevelsMenu() {
  const lines = [
    new Line(
      "Add Level", (b) => {
        game.levels.push(new Level())
        b.pop()
        b.push(LevelsMenu())
      }
    )
  ]
  for (let level of game.levels) {
    lines.push(
      new Line(
        () => level.title, (b) => b.push(EditLevelMenu(b, level))
      )
    )
  }
  return new Page(
    {
      title: () => `Levels (${game.levels.length})`,
      lines: lines
    }
  )
}

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
            "Levels", b => {
              b.push(LevelsMenu())
            }
          ),
          new Line(
            "Copy Game JSON", () => {
              gameJson.value = JSON.stringify(game)
              gameJson.select()
              gameJson.setSelectionRange(0, -1)
              document.execCommand("copy")
            }
          ),
          new Line(
            "Load Game JSON", (b) => {
              if (confirm("Are you sure you want to reset your game and load from JSON?")) {
                try {
                  let obj = JSON.parse(gameJson.value)
                  game.reset()
                  game.title = obj.title || game.title
                  for (let data of obj.levels) {
                    let l = new Level()
                    for (let name of ["title", "size"]) {
                      l[name] = data[name]
                    }
                    for (let name of ["beforeScene", "afterScene", "music", "ambience"]) {
                      l[name] = new Sound(data[name])
                    }
                    game.levels.push(l)
                  }
                } catch(e) {
                  b.message(e)
                }
              }
            }
          ),
          new Line(
            "Reset Game", () => {
              if (confirm("Are you sure you want to reset the game?")) {
                game.reset()
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

keyboardArea.onkeydown = (e) => book.onkeydown(e)

book.message = (text) => {
  message.innerText = text
}
