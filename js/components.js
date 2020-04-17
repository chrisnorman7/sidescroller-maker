const audioDivider = 10

const tts = window.speechSynthesis
let ttsVoice = null
let ttsRate =1

let audio = null
let gain = null
let musicGain = null
window.AudioContext = window.AudioContext || window.webkitAudioContext

const LevelDirections = {
  backwards: -1,
  either: 0,
  forwards: 1
}

function randint(start, end) {
  const r = Math.random() * end + start
  return Math.round(r)
}

const buffers = {}

function distanceBetween(a, b) {
  return Math.max(a, b) - Math.min(a, b)
}

function startAudio() {
  audio = new AudioContext()
  audio.listener.setOrientation(0, 0, -1, 0, 1, 0)
  audio.listener.positionZ.value = -1
  gain = audio.createGain()
  musicGain = audio.createGain()
  for (let g of [gain, musicGain]) {
    g.gain.value = 0.5
    g.connect(audio.destination)
  }
  const music = new Sound("res/music/start.wav")
  music.play()
  fists = new Object()
  fists.title = "Fists"
  fists.type = objectTypes.weapon
}

this.startAudio = startAudio

function getBuffer(url, done) {
  if (typeof(url) != "string") {
    throw(`Must provide URL as a string. (${url})`)
  }
  const buffer = buffers[url]
  if (buffer === undefined) {
    let xhr = new XMLHttpRequest()
    xhr.open("GET", url)
    xhr.responseType = "arraybuffer"
    xhr.onload = () => {
      audio.decodeAudioData(xhr.response).then(done, (e) => {
        console.log(`Error decoding "${url}": ${e}`)
      })
    }
    xhr.send()
  } else {
    done(buffer)
  }
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
      if (this.url === undefined) {
        throw("An undefined URL was provided for a sound with an already-undefined url.")
      }
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
    if (url === null) {
      if (this.source !== null) {
        this.source.disconnect()
      }
      this.source = null
      return
    } else if (url !== undefined) {
      if (url != this.url) {
        this.buffer = null
      }
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
    for (let d of [g.urls, g.numericProperties]) {
      for (let name in d) {
        const value = data[name]
        if (value !== undefined) {
          g[name] = data[name]
        }
      }
    }
    for (let objectData of data.objects) {
      g.objects.push(Object.fromJson(objectData))
    }
    for (let levelData of data.levels) {
      const level = Level.fromJson(levelData, g)
      g.levels.push(level)
    }
    for (let obj of g.objects) {
      if (obj.targetLevelIndex !== null) {
        obj.targetLevel = g.levels[obj.targetLevelIndex]
      }
    }
    g.resetVolumes()
    return g
  }

  toJson() {
    const data = {
      title: this.title,
      levels: [],
      objects: []
    }
    for (let d of [this.urls, this.numericProperties]) {
      for (let name in d) {
        data[name] = this[name]
      }
    }
    for (let level of this.levels) {
      data.levels.push(level.toJson(this))
    }
    for (let object of this.objects) {
      data.objects.push(object.toJson(this))
    }
    return data
  }

  reset() {
    this.urls = {
      volumeSoundUrl: "Volume change sound",
      moveSoundUrl: "Menu navigation sound",
      activateSoundUrl: "Activate sound",
      musicUrl: "Menu music"
    }
    this.volumeSoundUrl = "res/menus/volume.wav"
    this.moveSoundUrl = "res/menus/move.wav"
    this.moveSound = new Sound(this.moveSoundUrl)
    this.activateSoundUrl = "res/menus/activate.wav"
    this.activateSound = new Sound(this.activateSoundUrl)
    this.musicUrl = "res/menus/music.mp3"
    this.music = null
    this.numericProperties = {
      volumeChangeAmount: "Volume key sensitivity",
      initialVolume: "Initial volume",
      initialMusicVolume: "Initial music volume",
    }
    this.volumeChangeAmount = 0.05
    this.initialVolume = 0.5
    this.initialMusicVolume = 0.25
    this.title = "Untitled Game"
    this.levels = []
    this.objects = []
    this.resetVolumes()
  }
  
  resetVolumes() {
    gain.gain.value = this.initialVolume
    musicGain.gain.value = this.initialMusicVolume
  }

  stopMusic() {
    if (this.music !== null) {
      if (this.music.source !== null) {
        this.music.source.disconnect()
      }
      this.music = null
    }
  }

  reloadMusic(book) {
    this.stopMusic()
    book.push(
      new Page(
        {
          title: "Reloading game music..."
        }
      )
    )
    book.pop()
  }
}

