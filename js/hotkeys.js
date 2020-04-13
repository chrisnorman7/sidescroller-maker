/* global book, volumeDown, volumeUp */

this.hotkeys = {
  "ArrowUp": () => book.moveUp(),
  "ArrowDown": () => book.moveDown(),
  " ": () => book.activate(),
  "ArrowRight": () => book.activate(),
  "Enter": () => book.activate(),
  "ArrowLeft": () => book.cancel(),
  "[": volumeDown,
  "]": volumeUp
}
