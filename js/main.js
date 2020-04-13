/* globals book, buffers, game, gameJson, keyboardArea, Level, levelSounds, Line, mainDiv, message, Page, Sound, startAudio, startButton, startDiv */

function EditLevelMenu(b, level) {
  const lines = [
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
    new Line(
      "Play", (b) => {
        level.play(b)
      }
    ),
  ]
  for (let name in levelSounds) {
    let description = levelSounds[name]
    // Let's save some old details, but the title won't reflect changes if we don't get them every time.
    let oldSound = level[name]
    let oldUrl = null
    let loop = undefined
    if (oldSound !== null) {
      oldUrl = oldSound.url
      loop = oldSound.loop
    }
    lines.push(
      new Line(
        () => `${description} (${level[name] === null ? "not set" : level[name].url}`, () => {
          const url = prompt("Enter a URL", oldUrl || "")
          if (url) {
            level[name] = new Sound(url, loop)
            delete buffers[oldUrl]
          } else {
            level[name] = null
          }
        }
      )
    )
  }
  lines.push(
    new Line(
      "Delete", (b) => {
        if (confirm(`Are you sure you want to delete "${level.title}"?`)) {
          const index = game.levels.indexOf(level)
          game.levels.splice(index, 1)
          for (let i = 0; i < 2; i++) {
            b.pop()
          }
          b.push(LevelsMenu())
        }
      }
    )
  )
  return new Page(
    {
      title: () => `Edit ${level.title}`,
      lines: lines
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
              const data = {title: game.title, levels: []}
              for (let i = 0; i < game.levels.length; i++) {
                const level = game.levels[i]
                const levelData = {
                  title: level.title,
                  size: level.size,
                }
                for (let name in levelSounds) {
                  if (level[name] === null) {
                    levelData[name] = null
                  } else {
                    levelData[name] = level[name].url
                  }
                }
                data.levels.push(levelData)
              }
              gameJson.value = JSON.stringify(data)
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
                    for (let name in levelSounds) {
                      const url = data[name]
                      if (url) {
                        l[name] = new Sound(url)
                      }
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

keyboardArea.onkeydown = (e) => {
  if (e.key == "Escape") {
    e.stopPropagation()
    if (book.getPage().isLevel) {
      book.pop()
    } else {
      book.message("You can't escape from here.")
    }
  } else {
    return book.onkeydown(e)
  }
}

book.message = (text) => {
  message.innerText = text
}
