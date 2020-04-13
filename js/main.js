/* globals Book, keyboardArea, mainDiv, Page, startAudio, startButton, startDiv */

const book = new Book()

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
      }
    )
  )
}

window.onload = () => {
  mainDiv.hidden = true
}

keyboardArea.onkeydown = (e) => {
  const key = e.key
  if (key == "ArrowUp") {
    book.moveUp()
  } else if (key == "ArrowDown") {
    book.moveDown()
  } else if ([" ", "ArrowRight", "Enter"].includes(key)) {
    book.activate()
  } else if (key == "ArrowLeft") {
    book.cancel()
  } else {
    return null
  }
  e.stopPropagation()
}
