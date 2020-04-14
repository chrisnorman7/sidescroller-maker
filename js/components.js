let audio = null
let gain = null
window.AudioContext = window.AudioContext || window.webkitAudioContext

const buffers = {}

function startAudio() {
  audio = new AudioContext()
  gain = audio.createGain()
  gain.gain.value = 0.5
  gain.connect(audio.destination)
  const music = new Sound("/res/music/start.wav")
  music.play()
}

this.startAudio = startAudio

class Sound {
  constructor(url, loop) {
    this.buffer = null
    this.stop = false
    this.url = url
    this.onended = null
    if (loop === undefined) {
      loop = false
    }
    this.loop = loop
  }

  getBuffer() {
    let xhr = new XMLHttpRequest()
    xhr.open("GET", this.url)
    xhr.responseType = "arraybuffer"
    xhr.onload = () => {
      audio.decodeAudioData(xhr.response).then(
        (buffer) => {
          this.playBuffer(buffer)
        }
      )
    }
    xhr.send()
  }

  playBuffer(buffer) {
    if (buffer === undefined) {
      buffer = this.buffer
    } else {
      this.buffer = buffer
      buffers[this.url] = buffer
    }
    if (!this.stop) {
      const source = audio.createBufferSource()
      source.onended = this.onended
      source.loop = this.loop
      source.buffer = buffer
      source.connect(gain)
      source.start(0)
    }
  }

  play() {
    if (this.buffer === null) {
      this.getBuffer()
    } else {
      this.playBuffer()
    }
  }
}

class Game {
  constructor() {
    this.reset()
  }

  static fromJson(data) {
    const g = new this()
    g.  title = data.title || g.title
    g.volumeChangeAmount = data.volumeChangeAmount || g.volumeChangeAmount
    for (let levelData of data.levels) {
      g.levels.push(Level.fromJson(levelData))
    }
    return g
  }

  toJson() {
    const data = {
      volumeChangeAmount: this.volumeChangeAmount,
      title: this.title,
      levels: []
    }
    for (let level of this.levels) {
      data.levels.push(level.toJson())
    }
    return data
  }

  reset() {
    this.volumeChangeAmount = 0.05
    this.title = "Untitled Game"
    this.levels = []
  }
}

this.Game = Game

class Level {
  constructor() {
    this.isLevel = true
    this.title = "Untitled Level"
    this.size = 200
    this.speed = 100
    this.numericProperties = {
      size: "The width of the level",
      speed: "How often (in milliseconds) the player can move",
      convolverVolume: "The volume of the impulse response"
    }
    this.urls = {
      beforeSceneUrl: "The scene to play before the level starts",
      afterSceneUrl: "The scene to play after the level has been completed successfully",
      musicUrl: "The background music to play throughout the scene",
      ambienceUrl: "The background of the level",
      footstepUrl: "The sound made when the player walks",
      wallUrl: "The sound heard when the player hits a wall",
      convolverUrl: "The impulse response to use for level fx"
    }
    this.beforeSceneUrl = null
    this.beforeScene = new Sound(this.beforeSceneUrl, false)
    this.afterSceneUrl = null
    this.afterScene = new Sound(this.afterSceneUrl, false)
    this.musicUrl = null
    this.music = new Sound(this.musicUrl, true)
    this.ambienceUrl = null
    this.ambience = new Sound(this.ambienceUrl, true)
    this.footstepUrl = "/res/footsteps/stone.wav"
    this.footstep = new Sound(this.footstepUrl, false)
    this.wallUrl = "/res/wall.wav"
    this.wall = new Sound(this.wallUrl, false)
    this.convolverUrl = null
    this.convolverVolume = 0.5
  }

  static fromJson(data) {
    const level = new this()
    level.title = data.title || level.title
    level.size = data.size || level.size
    level.speed = data.speed || level.speed
  }

  jump(book) {
    book.message("Jumping.")
  }

  left(book) {
    this.move(book, -1)
  }

  right(book) {
    this.move(book, 1)
  }

  move(book, direction) {
    const time = new Date().getTime()
    if ((time - book.player.lastMoved) > this.speed) {
      book.player.lastMoved = time
      let position = book.player.position + direction
      if (position < 0 || position > this.size) {
        if (this.wall !== null) {
          this.wall.play()
        }
      } else {
        book.player.position = position
        if (this.footstep !== null) {
          this.footstep.play()
        }
      }
  }
}

  play(book) {
    book.push(this)
    book.player.position = 0
  }
}

this.Level = Level

class Line{
  constructor(title, func) {
    this.title = title
    this.func = func
  }
}

this.Line = Line

