/* globals Book, ConfirmPage, englishList, gain, Game, Level, LevelDirections, Line, musicGain, objectTypes, Page, startAudio, TtsPage */

let lastError = null
window.addEventListener("error", (e) => {
  lastError = e
})

const issueLink = document.querySelector("#issueLink")
const startDiv = document.querySelector("#startDiv")
const mainDiv = document.querySelector("#main")
const keyboardArea = document.querySelector("#keyboardArea")
const gameJson = document.querySelector("#gameJson")
const startButton = document.querySelector("#startButton")
const message = document.querySelector("#message")
let book = null

const stringForm = document.querySelector("#stringForm")
const stringPrompt = document.querySelector("#stringPrompt")
const stringPromptDefaultValue = stringPrompt.innerText
const stringInput = document.querySelector("#stringInput")
const stringCancel = document.querySelector("#stringCancel")

const textForm = document.querySelector("#textForm")
const textPrompt = document.querySelector("#textPrompt")
const textPromptDefaultValue = textPrompt.innerText
const textInput = document.querySelector("#textInput")
const textCancel = document.querySelector("#textCancel")

function getText(obj) {
  // Pass a dictionary with the following keys:
  //
  // book: The book that called this function. This value must be provided.
  // multiline: Sets whether or not to show a single line, or multiline text field. Defaults to false.
  // prompt: The prompt text to show. Defaults to textPromptDefaultValue if multiline is true, or stringPromptDefaultValue otherwise.
  // value: The default value. Defaults to an empty string.
  // onok: The callback to be called as onok(value, book), where value is the value that was entered. Defaults to book.message.
  // oncancel: A callback to be called as oncancel(form, book), where form is the form that was chosen based on the value of multiline. Defaults to a callback that hides the form.
  obj.multiline = obj.multiline || false
  if (!obj.prompt) {
    if (obj.multiline) {
      obj.prompt = textPromptDefaultValue
    } else {
      obj.prompt = stringPromptDefaultValue
    }
  }
  obj.value = obj.value || ""
  if (!obj.onok) {
    obj.onok = (text) => {
      obj.book.message(text)
    }
  }
  if (!obj.oncancel) {
    obj.oncancel = (f, b) => {
      inputElement.value = ""
      f.hidden = true
      keyboardArea.focus()
      b.showFocus()
    }
  }
  let form, promptElement, inputElement, cancelElement = null
  if (obj.multiline) {
    form = textForm
    promptElement = textPrompt
    inputElement = textInput
    cancelElement = textCancel
  } else {
    form = stringForm
    promptElement = stringPrompt
    inputElement = stringInput
    cancelElement = stringCancel
  }
  cancelElement.onclick = () => obj.oncancel(form, obj.book)
  form.onkeydown = (e) => {
    if (e.key == "Escape") {
      e.preventDefault()
      cancelElement.click()
    }
  }
  inputElement.value = obj.value
  inputElement.setSelectionRange(0, -1)
  promptElement.innerText = obj.prompt
  form.hidden = false
  form.onsubmit = (e) => {
    e.preventDefault()
    form.hidden = true
    obj.book.showFocus()
    obj.onok(inputElement.value, obj.book)
    keyboardArea.focus()
  }
  inputElement.focus()
}

