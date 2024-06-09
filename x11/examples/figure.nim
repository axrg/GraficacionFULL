import
  ../x11/xlib,
  ../x11//xutil,
  ../x11//x,
  std/math

const
  windowWidth = 1000
  windowHeight = 600
  borderWidth = 10
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

  window = XCreateSimpleWindow(display, rootWindow, -1, -1, windowWidth, windowHeight, borderWidth, foregroundColor, backgroundColor)
  discard XSetStandardProperties(display, window, "X11 Example", "window", 0, nil, 0, nil)
  discard XSelectInput(display, window, eventMask)
  discard XMapWindow(display, window)
  deleteMessage = XInternAtom(display, "WM_DELETE_WINDOW", false.XBool)
  discard XSetWMProtocols(display, window, deleteMessage.addr, 1)
  graphicsContext = XDefaultGC(display, screen)

proc pixelX(x: int): float =
  const xCenter = 500.0
  return xCenter + float(x)

proc pixelY(y: int): float =
  const yCenter = 300.0
  return yCenter - float(y)

proc drawLine3D(x0, y0, z0, x1, y1, z1: int) =
  discard XDrawLine(display, window, graphicsContext, cint(pixelX(x0)), cint(pixelY(y0)), cint(pixelX(x1)), cint(pixelY(y1)))

proc drawPyramid() =
  # Base
  drawLine3D(-100, -50, 0, 100, -50, 0)
  drawLine3D(-100, -50, 0, 0, 100, 0)
  drawLine3D(0, 100, 0, 100, -50, 0)

  # Lados
  drawLine3D(-100, -50, 0, 0, 0, 100)
  drawLine3D(100, -50, 0, 0, 0, 100)
  drawLine3D(-100, -50, 0, 100, -50, 0)

proc drawWindow() =
  # Líneas de referencia
  discard XDrawLine(display, window, graphicsContext, 500, 0, 500, 600)
  discard XDrawLine(display, window, graphicsContext, 0, 300, 1000, 300)

  drawPyramid()

proc mainLoop() =
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
      discard XDrawPoint(display, window, graphicsContext, event.xbutton.x, event.xbutton.y)
      echo "Mouse button ", event.xbutton.button, " pressed at ",
          event.xbutton.x, ",", event.xbutton.y
    else:
      discard

proc main*() =
  init()
  mainLoop()
  discard XDestroyWindow(display, window)
  discard XCloseDisplay(display)

main()
