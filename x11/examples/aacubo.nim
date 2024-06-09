import
  ../x11/xlib,
  ../x11/xutil,
  ../x11/x,
  std/math,
  ../x11/keysym

const
  pi = 3.141592653589793
  windowWidth = 1000
  windowHeight = 600
  borderWidth = 10
  eventMask = ButtonPressMask or KeyPressMask or ExposureMask

var
  display: PDisplay
  window: Window
  deleteMessage: Atom
  graphicsContext: GC

type
  Vec3 = tuple[x, y, z: float]
  Mat4 = array[4, array[4, float]]

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

proc rotationMatrix(angle: float, axis: Vec3): Mat4 =
  let
    c = cos(angle)
    s = sin(angle)
    t = 1 - c
    x = axis.x
    y = axis.y
    z = axis.z
  result = [[t*x*x + c, t*x*y - s*z, t*x*z + s*y, 0],
            [t*x*y + s*z, t*y*y + c, t*y*z - s*x, 0],
            [t*x*z - s*y, t*y*z + s*x, t*z*z + c, 0],
            [0, 0, 0, 1]]

proc matMulVec(m: Mat4, v: Vec3): Vec3 =
  result = (
    x: m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z + m[0][3],
    y: m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z + m[1][3],
    z: m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z + m[2][3]
  )

proc project(v: Vec3): (cint, cint) =
  let d = 4.0
  result = (
    cint((v.x / (d - v.z) + 0.5) * windowWidth),
    cint((0.5 - v.y / (d - v.z)) * windowHeight)
  )

var
  vertices = [
    (x: -1.0, y: -1.0, z: -1.0),
    (x:  1.0, y: -1.0, z: -1.0),
    (x:  1.0, y:  1.0, z: -1.0),
    (x: -1.0, y:  1.0, z: -1.0),
    (x: -1.0, y: -1.0, z:  1.0),
    (x:  1.0, y: -1.0, z:  1.0),
    (x:  1.0, y:  1.0, z:  1.0),
    (x: -1.0, y:  1.0, z:  1.0)
  ]
  
  edges = [
    (0, 1), (1, 2), (2, 3), (3, 0),
    (4, 5), (5, 6), (6, 7), (7, 4),
    (0, 4), (1, 5), (2, 6), (3, 7)
  ]
  
  angleX = 0.0
  angleY = 0.0

proc drawCube() =
  let
    rotationX = rotationMatrix(angleX, (x: 1.0, y: 0.0, z: 0.0))
    rotationY = rotationMatrix(angleY, (x: 0.0, y: 1.0, z: 0.0))
  
  for (i, j) in edges:
    let
      v1 = matMulVec(rotationX, matMulVec(rotationY, vertices[i]))
      v2 = matMulVec(rotationX, matMulVec(rotationY, vertices[j]))
      (x1, y1) = project(v1)
      (x2, y2) = project(v2)
    discard XDrawLine(display, window, graphicsContext, x1, y1, x2, y2)

proc handleKeyPress(key: KeySym) =
  case key
  of XK_Left:
    angleY -= 0.1
  of XK_Right:
    angleY += 0.1
  of XK_Up:
    angleX -= 0.1
  of XK_Down:
    angleX += 0.1
  else:
    discard

proc mainLoop() =
  var event: XEvent
  while true:
    discard XNextEvent(display, event.addr)
    case event.theType
    of Expose:
      discard XClearWindow(display, window)
      drawCube()
    of ClientMessage:
      if cast[Atom](event.xclient.data.l[0]) == deleteMessage:
        break
    of KeyPress:
      let key = XLookupKeysym(cast[PXKeyEvent](event.addr), 0)
      handleKeyPress(key)
      discard XClearWindow(display, window)
      drawCube()
    else:
      discard

proc main*() =
  init()
  mainLoop()
  discard XDestroyWindow(display, window)
  discard XCloseDisplay(display)

main()