function EditLevelMenu(b, level) {
  const lines = [
    new Line(
      "Rename", (b) => {
        getText(
          {
            book: b,
            prompt: "Enter new level name",
            value: level.title,
            onok: (title, bk) => {
              if (title && title != level.title) {
                level.title = title
                bk.message("Level renamed.")
              }
            }
          }
        )
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
          getText(
            {
              book: b,
              prompt: "Enter new value",
              value: level[name],
              onok: (value, bk) => {
                value = Number(value)
                if (isNaN(value)) {
                  bk.message("Invalid number.")
                } else {
                  level[name] = value
                }
              }
            }
          )
        }
      )
    )
  }
  for (let name in level.urls) {
    const description = level.urls[name]
    lines.push(
      new Line(
        () => `${description} (${level[name] === null ? "not set" : level[name]})`, (b) => {
          getText(
            {
              book: b,
              prompt: "Enter a URL",
              value: level[name] || "",
              onok: (url, bk) => {
                if (url) {
                  level[name] = url
                } else {
                  level[name] = null
                }
                bk.showFocus()
              }
            }
          )
        }
      )
    )
  }
  lines.push(
    new Line(
      "Delete", (b) => {
        b.push(
          ConfirmPage(
            {
              title: `Are you sure you want to delete "${level.title}"?`,
              okTitle: "Yes",
              cancelTitle: "No",
              onok: (b) => {
                const index = b.game.levels.indexOf(level)
                b.game.levels.splice(index, 1)
                for (let i = 0; i < 2; i++) {
                  b.pop()
                }
                b.push(LevelsMenu(b))
                b.message("Level deleted.")
              }
            }
          )
        )
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
        getText(
          {
            book: b,
            prompt: "New title",
            value: obj.title,
            onok: (title, bk) => {
              obj.title = title || obj.title
              bk.showFocus()
            }
          }
        )
      }
    ),
    new Line(
      () => `Set Type (${obj.type})`, (b) => {
        const lines = []
        for (let name in objectTypes) {
          const description = objectTypes[name]
          lines.push(
            new Line(
              description, (b) => {
                obj.type = description
                b.pop()
              }
            )
          )
        }
        b.push(
          new Page(
            {
              title: "Set Object Type",
              lines: lines
            }
          )
        )
      }
    ),
    new Line(
      () => `Target Level (${obj.targetLevel === null ? "not set" : obj.targetLevel.title})`, (b) => {
        const lines = []
        for (let level of b.game.levels) {
          lines.push(
            new Line(
              level.title, (b) => {
                obj.targetLevel = level
                b.pop()
                b.message("Level set.")
              }
            )
          )
        }
        b.push(
          new Page(
            {
              title: "Set exit destination",
              lines: lines
            }
          )
        )
      }
    ),
    new Line(
      () => `Contained Objects (${obj.contains.length})`, (b) => {
        b.push(
          ObjectsMenu(
            obj.contains,
            (b, onadd) => {
              const objectLines = []
              for (let o of b.game.objects) {
                objectLines.push(
                  new Line(
                    o.title, (b) => {
                      obj.contains.push(o)
                      b.pop()
                      onadd()
                    }
                  )
                )
              }
              b.push(
                new Page(
                  {
                    title: "Select Object",
                    lines: objectLines
                  }
                )
              )
            },
          )
        )
      }
    ),
  ]
  for (let name in obj.numericProperties) {
    const description = obj.numericProperties[name]
    lines.push(
      new Line(
        () => `${description} (${obj[name]})`, (b) => {
          getText(
            {
              book: b,
              prompt: "Enter new value",
              value: obj[name],
              onok: (value, bk) => {
                value = Number(value)
                if (isNaN(value)) {
                  bk.message("Invalid number.")
                } else {
                  obj[name] = value
                }
              }
            }
          )
        }
      )
    )
  }
  for (let name in obj.urls) {
    const description = obj.urls[name]
    lines.push(
      new Line(
        () => `${description} (${obj[name] === null ? "not set" : obj[name]})`, (b) => {
          getText(
            {
              book: b,
              prompt: "Enter a URL",
              value: obj[name] || "",
              onok: (url, bk) => {
                if (url) {
                  obj[name] = url
                } else {
                  obj[name] = null
                }
                bk.showFocus()
              }
            }
          )
        }
      )
    )
  }
  return new Page(
    {
      title: () => `Edit ${obj.title}`,
      lines: lines
    }
  )
}

function ObjectsMenu(initialObjects, addObject, editObject) {
  const lines = [
    new Line(
      "Add Object", (b) => {
        addObject(b, () => {
          b.pop()
          const page = ObjectsMenu(initialObjects, addObject, editObject)
          page.focus = initialObjects.length
          b.push(page)
        })
      }
    )
  ]
  for (let obj of initialObjects) {
    lines.push(
      new Line(
        () => obj.title, (b) => editObject(b, obj)
      )
    )
  }
  return new Page(
    {
      title: () => `Objects (${initialObjects.length})`,
      lines: lines
    }
  )
}

