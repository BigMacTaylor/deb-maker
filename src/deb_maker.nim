# ========================================================================================
#
#                                   Deb Maker
#                          version 1.0.0 by Mac_Taylor
#
# ========================================================================================

import nim2gtk/[gtk, glib, gdk, gobject, gio]
import std/os
import strutils
import osproc

proc onExtract(btn: Button, chooser: FileChooserButton) =
  let debFile = getFilename(chooser)
  if debFile == "":
    echo "error: no file selected"
    return

  if not debFile.endsWith(".deb"):
    echo "error: invalid file"
    return

  var newDeb = debFile
  removeSuffix(newDeb, ".deb")
  let cmd = "dpkg-deb -R " & debFile & " " & newDeb
  let status = execCmd(cmd)
  if status == 0:
    echo "success"
  else:
    echo "Command exited with status code: ", status

proc onCreate(btn: Button, chooser: FileChooserButton) =
  let dir = getFilename(chooser)
  if dir == "":
    echo "error: no directory selected"
    return

  os.setCurrentDir(dir)
  let status = execCmd("make-deb -c")
  if status == 0:
    echo "success"
  else:
    echo "Command exited with status code: ", status

proc passwordPromt(): string =
  let dialog = newDialog()
  dialog.title = "Enter Password"
  dialog.setModal(true)
  #setTransientFor(dialog, window)
  dialog.setPosition(WindowPosition.center)

  let contentArea = getContentArea(dialog)
  let grid = newGrid()
  grid.setRowSpacing(10)
  grid.setColumnSpacing(10)
  grid.setMargin(10)
  grid.halign = Align.center

  let label = newLabel("Password:")
  label.halign = Align.end
  grid.attach(label, 0, 0, 1, 1)

  let entry = newEntry()
  entry.visibility = false
  entry.activatesDefault = true
  grid.attach(entry, 1, 0, 1, 1)

  discard dialog.addButton("Cancel", ResponseType.cancel.ord)
  discard dialog.addButton("Enter", ResponseType.accept.ord)
  dialog.defaultResponse = ResponseType.accept.ord

  contentArea.add(grid)
  dialog.showAll()

  let response = dialog.run()

  let password =
    if ResponseType(response) == ResponseType.accept:
      entry.getText()
    else:
      ""

  dialog.destroy()

  return password

proc onMake(btn: Button, chooser: FileChooserButton) =
  let dir = getFilename(chooser)
  if dir == "":
    echo "error: no directory selected"
    return

  let password = passwordPromt()

  if password == "":
    return

  discard execCmd("sudo -k")
  os.setCurrentDir(dir)
  let cmd = "echo " & password & " | sudo -S make-deb " & dir
  let status = execCmd(cmd)
  if status == 0:
    echo "success"
  else:
    echo "Command exited with status: ", status

proc closeEvent(window: ApplicationWindow, event: Event, app: Application): bool =
  echo "quitting..."
  quit(app)

proc appStartup(app: Application) =
  echo "appStartup"

proc appActivate(app: Application) =
  let window = newApplicationWindow(app)
  window.title = "Deb Maker"
  window.defaultSize = (500, 400)

  let headerBar = newHeaderBar()
  headerBar.title = "Deb Maker"
  headerBar.showCloseButton = true
  headerBar.decorationLayout = ":close"

  let mainBox = newBox(Orientation.vertical)

  let grid = newGrid()
  grid.setRowSpacing(10)
  grid.setColumnSpacing(10)
  grid.setMargin(40)
  grid.halign = Align.center

  let extractLabel = newLabel("Extract Deb")
  let extractChooser = newFileChooserButton("Select File", FileChooserAction.open)
  let extractButton = newButton("Extract")
  grid.attach(extractLabel, 0, 0, 2, 1)
  grid.attach(extractChooser, 0, 1, 2, 1)
  grid.attach(extractButton, 2, 1, 1, 1)

  let space_1 = newLabel("")
  grid.attach(space_1, 0, 2, 1, 1)

  let createLabel = newLabel("Create template")
  let createChooser =
    newFileChooserButton("Select Directory", FileChooserAction.selectFolder)
  let createButton = newButton("Create")
  grid.attach(createLabel, 0, 3, 2, 1)
  grid.attach(createChooser, 0, 4, 2, 1)
  grid.attach(createButton, 2, 4, 1, 1)

  let space_2 = newLabel("")
  grid.attach(space_2, 0, 5, 1, 1)

  let makeLabel = newLabel("Make Deb")
  let makeChooser =
    newFileChooserButton("Select Directory", FileChooserAction.selectFolder)
  let makeButton = newButton("Make")
  grid.attach(makeLabel, 0, 6, 2, 1)
  grid.attach(makeChooser, 0, 7, 2, 1)
  grid.attach(makeButton, 2, 7, 1, 1)

  extractButton.connect("clicked", onExtract, extractChooser)
  createButton.connect("clicked", onCreate, createChooser)
  makeButton.connect("clicked", onMake, makeChooser)

  mainBox.add(grid)

  window.add(mainBox)
  window.setTitlebar(headerBar)
  window.connect("delete-event", closeEvent, app)

  window.showAll()

proc main() =
  let app = newApplication("org.gtk.deb_maker", {ApplicationFlag.nonUnique})
  connect(app, "startup", appStartup)
  connect(app, "activate", appActivate)
  discard app.run()

when isMainModule:
  main()
