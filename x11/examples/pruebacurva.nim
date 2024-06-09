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

# Define los límites de la curva
var minX, maxX, minY, maxY: int

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

proc calculateCurveLimits() =
  var minXf, maxXf, minYf, maxYf: float  # Define variables flotantes para los límites de la curva
  minXf = float(minX)  # Convierte minX a float
  maxXf = float(maxX)  # Convierte maxX a float
  minYf = float(minY)  # Convierte minY a float
  maxYf = float(maxY)  # Convierte maxY a float

  for u in 0..windowWidth:
    var x =  u * u * 4 / 1  # Ajusta esta fórmula para cambiar la forma de la curva
    var y =  u / 2 
    if x < minXf: minXf = x
    if x > maxXf: maxXf = x
    if y < minYf: minYf = y
    if y > maxYf: maxYf = y

  # Convierte los límites de la curva de nuevo a enteros para utilizarlos en el dibujo
  minX = int(minXf)
  maxX = int(maxXf)
  minY = int(minYf)
  maxY = int(maxYf)

proc drawWindow() =
  calculateCurveLimits()

  ## Dibuja los ejes utilizando los límites de la curva
  discard XSetLineAttributes(display, graphicsContext, 1, LineSolid, CapButt, JoinRound)
  discard XSetForeground(display, graphicsContext, 0x00000000)  # Negro en formato RGB
  discard XDrawLine(display, window, graphicsContext, cint(float(minX)), cint(maxY), cint(maxX), cint(maxY))  # Eje x
  discard XDrawLine(display, window, graphicsContext, cint(float(minX)), cint(minY), cint(float(minX)), cint(maxY))  # Eje y

  ## Dibujar la curva (parábola)
  discard XSetForeground(display, graphicsContext, 0x00FF0000)  # Rojo en formato RGB
  for u in 0..windowWidth:
    var x =  u * u * 4 / 4000  # Ajusta esta fórmula para cambiar la forma de la curva
    var y =  u / 10 
    discard XDrawPoint(display, window, graphicsContext, cint(x), cint(y))

proc mainLoop() =
  ## Procesar eventos hasta que se reciba el evento de salida
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
        echo "Tecla ", key, " presionada"
    of ButtonPressMask:
      echo "Botón del mouse ", event.xbutton.button, " presionado en ",
          event.xbutton.x, ",", event.xbutton.y
    else:
      discard


proc main() =
  init()
  mainLoop()
  discard XDestroyWindow(display, window)
  discard XCloseDisplay(display)


main()
