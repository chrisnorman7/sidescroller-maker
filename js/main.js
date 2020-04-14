/* globals book, Game, gameJson, keyboardArea, Level, LevelObject, Line, mainDiv, message, Page, startAudio, startButton, startDiv */

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
      "Play", (b) => {
        level.play(b)
      }
    ),
  ]
  for (let name in level.numericProperties) {
    const description = level.numericProperties[name]
    lines.push(
      new Line(
        () => `${description} (${level[name]})`, (b) => {
          let value = Number(prompt("Enter new value", level[name])) || level[name]
          if (isNaN(value)) {
            b.message("Invalid number.")
          } else {
            level[name] = value
          }
        }
      )
    )
  }
  for (let name in level.urls) {
    const description = level.urls[name]
    lines.push(
      new Line(
        () => `${description} (${level[name] === null ? "not set" : level[name]})`, () => {
          const url = prompt("Enter a URL", level[name] || "")
          if (url) {
            level[name] = url
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
          const index = b.game.levels.indexOf(level)
          b.game.levels.splice(index, 1)
          for (let i = 0; i < 2; i++) {
            b.pop()
          }
          b.push(LevelsMenu(b))
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

function LevelsMenu(b) {
  const lines = [
    new Line(
      "Add Level", (b) => {
        b.game.levels.push(new Level())
        b.pop()
        b.push(LevelsMenu(b))
      }
    )
  ]
  for (let level of b.game.levels) {
    lines.push(
      new Line(
        () => level.title, (b) => b.push(EditLevelMenu(b, level))
      )
    )
  }
  return new Page(
    {
      title: (b) => `Levels (${b.game.levels.length})`,
      lines: lines
    }
  )
}

function EditObjectMenu(b, obj) {
  const lines = [
    new Line(
      "Rename", () => {
        obj.title = prompt("New title", obj.title) || obj.title
      }
    ),
    new Line(
      () => `Sound URL (${obj.soundUrl})`, () => {
        obj.soundUrl = prompt("New URL", obj.soundUrl) || null
      }
    )
  ]
  return new Page(
    {
      title: () => `Edit ${obj.title}`,
      lines: lines
    }
  )
}

function ObjectsMenu(b) {
  const lines = [
    new Line(
      "Add Object", (b) => {
        const title = prompt("Enter the name for the new object") || ""
        if (title) {
          const obj = new Object()
          obj.title = title
          b.game.objects.push(obj)
          b.pop()
          b.push(ObjectsMenu(b))
        }
      }
    ),
  ]
  for (let obj of b.game.objects) {
    lines.push(
      new Line(
        () => obj.title, (b) => b.push(EditObjectMenu(b, obj))
      )
    )
  }
  return new Page(
    {
      title: (b) => `Objects (${b.game.objects.length})`,
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
            "Set Game Name", (b) => {
              b.game.title = prompt("Enter a new name", b.game.title || "Untitled Game")
            }
          ),
          new Line(
            "Levels", b => {
              b.push(LevelsMenu(b))
            }
          ),
          new Line(
            "Objects", (b) => {
              b.push(ObjectsMenu(b))
            }
          ),
          new Line(
            "Set Volume Change Amount", (b) => {
              const value = Number(prompt("Enter new value", b.game.volumeChangeAmount), 2)
              if (isNaN(value)) {
                b.message("Invalid value.")
              } else {
                b.game.volumeChangeAmount = Number(value, 2) || b.game.volumeChangeAmount
              }
            }
          ),
          new Line(
            "Copy Game JSON", (b) => {
              gameJson.value = JSON.stringify(b.game.toJson())
              gameJson.select()
              gameJson.setSelectionRange(0, -1)
              document.execCommand("copy")
            }
          ),
          new Line(
            "Load Game JSON", (b) => {
              if (confirm("Are you sure you want to reset your game and load from JSON?")) {
                let obj = JSON.parse(gameJson.value)
                b.game = Game.fromJson(obj)
              }
            }
          ),
          new Line(
            "Reset Game", (b) => {
              if (confirm("Are you sure you want to reset the game?")) {
                b.game.reset()
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
  try {
    if (e.key == "Escape") {
      const page = book.getPage()
      if (page.isLevel) {
        page.leave(book)
      } else {
        book.message("You can't escape from here.")
      }
    } else if (e.key == "o") {
      const page = book.getPage()
      if (page.isLevel) {
        const lines = []
        for (let obj of book.game.objects) {
          lines.push(
            new Line(
              obj.title, (b) => {
                const content = new LevelObject(obj, book.player.position)
                page.contents.push(content)
                content.spawn(page)
                b.pop()
              }
            )
          )
        }
        book.push(
          new Page(
            {
              title: "Add Object",
              lines: lines
            }
          )
        )
      }
    } else {
      return book.onkeydown(e)
    }
    e.stopPropagation()
  } catch(e) {
    book.message(e)
    throw(e)
  }
}

book.message = (text) => {
  message.innerText = text
}