function GameMenu(game) {
  const lines = [
    new Line(
      "Rename", (b) => {
        getText(
          {
            book: b,
            prompt: "Enter a new name",
            value: game.title,
            onok: (text) => {
              game.title = text || game.title
            }
          }
        )
      }
    ),
    new Line(
      "Volume Change Amount", (b) => {
        getText(
          {
            book: b,
            prompt: "Enter new value",
            value: game.volumeChangeAmount,
            onok: (value, bk) => {
              value = Number(value, 2)
              bk.showFocus()
              if (isNaN(value)) {
                bk.message("Invalid value.")
              } else {
                game.volumeChangeAmount = Number(value, 2) || game.volumeChangeAmount
              }
            }
          }
        )
      }
    ),
  ]
  for (let name in game.urls) {
    const description = game.urls[name]
    lines.push(
      new Line(
        () => `${description} (${game[name] === null ? "Not set" : game[name]})`, (b) => {
          getText(
            {
              book: b,
              prompt: "Enter a new URL",
              value: game[name],
              onok: (value, bk) => {
                game[name] = value || null
                if (name == "musicUrl") {
                  game.reloadMusic(bk)
                }
              }
            }
          )
        }
      )
    )
  }
  for (let name in game.numericProperties) {
    const description = game.numericProperties[name]
    lines.push(
      new Line(
        () => `${description} (${game[name]})`, (b) => {
          getText(
            {
              book: b,
              prompt: "Enter new value",
              value: game[name],
              onok: (value, bk) => {
                value = Number(value, 2)
                if (isNaN(value)) {
                  bk.message("Invalid number.")
                } else {
                  game[name] = value
                }
              }
            }
          )
        }
      )
    )
  }
  return new Page(
    {
      title: "Game Menu",
      lines: lines
    }
  )
}

startButton.onclick = () => {
  startAudio()
  startDiv.hidden = true
  mainDiv.hidden = false
  keyboardArea.focus()
  book = new Book()
  book.message = (text) => {
    message.innerText = text
  }
  book.push(
    new Page(
      {
        title: "Main Menu",
        dismissible: false,
        lines: [
          new Line(
            "Levels", b => {
              b.push(LevelsMenu(b))
            }
          ),
          new Line(
            "Objects and Monsters", (b) => {
              b.push(
                ObjectsMenu(
                  b.game.objects, (b, onadd) => {
                    getText(
                      {
                        book: b,
                        prompt: "Enter the name for the new object",
                        onok: (title, bk) => {
                          if (title) {
                            const obj = new Object()
                            obj.title = title
                            bk.game.objects.push(obj)
                            onadd()
                          }
                        }
                      }
                    )
                  },
                  (b, obj) => b.push(EditObjectMenu(b, obj))
                )
              )
            }
          ),
          new Line(
            "Configure Game", (b) => {
              b.push(GameMenu(b.game))
            }
          ),
          new Line(
            "Load Game JSON", (b) => {
              b.push(
                new ConfirmPage(
                  {
                    title: "Are you sure you want to reset your game and load from JSON?",
                    onok: (b) => {
                      b.pop()
                      let obj = JSON.parse(gameJson.value)
                      b.game.stopMusic()
                      b.game = Game.fromJson(obj)
                      b.game.reloadMusic(b)
                      b.message("Game loaded.")
                    }
                  }
                )
              )
            }
          ),
          new Line(
            "Copy Game JSON", (b) => {
              const data = b.game.toJson()
              const json = JSON.stringify(data, undefined, 2)
              gameJson.value = json
              gameJson.select()
              gameJson.setSelectionRange(0, -1)
              document.execCommand("copy")
              keyboardArea.focus()
              b.message("JSON copied.")
            }
          ),
          new Line(
            "Reset Game", (b) => {
              b.push(
                new ConfirmPage(
                  {
                    title: "Are you sure you want to reset the game?",
                    onok: (b) => {
                      b.game.reset()
                      b.pop()
                      b.message("Game reset.")
                    }
                  }
                )
              )
            }
          ),
          new Line(
            "Configure TTS", (b) => {
              b.push(TtsPage())
            }
          ),
          new Line(
            "Throw an Error", (b) => {
              b.pop()
              throw(Error("Error intentionally thrown by user."))
            }
          ),
        ]
      }
    )
  )
}

