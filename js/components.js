const audioDivider = 10

const tts = window.speechSynthesis
let ttsVoice = null
let ttsRate =1

let audio = null
let gain = null
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
  gain.gain.value = 0.5
  gain.connect(audio.destination)
  const music = new Sound("res/music/start.wav")
  music.play()
  fists = new Object()
  fists.title = "Fists"
  fists.type = objectTypes.weapon
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
      const level = Level.fromJson(levelData, g)
      g.levels.push(level)
    }
    for (let obj of g.objects) {
      if (obj.targetLevelIndex !== null) {
        obj.targetLevel = g.levels[obj.targetLevelIndex]
      }
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
      data.objects.push(object.toJson(this))
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
      dieUrl: "The sound played when this object is killed or destroyed",
    }
    this.takeUrl = "res/take.wav"
    this.take = new Sound(this.takeUrl)
    this.soundUrl = "res/object.wav"
    this.dropUrl = "res/drop.wav"
    this.hitUrl = "res/hit.wav"
    this.useUrl = "res/weapons/punch.wav"
    this.use = new Sound(this.useUrl)
    this.dieUrl = "res/die.wav"
    this.numericProperties = {
      damage: "The amount of damage dealt by this weapon",
      range: "The range of this weapon",
      health: "The initial health of this object"
    }
    this.damage = 2
    this.range = 1
    this.health = 1
  }

  static fromJson(data) {
    const o = new this()
    o.title = data.title || o.title
    o.type = data.type || o.type
    o.targetLevelIndex = data.targetLevelIndex
    for (let d of [o.urls, o.numericProperties]) {
      for (let name in d) {
        o[name] = data[name] || o[name]
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
    if (this.dropUrl !== null) {
      content.drop.play(this.dropUrl)
    }
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
    if (obj.soundUrl !== null) {
      this.sound = new Sound(obj.soundUrl, true, this.panner)
      this.sound.play()
    }
    this.move(this.position)
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
    if (this.sound !== null) {
      this.panner.positionX.value = position / audioDivider
    }
  }

  die() {
    this.silence(false)
    const index = this.level.contents.indexOf(this)
    this.level.contents.splice(index, 1)
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

this.LevelObject = LevelObject

class Level {
  constructor() {
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
      musicUrl: "Background music to play throughout the level",
      ambienceUrl: "Background sound of the level",
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
    this.ambienceUrl = null
    this.ambience = new Sound(this.ambienceUrl, true)
    this.footstepUrl = "res/footsteps/stone.wav"
    this.footstep = new Sound(this.footstepUrl, false)
    this.wallUrl = "res/wall.wav"
    this.wall = new Sound(this.wallUrl, false)
    this.turnUrl = "res/turn.wav"
    this.turn = new Sound(this.turnUrl)
    this.tripUrl = "res/trip.wav"
    this.trip = new Sound(this.tripUrl)
    this.convolverUrl = null
    this.convolverVolume = 0.5
    this.convolver = null
    this.convolverGain = null
    this.noWeaponUrl = "res/noweapon.wav"
    this.noWeapon = new Sound(this.noWeaponUrl)
  }

  static fromJson(data, game) {
    const level = new this()
    level.title = data.title || level.title
    for (let d of [level.urls, level.numericProperties]) {
      for (let name in d) {
        level[name] = data[name] || level[name]
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
        if (this.wallUrl !== null) {
          this.wall.play(this.wallUrl)
        }
      } else {
        book.setPlayerPosition(position)
        if (direction != player.facing) {
          if (player.facing != LevelDirections.either && this.turnUrl !== null) {
            this.turn.play(this.turnUrl)
          }
          player.facing = direction
        }
        if (this.footstepUrl !== null) {
          this.footstep.play(this.footstepUrl)
        }
      }
    }
  }

  play(book) {
    book.push(this)
    book.player.level = this
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
    this.level = null
    this.facing = LevelDirections.either
    this.health = 100
    this.lastMoved = 0
    this.carrying = []
    this.weapon = fists
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
      " ": () => this.shootOrActivate(),
      "ArrowRight": () => this.moveOrActivate(),
      "Enter": () => this.takeOrActivate(),
      "ArrowLeft": () => this.cancel(),
      "Escape": () => this.cancel(),
      "[": () => this.volumeDown(),
      "]": () => this.volumeUp(),
      "i": () => this.inventory(),
      "d": () => this.drop(),
      "f": () => this.showFacing(),
      "p": () => this.showPosition(),
    }
    for (let i = 0; i < 10; i++) {
      this.hotkeys[i.toString()] = () => {
        this.selectWeapon(i)
      }
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
          if (obj.takeUrl !== null) {
            obj.take.play(obj.takeUrl)
          }
          content.destroy()
          this.message(`Taken: ${content.object.title}.`)
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
    const func = this.hotkeys[key]
    if (func !== undefined) {
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
        if (level.tripUrl !== null) {
          level.trip.play(level.tripUrl)
        }
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
      if (level.noWeaponUrl !== null) {
        level.noWeapon.play(level.noWeaponUrl)
      }
    } else {
      this.player.weapon = weapon
      this.message(weapon.title)
    }
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
        if (weapon.useUrl !== null) {
          weapon.use.play(weapon.useUrl)
        }
        if (obj.hitUrl !== null) {
          content.hit.play(obj.hitUrl)
        }
        content.health -= randint(0, weapon.damage)
        if (content.health < 0) {
          content.die()
        }
      }
    }
  }
}

this.Book = Book
