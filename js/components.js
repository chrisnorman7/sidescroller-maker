const audioDivider = 10

const tts = window.speechSynthesis
let ttsVoice = null
let ttsRate =1 

let audio = null
let gain = null
window.AudioContext = window.AudioContext || window.webkitAudioContext

const buffers = {}

function startAudio() {
  audio = new AudioContext()
  audio.listener.setOrientation(0, 0, -1, 0, 1, 0)
  audio.listener.positionZ.value = -1
  gain = audio.createGain()
  gain.gain.value = 0.5
  gain.connect(audio.destination)
  const music = new Sound("res/music/start.wav")
  music.play()
}

this.startAudio = startAudio

function getBuffer(url, done) {
  let xhr = new XMLHttpRequest()
  xhr.open("GET", url)
  xhr.responseType = "arraybuffer"
  xhr.onload = () => {
    audio.decodeAudioData(xhr.response).then(done)
  }
  xhr.send()
}

class Sound {
  constructor(url, loop, output) {
    this.buffer = null
    this.stop = false
    this.url = url
    this.onended = null
    if (loop === undefined) {
      loop = false
    }
    this.loop = loop
    if (output === undefined) {
      output = gain
    }
    this.source = null
    this.output = output
  }

  playBuffer(buffer) {
    if (buffer === undefined) {
      buffer = this.buffer
    } else {
      this.buffer = buffer
      buffers[this.url] = buffer
    }
    if (!this.stop) {
      this.source = audio.createBufferSource()
      this.source.onended = this.onended
      this.source.loop = this.loop
      this.source.buffer = buffer
      this.source.connect(this.output)
      this.source.start(0)
    }
  }

  play(url) {
    if (url !== undefined) {
      this.url = url
    }
    if (this.buffer === null) {
      getBuffer(this.url, (buffer) => this.playBuffer(buffer))
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
    for (let objectData of data.objects) {
      g.objects.push(Object.fromJson(objectData))
    }
    for (let levelData of data.levels) {
      g.levels.push(Level.fromJson(levelData, g))
    }
    return g
  }

  toJson() {
    const data = {
      volumeChangeAmount: this.volumeChangeAmount,
      title: this.title,
      levels: [],
      objects: []
    }
    for (let level of this.levels) {
      data.levels.push(level.toJson(this))
    }
    for (let object of this.objects) {
      data.objects.push(object.toJson())
    }
    return data
  }

  reset() {
    this.volumeChangeAmount = 0.05
    this.title = "Untitled Game"
    this.levels = []
    this.objects = []
  }
}

this.Game = Game

const ObjectTypes = {
  object: "An object which can be picked up by the player",
  aggressiveMonster: "A monster which will attack the player",
  peacefulMonster: "A monster which will ignore the player",
  weapon: "A weapon which can be wielded"
}

class Object {
  constructor() {
    this.title = null
    this.type = ObjectTypes.object
    this.soundUrl = "res/object.wav"
  }

  static fromJson(data) {
    const o = new this()
    o.title = data.title || o.title
    o.type = data.type || o.type
    o.soundUrl = data.soundUrl || o.soundUrl
    return o
  }

  toJson() {
    return {
      title: this.title,
      type: this.type,
      soundUrl: this.soundUrl,
    }
  }
}

this.Object = Object

class LevelObject {
  constructor(obj, position) {
    this.object = obj
    this.position = position
    this.panner = null
    this.sound = null
  }

  static fromJson(data, game) {
    let c = new this()
    c.object = game.objects[data.objectIndex]
    c.position = data.position
    return c
  }

  toJson(game) {
    return {objectIndex: game.objects.indexOf(this.object), position: this.position}
  }

  spawn(level) {
    if (this.object.soundUrl !== null) {
      this.panner = audio.createPanner()
      this.panner.maxDistance = 10
      this.panner.rolloffFactor = 6
      this.panner.connect(level.convolver || gain)
      this.sound = new Sound(this.object.soundUrl, true, this.panner)
      this.sound.play()
      this.move(this.position)
    }
  }

  destroy(level) {
    const index = level.contents.indexOf(this)
    level.contents.splice(index, 1)
    this.silence()
  }

  silence() {
    if (this.sound !== null) {
      this.panner.disconnect()
      this.sound.source.disconnect()
    }
  }

