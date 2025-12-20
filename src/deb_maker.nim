# ========================================================================================
#
#                                   Deb Maker
#                          version 1.0.2 by Mac_Taylor
#
# ========================================================================================

import nim2gtk/[gtk, glib, gdk, gobject, gio]
import std/os
import strutils
import osproc

proc errorMsg(messageText: string) =
  let dialog = newDialog()
  dialog.title = "Error"
  dialog.setModal(true)
  dialog.defaultSize = (300, 100)
  dialog.setPosition(WindowPosition.center)

  let contentArea = getContentArea(dialog)

  let grid = newGrid()
  grid.setRowSpacing(10)
  grid.setColumnSpacing(10)
  grid.setMargin(10)
  grid.halign = Align.center

  let icon = newImageFromIconName("dialog-error", IconSize.dialog.ord)
  grid.attach(icon, 0, 0, 1, 1)

  let label = newLabel(messageText)
  label.setMargin(20)
  grid.attach(label, 1, 0, 1, 1)

  contentArea.add(grid)

  discard dialog.addButton("OK", 1)
  dialog.defaultResponse = 1

  dialog.showAll()
  discard dialog.run()
  dialog.destroy()

proc onExtract(btn: Button, chooser: FileChooserButton) =
  let debFile = getFilename(chooser)
  if debFile == "":
    errorMsg("No file selected.")
    return

  if not debFile.endsWith(".deb"):
    errorMsg("File selected is not Deb.")
    return

  var newDeb = debFile
  removeSuffix(newDeb, ".deb")
  let cmd = "dpkg-deb -R " & debFile & " " & newDeb
  let status = execCmd(cmd)
  if status == 0:
    echo "success"
  else:
    errorMsg("Command exited with status code: " & $status)

proc onCreate(btn: Button, chooser: FileChooserButton) =
  let dir = getFilename(chooser)
  if dir == "":
    errorMsg("No directory selected.")
    return

  os.setCurrentDir(dir)
  let status = execCmd("make-deb -c")
  if status == 0:
    echo "success"
  else:
    errorMsg("Command exited with status code: " & $status)

proc passwordPromt(): string =
  let dialog = newDialog()
  dialog.title = "Deb Maker"
  dialog.setModal(true)
  #dialog.setTransientFor(window)
  dialog.setPosition(WindowPosition.center)

  let contentArea = getContentArea(dialog)

  let grid = newGrid()
  grid.setRowSpacing(10)
  grid.setColumnSpacing(20)
  grid.setMargin(25)
  grid.halign = Align.center

  let icon = newImageFromIconName("dialog-password", IconSize.dialog.ord)
  grid.attach(icon, 0, 0, 1, 1)

  let text = newLabel("Enter password")
  text.halign = Align.start
  grid.attach(text, 1, 0, 1, 1)

  let label = newLabel("Password:")
  label.halign = Align.end
  grid.attach(label, 0, 1, 1, 1)

  let entry = newEntry()
  entry.visibility = false
  entry.activatesDefault = true
  grid.attach(entry, 1, 1, 1, 1)

  discard dialog.addButton("Cancel", ResponseType.cancel.ord)
  discard dialog.addButton("Enter", ResponseType.accept.ord)
  dialog.defaultResponse = ResponseType.accept.ord

  contentArea.add(grid)
  dialog.showAll()

  let response = dialog.run()

  if ResponseType(response) != ResponseType.accept:
    dialog.destroy()
    return

  let password = entry.getText()

  dialog.destroy()

  if password == "":
    errorMsg("Password empty.")

  return password

proc onMake(btn: Button, chooser: FileChooserButton) =
  let dir = getFilename(chooser)
  if dir == "":
    errorMsg("No directory selected.")
    return

  let password = passwordPromt()

  if password == "":
    return

  discard execCmd("sudo -k")
  os.setCurrentDir(dir)

  # Check if password is valid
  var cmd = "echo " & password & " | sudo -S -v"
  var status = execCmd(cmd)
  if status != 0:
    errorMsg("Invalid password.")
    return

  cmd = "echo " & password & " | sudo -S make-deb " & dir
  status = execCmd(cmd)
  if status == 0:
    echo "success"
  else:
    errorMsg(
      "Command exited with status code: " & $status &
        "\n \nDoes directory have a valid .deb structure?"
    )

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