this.Game = Game

const objectTypes = {
  object: "An object which can be picked up by the player",
  aggressiveMonster: "A monster which will attack the player",
  peacefulMonster: "A monster which will ignore the player",
  weapon: "A weapon which can be wielded",
  exit: "An exit to another level"
}

class Object {
  constructor() {
    this.title = null
    this.targetLevel = null
    this.targetLevelIndex = null
    this.type = objectTypes.object
    this.urls = {
      soundUrl: "The sound constantly played by this object",
      takeUrl: "The sound played when picking up this object",
      dropUrl: "The sound that is played when this object is dropped",
      hitUrl: "The sound that is heard when this object is hit",
      useUrl: "The sound that is played when this object is used or fired",
      cantUseUrl: "The sound to be played when this object can't be used",
      dieUrl: "The sound played when this object is killed or destroyed",
    }
    this.takeUrl = "res/objects/take.wav"
    this.take = new Sound(this.takeUrl)
    this.soundUrl = "res/objects/object.wav"
    this.dropUrl = "res/objects/drop.wav"
    this.hitUrl = "res/objects/hit.wav"
    this.useUrl = "res/weapons/punch.wav"
    this.use = new Sound(this.useUrl)
    this.cantUseUrl = "res/objects/cantuse.wav"
    this.cantUse = new Sound(this.cantUseUrl)
    this.dieUrl = "res/objects/die.wav"
    this.numericProperties = {
      damage: "The amount of damage dealt by this weapon",
      range: "The range of this weapon",
      health: "The initial health of this object",
      targetPosition: "The position the player should be in after using this exit",
    }
    this.damage = 2
    this.range = 1
    this.health = 1
    this.targetPosition = 0
  }

  static fromJson(data) {
    const o = new this()
    o.title = data.title || o.title
    o.type = data.type || o.type
    o.targetLevelIndex = data.targetLevelIndex
    for (let d of [o.urls, o.numericProperties]) {
      for (let name in d) {
        if (data[name] === undefined) {
          data[name] = o[name]
        }
        o[name] = data[name]
      }
    }
    return o
  }

  toJson(game) {
    const data = {
      title: this.title,
      type: this.type,
    }
    if (this.targetLevel === null) {
      data.targetLevelIndex = null
    } else {
      data.targetLevelIndex = game.levels.indexOf(this.targetLevel)
    }
    for (let d of [this.urls, this.numericProperties]) {
      for (let name in d) {
        data[name] = this[name]
      }
    }
    return data
  }

  drop(level, position) {
    const content = new LevelObject(level, this, position)
    level.contents.push(content)
    content.spawn()
    content.drop.play(this.dropUrl)
  }
}

let fists = null

class LevelObject {
  constructor(level, obj, position) {
    this.level = level
    this.object = obj
    this.position = position
    this.health = obj.health
    this.panner = null
    this.sound = null
    this.drop = null
    this.dieSound = null
  }

  static fromJson(level, data, game) {
    const obj = game.objects[data.objectIndex]
    let c = new this(level, obj, data.position)
    return c
  }

  toJson(game) {
    return {objectIndex: game.objects.indexOf(this.object), position: this.position}
  }

  spawn() {
    const obj = this.object
    this.panner = audio.createPanner()
    this.panner.maxDistance = 10
    this.panner.rolloffFactor = 6
    this.panner.connect(gain)
    this.move(this.position)
    if (obj.soundUrl !== null) {
      this.sound = new Sound(obj.soundUrl, true, this.panner)
      this.sound.play()
    }
    this.drop = new Sound(this.dropUrl, false, this.panner)
    this.hit = new Sound(obj.hitUrl, false, this.panner)
    this.dieSound = new Sound(obj.dieUrl, false, this.panner)
  }

