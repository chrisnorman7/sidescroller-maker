/* globals showMessage, Sound */

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

class Book{
  // Got the idea from the Navigator class in Flutter.

  constructor() {
    this.pages = []
  }

  push(page) {
    this.pages.push(page)
    showMessage(page.title)
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
    showMessage(line.title)
  }

  moveUp() {
    const page = this.getPage()
    if (page === null) {
      return // There's probably no pages.
    }
    const focus = this.getFocus()
    if (focus == -1) {
      return // Do nothing.
    }
    page.focus --
    if (page.focus == -1) {
      showMessage(page.title)
    } else {
      this.showFocus()
    }
  }

  moveDown() {
    const page = this.getPage()
    if (page === null) {
      return // There's probably no pages.
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
      return // Can't do anything with no page.
    }
    const line = page.getLine()
    if (line === null) {
      return // They are probably looking at the title.
    }
    page.activateSound.play()
    line.func(this)
  }

  cancel() {
    const page = this.getPage()
    if (page === null || !page.dismissible) {
      return null // No page, or the page can't be dismissed that easily.
    }
    this.pop()
  }
}

this.Book = Book