class Page{
  constructor(obj) {
    // Provide a dictionary. Possible keys:
    //
    // string title:
    // The title of this page.
    //
    // array<Line> lines:
    // A list of Line instances to move through.
    //
    // Sound moveSound:
    // A Sound instance which will be played when moving up or down through the menu.
    //
    // Sound activateSound:
    // The sound to play when an item is activates.
    //
    // bool dismissible:
    // Whether or not this menu can be easily dismissed.
    this.isLevel = false
    if (obj === undefined) {
      throw("You must pass an object.")
    }
    this.focus = -1
    this.title = obj.title
    if (obj.lines === undefined) {
      obj.lines = []
    }
    this.lines = obj.lines
    if (obj.moveSound === undefined) {
      obj.moveSound = new Sound("/res/menus/move.wav")
    }
    this.moveSound = obj.moveSound
    if (obj.activateSound === undefined) {
      obj.activateSound = new Sound("/res/menus/activate.wav")
    }
    this.activateSound = obj.activateSound
    if (obj.dismissible === undefined) {
      obj.dismissible = true
    }
    this.dismissible = obj.dismissible
  }

  getLine() {
    if (this.focus == -1) {
      return null
    }
    return this.lines[this.focus]
  }
}

this.Page = Page

class Player {
  constructor() {
    this.position = null
    this.health = 100
    this.lastMoved = 0
  }
}

class Book{
  // Got the idea from the Navigator class in Flutter.

  constructor() {
    this.pages = []
    this.player = new Player()
    this.hotkeys = {
      "ArrowUp": () => this.moveUp(),
      "ArrowDown": () => this.moveDown(),
      " ": () => this.activate(),
      "ArrowRight": () => this.activate(),
      "Enter": () => this.activate(),
      "ArrowLeft": () => this.cancel(),
      "[": () => this.volumeDown(),
      "]": () => this.volumeUp(),
    }
    this.message = null
    this.game = new Game()
  }

  push(page) {
    this.pages.push(page)
    this.message(this.getText(page.title))
  }

  pop() {
    this.pages.pop() // Remove the last page from the list.
    if (this.pages.length > 0) {
      const page = this.pages.pop() // Pop the next one too, so we can push it again.
      this.push(page)
    }
  }

  getPage() {
    if (this.pages.length) {
      return this.pages[this.pages.length - 1]
    }
    return null
  }

  getFocus() {
    const page = this.getPage()
    if (page === null) {
      return null
    }
    return page.focus
  }

  showFocus() {
    const page = this.getPage()
    const line = page.getLine()
    page.moveSound.play()
    this.message(this.getText(line.title))
  }

  moveUp() {
    const page = this.getPage()
    if (page === null) {
      return // There"s probably no pages.
    } else if (page.isLevel) {
      page.jump(this)
    } else {
      const focus = this.getFocus()
      if (focus == -1) {
        return // Do nothing.
      }
      page.focus --
      if (page.focus == -1) {
        this.message(this.getText(page.title))
      } else {
        this.showFocus()
      }
    }
  }

  moveDown() {
    const page = this.getPage()
    if (page === null || page.isLevel) {
      return // There"s probably no pages.
    }
    const focus = this.getFocus()
    if (focus == (page.lines.length - 1)) {
      return // Do nothing.
    }
    page.focus++
    this.showFocus()
  }

  activate() {
    const page = this.getPage()
    if (page === null) {
      return // Can"t do anything with no page.
    } else if (page.isLevel) {
      page.right(this)
    } else {
      const line = page.getLine()
      if (line === null) {
        return // They are probably looking at the title.
      }
      page.activateSound.play()
      line.func(this)
    }
  }

  cancel() {
    const page = this.getPage()
    if (page === null || page.dismissible == false) {
      return null // No page, or the page can"t be dismissed that easily.
    } else if (page.isLevel) {
      page.left(this)
    } else {
      this.pop()
    }
  }

  setVolume(v) {
    const volumeSound = new Sound("/res/volume.wav")
    gain.gain.value = v
    volumeSound.play()
    this.message(`${Math.floor(gain.gain.value * 100)}%.`)
  }

  volumeUp() {
    this.setVolume(Math.min(1.0, gain.gain.value + this.game.volumeChangeAmount))
  }

  volumeDown() {
    this.setVolume(Math.max(0.0, gain.gain.value - this.game.volumeChangeAmount))
  }

  onkeydown(e) {
    const key = e.key
    const func = this.hotkeys[key]
    if (func !== undefined) {
      e.stopPropagation()
      func()
    }
  }

  getText(text) {
    if (typeof(text) == "function") {
      return text(this)
    }
    return text
  }
}

this.Book = Book