window.onload = () => {
  for (let e of [mainDiv, stringForm, textForm]) {
    e.hidden = true
  }
  const issueUrl = issueLink.href
  issueLink.onclick = (e) => {
    e.target.href = issueUrl // Fallback in case something breaks
    let title = null
    let body = ""
    try {
      let json = "No game loaded"
      let player = null
      let game = null
      if (book === null) {
        title = "before start button has been clicked"
      } else {
        game = book.game
        player = book.player
        if (game == null || game === undefined) {
          title = "with a null game"
        } else {
          json = JSON.stringify(game.toJson(), undefined, 2)
          const page = book.getPage()
          if (page === null || page === undefined) {
            title = "with no page pushed"
          } else {
            let type = null
            let lineTitle = null
            if (page.isLevel) {
              type = "level"
              let facing = null
              if (player.facing == LevelDirections.forwards) {
                facing = "forwards"
              } else if (player.facing == LevelDirections.backwards) {
                facing = "backwards"
              } else if (player.facing == LevelDirections.either) {
                facing = "either way"
              } else {
                facing = player.facing.toString()
              }
              lineTitle = `at position ${book.player.position}, facing ${facing}`
            } else {
              const line = page.getLine()
              type = "page"
              if (line === null) {
                lineTitle = "not focussed on any particular line"
              } else {
                lineTitle = `focussed on a line called "${book.getText(line.title)}"`
              }
            }
            title = `with a ${book.pages.length} deep ${type} called "${book.getText(page.title)}", ${lineTitle}`
          }
        }
      }
      let soundVolume = null
      if (gain === null || gain === undefined) {
        soundVolume = "Sound output not present"
      } else {
        soundVolume = gain.gain.value.toFixed(2)
      }
      let musicVolume = null
      if (musicGain === null || musicGain === undefined) {
        musicVolume = "Music output not present"
      } else {
        musicVolume = musicGain.gain.value.toFixed(2)
        if (game.music !== null && game.music.source !== null) {
          musicVolume += " (music present)"
        } else {
          musicVolume += " (music not present)"
        }
      }
      let lastErrorData = null
      if (lastError !== null) {
        lastErrorData = {
          message: lastError.message,
          // Code copied from https://stackoverflow.com/questions/11550790/remove-hostname-and-port-from-url-using-regular-expression:
          filename: lastError.filename.replace (/^[a-z]{4,5}:\/{2}[a-z]{1,}:[0-9]{1,4}.(.*)/, '$1'),
          line: lastError.lineno,
          column: lastError.colno,
          type: lastError.type,
          srcElement: lastError.srcElement.toString()
        }
      }
      const stats = {
        "Sound volume": soundVolume,
        "Music volume": musicVolume,
        "Languages": englishList(navigator.languages),
        "Platform": navigator.platform || "Unknown",
        "Last error thrown": JSON.stringify(lastErrorData, undefined, 2)
      }
      if (player !== null) {
        stats["Player health"] = player.health
        stats["Player carrying"] = englishList(
          Array.from(
            player.carrying,
            (e) => e.title
          )
        )
        let weaponTitle = "Not present"
        if (player.weapons !== null) {
          weaponTitle = player.weapon.title
        }
        stats["Weapon"] = weaponTitle
      }
      for (let key in stats) {
        const value = stats[key]
        body += `\n${key}: ${value}`
      }
      body += `\n\nSteps to reproduce:\n1. \n2. \n3. \n\nGame JSON:\n${json}`
      title = `Problem ${title}`
    } catch(e) {
      throw(e)
      title = "Issue while running onclick handler"
      body = `Error: ${e.message}`
    }
    e.target.href = `${issueUrl}?title=${encodeURI(title)}&body=${encodeURI(body)}`
  }
}

keyboardArea.onkeydown = (e) => {
  for (let modifier of ["Alt", "AltGraph", "CapsLock", "Control", "Fn", "FnLock", "Hyper", "Meta", "NumLock", "ScrollLock", "Shift", "Super", "Symbol", "SymbolLock"]) {
    if (e.getModifierState(modifier)) {
      return
    }
  }
  try {
    const page = book.getPage()
    if (e.key == "Escape" && page.isLevel) {
      page.leave(book)
    } else if (e.key == "o" && page.isLevel) {
      const lines = []
      for (let obj of book.game.objects) {
        lines.push(
          new Line(
            obj.title, (b) => {
              obj.drop(page, b.player.position, true)
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
    } else {
      book.onkeydown(e)
    }
  } catch(e) {
    book.message(e)
    throw(e)
  }
}
