import ../x11/xlib
import ../x11/xutil
import ../x11/x
import ../x11/xi2
import ../x11/xinput2

const
  windowWidth = 1000
  windowHeight = 600
  borderWidth = 5
  eventMask = ButtonPressMask or KeyPressMask or ExposureMask

var
  display: PDisplay
  window: Window
  deleteMessage: Atom
  graphicsContext: GC

proc init() =
  display = XOpenDisplay(nil)
  if display == nil:
    quit "Failed to open display"

  let
    screen = XDefaultScreen(display)
    rootWindow = XRootWindow(display, screen)
    foregroundColor = XBlackPixel(display, screen)
    backgroundColor = XWhitePixel(display, screen)

  window = XCreateSimpleWindow(display, rootWindow, -1, -1, windowWidth,
      windowHeight, borderWidth, foregroundColor, backgroundColor)

  discard XSetStandardProperties(display, window, "X11 Example", "window", 0,
      nil, 0, nil)

  discard XSelectInput(display, window, eventMask)
  discard XMapWindow(display, window)

  deleteMessage = XInternAtom(display, "WM_DELETE_WINDOW", false.XBool)
  discard XSetWMProtocols(display, window, deleteMessage.addr, 1)

  graphicsContext = XDefaultGC(display, screen)


proc drawWindow() =
  ## Set the line width to 5 pixels (change this value as needed)
  discard XSetLineAttributes(display, graphicsContext, 5, LineSolid, CapButt, JoinRound)

  ## Draw a curve (parabola)
  for x in 0..windowWidth:
    let y = x * x / 1000  # Adjust this formula to change the shape of the curve
    discard XDrawPoint(display, window, graphicsContext, cint(x), cint(y))


proc mainLoop() =
  ## Process events until the quit event is received
  var event: XEvent
  while true:
    discard XNextEvent(display, event.addr)
    case event.theType
    of Expose:
      drawWindow()
    of ClientMessage:
      if cast[Atom](event.xclient.data.l[0]) == deleteMessage:
        break
    of KeyPress:
      let key = XLookupKeysym(cast[PXKeyEvent](event.addr), 0)
      if key != 0:
        echo "Key ", key, " pressed"
    of ButtonPressMask:
      echo "Mouse button ", event.xbutton.button, " pressed at ",
          event.xbutton.x, ",", event.xbutton.y
    else:
      discard


proc main() =
  init()
  mainLoop()
  discard XDestroyWindow(display, window)
  discard XCloseDisplay(display)


main()