  move(position) {
    this.position = position
    if (this.sound !== null) {
      this.panner.positionX.value = position / audioDivider
    }
  }
}

this.LevelObject = LevelObject

class Level {
  constructor() {
    this.loading = false
    this.isLevel = true
    this.contents = []
    this.title = "Untitled Level"
    this.numericProperties = {
      size: "The width of the level",
      speed: "How often (in milliseconds) the player can move",
      convolverVolume: "The volume of the impulse response"
    }
    this.size = 200
    this.speed = 100
    this.urls = {
      beforeSceneUrl: "The scene to play before the level starts",
      afterSceneUrl: "The scene to play after the level has been completed successfully",
      musicUrl: "The background music to play throughout the scene",
      ambienceUrl: "The background of the level",
      footstepUrl: "The sound made when the player walks",
      wallUrl: "The sound heard when the player hits a wall",
      tripUrl: "The sound that plays when a player trips over an object",
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
    this.footstepUrl = "res/footsteps/stone.wav"
    this.footstep = new Sound(this.footstepUrl, false)
    this.wallUrl = "res/wall.wav"
    this.wall = new Sound(this.wallUrl, false)
    this.tripUrl = "res/trip.wav"
    this.trip = new Sound(this.tripUrl)
    this.convolverUrl = null
    this.convolverVolume = 0.5
    this.convolver = null
    this.convolverGain = null
  }

  static fromJson(data, game) {
    const level = new this()
    level.title = data.title || level.title
    for (let name in level.numericProperties) {
      level[name] = data[name] || level[name]
    }
    for (let name in level.urls) {
      level[name] = data[name] || level[name]
    }
    for (let contentData of data.contents) {
      level.contents.push(LevelObject.fromJson(contentData, game))
    }
    return level
  }

  toJson(game) {
    const data = {title: this.title, contents: []}
    for (let name in this.numericProperties) {
      data[name] = this[name]
    }
    for (let name in this.urls) {
      data[name] = this[name]
    }
    for (let content of this.contents) {
      data.contents.push(content.toJson(game))
    }
    return data
  }

  jump(book) {
    if (this.loading) {
      return
    }
    book.message("Jumping.")
  }

  left(book) {
    this.move(book, -1)
  }

  right(book) {
    this.move(book, 1)
  }

  move(book, direction) {
    if (this.loading) {
      return
    }
    const time = new Date().getTime()
    if ((time - book.player.lastMoved) > this.speed) {
      book.player.lastMoved = time
      let position = book.player.position + direction
      if (position < 0 || position > this.size) {
        if (this.wallUrl !== null) {
          this.wall.play(this.wallUrl)
        }
      } else {
        book.setPlayerPosition(position)
        if (this.footstepUrl !== null) {
          this.footstep.play(this.footstepUrl)
        }
        for (let content of this.contents) {
          if (content.position == position) {
            this.trip.play(this.tripUrl)
            book.message(content.object.title)
          }
        }
      }
    }
  }

  play(book) {
    book.push(this)
    book.setPlayerPosition(0)
    if (this.convolverUrl !== null) {
      this.loading = true
      getBuffer(this.convolverUrl, (buffer) => {
        this.convolver = audio.createConvolver()
        this.convolver.buffer = buffer
        gain.connect(this.convolver)
        this.convolverGain = audio.createGain()
        this.convolverGain.gain.value = this.convolverVolume
        this.convolver.connect(this.convolverGain)
        this.convolverGain.connect(audio.destination)
        this.loadContents()
      })
    } else {
      this.loadContents()
    }
  }

  loadContents() {
    for (let content of this.contents) {
      content.spawn(this)
    }
    this.loading = false
  }

  leave(book) {
    book.pop()
    if (this.convolver !== null) {
      gain.disconnect(this.convolver)
      this.convolverGain.disconnect()
      this.convolver.disconnect()
      this.convolverGain = null
      this.convolver = null
    }
    for (let content of this.contents) {
      content.silence()
    }
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
      obj.moveSound = new Sound("res/menus/move.wav")
    }
    this.moveSound = obj.moveSound
    if (obj.activateSound === undefined) {
      obj.activateSound = new Sound("res/menus/activate.wav")
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

function ConfirmPage(obj) {
  // Pass an object obj, with the following keys:
  //
  // title: The title of the resulting page. Defaults to "Are you sure?".
  // okTitle: The title of the "OK" button. Defaults to "OK".
  // cancelTitle: The title of the "cancel" button. Defaults to "Cancel".
  // onok: The function to be run when the OK button is pressed.
  // oncancel: The function to be run when the cancel button is pressed.
  const lines = [
    new Line(
      obj.okTitle || "OK",
      obj.onok || ((b) => b.pop())
    ),
    new Line(
      obj.cancelTitle || "Cancel",
      obj.oncancel || ((b) => b.pop())
    )
  ]
  return new Page(
    {
      title: obj.title || "Are you sure?",
      lines: lines
    }
  )
}

function VoicesPage() {
  const lines = []
  const voices = tts.getVoices().sort(
    (a, b) => {
      const aname = a.name.toUpperCase()
      const bname = b.name.toUpperCase()
      if ( aname < bname ) {
        return -1
      } else if ( aname == bname ) {
        return 0
      } else {
        return 1
      }
    }
  )
  for (let voice of voices) {
    lines.push(
      new Line(
        () => `${(voice === ttsVoice) ? "* " : ""}${voice.name}${voice.default ? " (Default)" : ""}`, (b) => {
          ttsVoice = voice
          b.pop()
        }
      )
    )
  }
  return new Page(
    {
      title: "Available Voices",
      lines: lines
    }
  )
}

function RatePage() {
  const lines = []
  for (let i = -1; i < 21; i++) {
    lines.push(
      new Line(
        `${(i == ttsRate) ? "* " : ""}${i}`, (b) => {
          ttsRate = i
          b.pop()
        }
      )
    )
  }
  return new Page(
    {
      title: "Voice Rate",
      lines: lines
    }
  )
}

function TtsPage() {
  const lines = [
    new Line(
      "Change Voice", (b) => {
        b.push(VoicesPage())
      }
    ),
    new Line(
      "Change Rate", (b) => {
        b.push(RatePage())
      }
    ),
  ]
  return new Page(
    {
      title: "Configure TTS",
      lines: lines
    }
  )
}

this.TtsPage = TtsPage

this.ConfirmPage = ConfirmPage

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
    this.message = null
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
    this.game = new Game()
  }

  speak(text, interrupt) {
    if (interrupt) {
      tts.cancel()
    }
    const u = new SpeechSynthesisUtterance(text)
    u.voice = ttsVoice
    u.rate = ttsRate
    tts.speak(u)
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
      this.showFocus()
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
    if (!page.isLevel) {
      const line = page.getLine()
      page.moveSound.play()
      this.message(this.getText(line.title), true)
    }
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
        this.message(this.getText(page.title), true)
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
    const volumeSound = new Sound("res/volume.wav")
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

  setPlayerPosition(position) {
    this.player.position = position
    audio.listener.positionX.value = position / audioDivider
  }
}

this.Book = Book