  destroy() {
    const index = this.level.contents.indexOf(this)
    this.level.contents.splice(index, 1)
    this.silence(true)
  }

  silence(disconnectPanner) {
    if (disconnectPanner) {
      this.panner.disconnect()
    }
    if (this.sound !== null) {
      this.sound.stop = true
      this.sound.source.disconnect()
    }
  }

  move(position) {
    this.position = position
    this.panner.positionX.value = position / audioDivider
  }

  die() {
    this.silence(false)
    const index = this.level.contents.indexOf(this)
    this.level.contents.splice(index, 1)
    if (this.object.dieUrl !== null) {
      this.level.deadObjects.push(this)
      this.die.onended = () => {
        const index = this.level.deadObjects.indexOf(this)
        if (index != -1) {
          this.level.deadObjects.splice(index, 1)
        }
      }
      this.dieSound.play(this.object.dieUrl)
    }
  }
}

this.LevelObject = LevelObject

class Level {
  constructor() {
    this.focus = -1 // Just to fool Book.showFocus
    this.loading = false
    this.isLevel = true
    this.deadObjects = []
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
      beforeSceneUrl: "Scene to play before the level starts",
      musicUrl: "Background music",
      ambianceUrl: "Level Ambiance",
      footstepUrl: "Footstep sound",
      wallUrl: "Wall sound",
      turnUrl: "Turning sound",
      tripUrl: "Object discovery sound",
      convolverUrl: "Impulse response",
      noWeaponUrl: "Empty weapons slot"
    }
    this.beforeSceneUrl = null
    this.beforeScene = new Sound(this.beforeSceneUrl, false)
    this.musicUrl = null
    this.music = new Sound(this.musicUrl, true)
    this.ambianceUrl = null
    this.ambiance = new Sound(this.ambianceUrl, true)
    this.footstepUrl = "res/footsteps/stone.wav"
    this.footstep = new Sound(this.footstepUrl, false)
    this.wallUrl = "res/level/wall.wav"
    this.wall = new Sound(this.wallUrl, false)
    this.turnUrl = "res/level/turn.wav"
    this.turn = new Sound(this.turnUrl)
    this.tripUrl = "res/level/trip.wav"
    this.trip = new Sound(this.tripUrl)
    this.convolverUrl = null
    this.convolverVolume = 0.5
    this.convolver = null
    this.convolverGain = null
    this.noWeaponUrl = "res/level/noweapon.wav"
    this.noWeapon = new Sound(this.noWeaponUrl)
  }

  static fromJson(data, game) {
    const level = new this()
    level.title = data.title || level.title
    for (let d of [level.urls, level.numericProperties]) {
      for (let name in d) {
        if (data[name] === undefined) {
          data[name] = level[name]
        }
        level[name] = data[name]
      }
    }
    for (let contentData of data.contents) {
      const content = LevelObject.fromJson(level, contentData, game)
      level.contents.push(content)
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

  nearestObject(position, direction) {
    if (direction === undefined) {
      direction = LevelDirections.either
    }
    let distance = null
    let obj = null
    for (let content of this.contents) {
      if ((direction == LevelDirections.forwards && content.position >= position) || (direction == LevelDirections.backwards && content.position <= position)) {
        const newDistance = distanceBetween(position, content.position)
        if (distance === null || newDistance < distance) {
          obj = content
        }
        distance = newDistance
      }
    }
    return obj
  }

  jump(book) {
    if (this.loading) {
      return
    }
    book.message("Jumping.")
  }

  left(book) {
    this.move(book, LevelDirections.backwards)
  }

  right(book) {
    this.move(book, LevelDirections.forwards)
  }

  move(book, direction) {
    if (this.loading) {
      return
    }
    const player = book.player
    const time = new Date().getTime()
    if ((time - player.lastMoved) > this.speed) {
      player.lastMoved = time
      let position = player.position + direction
      if (position < 0 || position > this.size) {
        this.wall.play(this.wallUrl)
      } else {
        book.setPlayerPosition(position)
        if (direction != player.facing) {
          if (player.facing != LevelDirections.either) {
            this.turn.play(this.turnUrl)
          }
          player.facing = direction
        }
        this.footstep.play(this.footstepUrl)
      }
    }
  }

  finalise(book) {
    book.push(this)
    book.player.level = this
    this.ambiance.play(this.ambianceUrl)
    this.loadContents()
    book.setPlayerPosition(this.initialPosition)
  }

  play(book, initialPosition) {
    if (initialPosition === undefined) {
      initialPosition = 0
    }
    this.initialPosition = initialPosition
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
      })
    }
    if (this.beforeSceneUrl === null) {
      this.finalise(book)
    } else {
      book.playScene(this.beforeSceneUrl, (b) => this.finalise(b))
    }
  }

  loadContents() {
    for (let content of this.contents) {
      content.spawn()
    }
    this.loading = false
  }

  leave(book) {
    book.pop()
    book.player.level = null
    if (this.convolver !== null) {
      gain.disconnect(this.convolver)
      this.convolverGain.disconnect()
      this.convolver.disconnect()
      this.convolverGain = null
      this.convolver = null
    }
    for (let content of this.contents) {
      content.silence(true)
    }
    for (let corpse of this.deadObjects) {
      corpse.destroy()
    }
    if (this.ambiance.source !== null) {
      this.ambiance.source.disconnect()
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

this.ConfirmPage = ConfirmPage

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

function HotkeysPage(book) {
  const hotkeyConvertions = {
    " ": "Spacebar"
  }
  const lines = []
  const page = book.getPage()
  for (let key in book.hotkeys) {
    const hotkey = book.hotkeys[key]
    let keyString = key
    if (keyString in hotkeyConvertions) {
      keyString = hotkeyConvertions[keyString]
    }
    lines.push(
      new Line(
        `${keyString}: ${hotkey.getDescription(page)}`,
        (b) => {
          b.pop()
          hotkey.func()
        }
      )
    )
  }
  return new Page(
    {
      title: "Hotkeys",
      lines: lines
    }
  )
}

class Player {
  constructor() {
    this.position = null
    this.level = null
    this.facing = LevelDirections.either
    this.health = 100
    this.lastMoved = 0
    this.carrying = []
    this.weapon = fists
  }
}

class Scene {
  constructor(book, url, onfinish) {
    this.completed = false
    this.book = book
    this.url = url
    this.sound = new Sound(this.url)
    this.sound.onended = () => {
      this.done()
    }
    this.onfinish = onfinish
  }

  done() {
    if (this.completed) {
      return
    }
    this.completed = true
    this.book.scene = null
    this.sound.source.disconnect()
    this.onfinish(this.book)
  }
}

class Hotkey {
  constructor(description, func) {
    // Pass description as either a string, or a function ready to take a Page instance as its only argument, and return a string.
    this.description = description
    this.func = func
  }
  
  getDescription(page) {
    if (typeof(this.description) == "function") {
      return this.description(page)
    }
    return this.description
  }
}

class Book{
  // Got the idea from the Navigator class in Flutter.

  constructor() {
    this.levelInPages = false
    this.scene = null
    this.message = null
    this.pages = []
    this.player = new Player()
    const activateString = "Activate a menu item"
    const cancelString = "Return to the previous menu"
    this.hotkeys = {
      "ArrowUp": new Hotkey(
        (page) => {
          if (page.isLevel) {
            return "Jump"
          }
          return "Move up in a menu"
        },
        () => this.moveUp()
      ),
      "ArrowDown": new Hotkey(
        "Move down in a menu",
        () => this.moveDown()
      ),
      " ": new Hotkey(
        (page) => {
          if (page.isLevel) {
            return "Use a weapon"
          }
          return activateString
        },
        () => this.shootOrActivate()
      ),
      "ArrowRight": new Hotkey(
        (page) => {
          if (page.isLevel) {
            return "Move right"
          }
          return activateString
        },
        () => this.moveOrActivate()
      ),
      "Enter": new Hotkey(
        (page) => {
          if (page.isLevel) {
            return "Take the object at your current location"
          }
          return activateString
        },
        () => this.takeOrActivate()
      ),
      "ArrowLeft": new Hotkey(
        (page) => {
          if (page.isLevel) {
            return "Move left"
          }
          return cancelString
        },
        () => this.cancel()
      ),
      "Escape": new Hotkey(
        "Return to the previous menu",
        () => this.cancel()
      ),
      "[": new Hotkey(
        "Decrease sound volume",
        () => this.volumeDown(gain)
      ),
      "]": new Hotkey(
        "Increase sound volume",
        () => this.volumeUp(gain)
      ),
      "-": new Hotkey(
        "Decrease music volume",
        () => this.volumeDown(musicGain)
      ),
      "=": new Hotkey(
        "Increase music volume",
        () => this.volumeUp(musicGain)
      ),
      "i": new Hotkey(
        "Inventory menu",
        () => this.inventory()
      ),
      "d": new Hotkey(
        "Drop menu",
        () => this.drop()
      ),
      "f": new Hotkey(
        "Show which way you are facing",
        () => this.showFacing()
      ),
      "c": new Hotkey(
        "Show your current coordinate",
        () => this.showPosition()
      ),
      "/": new Hotkey(
        "Show a list of hotkeys",
        () => {
          this.push(HotkeysPage(this))
        }
      ),
    }
    for (let i = 0; i < 10; i++) {
      this.hotkeys[i.toString()] = new Hotkey(
        `Use the weapon in slot ${i == 0 ? 10 : i}`,
        () => {
          this.selectWeapon(i)
        }
      )
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
    if (page.isLevel) {
      this.levelInPages = true
      this.game.stopMusic()
    } else {
      if (this.game.music === null && !this.levelInPages) {
        this.game.music = new Sound(this.game.musicUrl, true, musicGain)
        this.game.music.play(this.game.musicUrl)
      }
    }
    this.pages.push(page)
    this.showFocus()
  }

  pop() {
    const oldPage = this.pages.pop() // Remove the last page from the list.
    if (oldPage.isLevel) {
      this.levelInPages = false
    }
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
    if (page === null) {
      throw("First push a page.")
    } else if (page.focus == -1) {
      this.message(this.getText(page.title))
    } else if (!page.isLevel) {
      const line = page.getLine()
      this.game.moveSound.play(this.game.moveSoundUrl)
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
      this.showFocus()
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

  takeOrActivate() {
    const level = this.getPage()
    if (!level.isLevel) {
      return this.activate()
    }
    for (let content of level.contents) {
      if (content.position == this.player.position) {
        const obj = content.object
        if ([objectTypes.object, objectTypes.weapon].includes(obj.type)) {
          this.player.carrying.push(obj)
          obj.take.play(obj.takeUrl)
          content.destroy()
          this.message(`Taken: ${content.object.title}.`)
        } else if (obj.type == objectTypes.exit) {
          if (obj.targetLevel === null) {
            obj.cantUse.play(obj.cantUseUrl)
          } else {
            level.leave(this)
            this.playScene(obj.useUrl, (b) => {
              obj.targetLevel.play(b, obj.targetPosition)
            })
          }
        } else {
          this.message(`You cannot take ${obj.title}.`)
        }
        break // Take one object at a time.
      }
    }
  }

  moveOrActivate() {
    const page = this.getPage()
    if (page.isLevel) {
      page.right(this)
    } else {
      this.activate()
    }
  }

  activate() {
    const page = this.getPage()
    if (page === null) {
      return // Can"t do anything with no page.
    } else {
      const line = page.getLine()
      if (line === null) {
        return // They are probably looking at the title.
      }
      this.game.activateSound.play(this.game.activateSoundUrl)
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

  setVolume(v, output) {
    output.gain.value = v
    if (this.game.volumeSoundUrl !== null) {
      new Sound(this.game.volumeSoundUrl, false, output).play()
    }
    this.message(`${Math.round(output.gain.value * 100)}%.`)
  }

  volumeUp(output) {
    if (output === undefined) {
      output = gain
    }
    this.setVolume(Math.min(1.0, output.gain.value + this.game.volumeChangeAmount), output)
  }

  volumeDown(output) {
    if (output === undefined) {
      output = gain
    }
    this.setVolume(Math.max(0.0, output.gain.value - this.game.volumeChangeAmount), output)
  }

  inventory() {
    if (this.player.level === null) {
      return
    }
    if (this.player.carrying.length) {
      const lines = []
      for (let obj of this.player.carrying) {
        lines.push(
          new Line(
            obj.title, (b) => {
              obj.use(b)
              b.pop()
            }
          )
        )
      }
      this.push(
        new Page(
          {
            title: "Inventory",
            lines: lines
          }
        )
      )
    } else {
      this.message("You aren't carrying anything.")
    }
  }

  drop() {
    const level = this.player.level
    if (level === null) {
      return
    }
    if (this.player.carrying.length) {
      const lines = []
      for (let obj of this.player.carrying) {
        lines.push(
          new Line(
            obj.title, (b) => {
              b.pop()
              this.message(`Dropped: ${obj.title}.`)
              obj.drop(level, b.player.position)
            }
          )
        )
      }
      this.push(
        new Page(
          {
            title: "Choose something to drop",
            lines: lines
          }
        )
      )
    } else {
      this.message("You have nothing to drop.")
    }
  }

  showFacing() {
    const player = this.player
    if (player.level === null) {
      return
    }
    let direction = null
    if (player.facing == LevelDirections.backwards) {
      direction = "backwards"
    } else if (player.facing == LevelDirections.forwards) {
      direction = "forwards"
    } else if (player.facing == LevelDirections.either) {
      direction = "both ways at once"
    } else {
      direction = "the wrong way"
    }
    this.message(`You are facing ${direction}.`)
  }

  showPosition() {
    if (this.player.level === null) {
      return
    }
    this.message(`Position: ${this.player.position}.`)
  }

  onkeydown(e) {
    const key = e.key
    if (this.scene !== null) {
      if (e.key == "Enter") {
        this.scene.done()
      }
      return
    }
    const hotkey = this.hotkeys[key]
    if (hotkey !== undefined) {
      const func = hotkey.func
      e.preventDefault()
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
    const level = this.player.level
    this.player.position = position
    audio.listener.positionX.value = position / audioDivider
    for (let content of level.contents) {
      if (content.position == position) {
        level.trip.play(level.tripUrl)
        this.message(content.object.title)
      }
    }
  }

  selectWeapon(i) {
    const level = this.player.level
    if (level === null) {
      return
    }
    let index = Number(i, 0)
    if (i == 0) {
      index = 9
    } else {
      index -= 1
    }
    const weapons = [fists]
    for (let obj in this.player.carrying) {
      if (obj.type == objectTypes.weapon) {
        weapons.push(obj)
      }
    }
    const weapon = weapons[index]
    if (weapon === undefined) {
      level.noWeapon.play(level.noWeaponUrl)
    } else {
      this.player.weapon = weapon
      this.message(weapon.title)
    }
  }

  playScene(url, onfinish) {
    this.scene = new Scene(this, url, onfinish)
    this.scene.sound.play()
  }

  shootOrActivate() {
    const level = this.player.level
    if (level === null) {
      return this.activate()
    }
    const weapon = this.player.weapon
    const content = level.nearestObject(this.player.position, this.player.facing)
    if (content !== null) {
      const obj = content.object
      const distance = distanceBetween(content.position, this.player.position)
      if (distance <= weapon.range) {
        weapon.use.play(weapon.useUrl)
        content.hit.play(obj.hitUrl)
        content.health -= randint(0, weapon.damage)
        if (content.health < 0) {
          content.die()
        }
      }
    }
  }
}

this.Book = Book
