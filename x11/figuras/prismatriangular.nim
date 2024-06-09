# Importa módulos necesarios de X11 y otros módulos estándar
import
  ../x11/xlib,
  ../x11/xutil,
  ../x11/x,
  std/math,
  ../x11/keysym

# Define constantes globales
const
  pi = 3.141592653589793           # Valor de pi
  windowWidth = 1000               # Ancho de la ventana
  windowHeight = 600               # Altura de la ventana
  borderWidth = 10                 # Ancho del borde de la ventana
  eventMask = ButtonPressMask or KeyPressMask or ExposureMask  # Máscara de eventos

# Define variables globales
var
  display: PDisplay                # Puntero al display de X11
  window: Window                   # Identificador de la ventana de X11
  deleteMessage: Atom              # Mensaje de eliminación de ventana
  graphicsContext: GC              # Contexto gráfico

# Define tipos personalizados
type
  Vec3 = tuple[x, y, z: float]     # Vector 3D
  Mat4 = array[4, array[4, float]] # Matriz 4x4

# Procedimiento para inicializar la ventana de X11
proc init() =
  display = XOpenDisplay(nil)      # Abre la conexión al display de X11
  if display == nil:
    quit "Failed to open display"  # Si falla, termina el programa

  let
    screen = XDefaultScreen(display)                     # Obtiene la pantalla por defecto
    rootWindow = XRootWindow(display, screen)            # Obtiene la ventana raíz
    foregroundColor = XBlackPixel(display, screen)       # Color de primer plano (negro)
    backgroundColor = XWhitePixel(display, screen)       # Color de fondo (blanco)

  window = XCreateSimpleWindow(display, rootWindow, -1, -1, windowWidth, windowHeight, borderWidth, foregroundColor, backgroundColor)
  discard XSetStandardProperties(display, window, "X11 Example", "window", 0, nil, 0, nil)  # Establece propiedades estándar de la ventana
  discard XSelectInput(display, window, eventMask)       # Selecciona los eventos a escuchar
  discard XMapWindow(display, window)                    # Mapea la ventana para que sea visible
  deleteMessage = XInternAtom(display, "WM_DELETE_WINDOW", false.XBool)  # Define el mensaje de eliminación de ventana
  discard XSetWMProtocols(display, window, deleteMessage.addr, 1)  # Establece el protocolo de manejo de mensajes
  graphicsContext = XDefaultGC(display, screen)          # Obtiene el contexto gráfico por defecto

# Procedimiento para crear una matriz de rotación
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

# Procedimiento para multiplicar una matriz por un vector
proc matMulVec(m: Mat4, v: Vec3): Vec3 =
  result = (
    x: m[0][0] * v.x + m[0][1] * v.y + m[0][2] * v.z + m[0][3],
    y: m[1][0] * v.x + m[1][1] * v.y + m[1][2] * v.z + m[1][3],
    z: m[2][0] * v.x + m[2][1] * v.y + m[2][2] * v.z + m[2][3]
  )

# Procedimiento para proyectar un vector 3D en coordenadas de pantalla
proc project(v: Vec3): (cint, cint) =
  let d = 4.0
  result = (
    cint((v.x / (d - v.z) + 0.5) * windowWidth),
    cint((0.5 - v.y / (d - v.z)) * windowHeight)
  )

# Define los vértices y aristas del prisma triangular, se definen las coordenadas de los vertices
var
  vertices = [
    (x: -1.0, y: -1.0, z: -1.0),
    (x:  1.0, y: -1.0, z: -1.0),
    (x:  0.0, y:  1.0, z: -1.0),
    (x: -1.0, y: -1.0, z:  1.0),
    (x:  1.0, y: -1.0, z:  1.0),
    (x:  0.0, y:  1.0, z:  1.0)
  ]
  
  edges = [
    (0, 1), (1, 2), (2, 0),  # Base inferior
    (3, 4), (4, 5), (5, 3),  # Base superior
    (0, 3), (1, 4), (2, 5)   # Aristas verticales
  ]
  
  angleX = 0.0                     # Ángulo de rotación en X
  angleY = 0.0                     # Ángulo de rotación en Y
  translateX = 0.0                 # Translación en X
  translateY = 0.0                 # Translación en Y

# Procedimiento para dibujar el prisma triangular
proc drawPrisma() =
  let
    rotationX = rotationMatrix(angleX, (x: 1.0, y: 0.0, z: 0.0))  # Matriz de rotación en X
    rotationY = rotationMatrix(angleY, (x: 0.0, y: 1.0, z: 0.0))  # Matriz de rotación en Y
  
  for (i, j) in edges:
    var
      v1 = matMulVec(rotationX, matMulVec(rotationY, vertices[i]))
      v2 = matMulVec(rotationX, matMulVec(rotationY, vertices[j]))
    # Aplicar translación
    v1 = (x: v1.x + translateX, y: v1.y + translateY, z: v1.z)
    v2 = (x: v2.x + translateX, y: v2.y + translateY, z: v2.z)
    let
      (x1, y1) = project(v1)
      (x2, y2) = project(v2)
    discard XDrawLine(display, window, graphicsContext, x1, y1, x2, y2)  # Dibuja una línea entre dos vértices

# Procedimiento para manejar eventos de teclas
proc handleKeyPress(key: KeySym) =
  case key
  of XK_Left:
    angleY -= 0.1                 # Rotar en sentido antihorario en Y
  of XK_Right:
    angleY += 0.1                 # Rotar en sentido horario en Y
  of XK_Up:
    angleX -= 0.1                 # Rotar en sentido antihorario en X
  of XK_Down:
    angleX += 0.1                 # Rotar en sentido horario en X
  of XK_w:
    translateY += 0.1             # Mover hacia arriba
  of XK_s:
    translateY -= 0.1             # Mover hacia abajo
  of XK_a:
    translateX -= 0.1             # Mover hacia la izquierda
  of XK_d:
    translateX += 0.1             # Mover hacia la derecha
  else:
    discard

# Procedimiento principal del bucle de eventos
proc mainLoop() =
  var event: XEvent
  while true:
    discard XNextEvent(display, event.addr)
    case event.theType
    of Expose:
      discard XClearWindow(display, window)
      drawPrisma()                # Redibujar el prisma cuando la ventana se expone
    of ClientMessage:
      if cast[Atom](event.xclient.data.l[0]) == deleteMessage:
        break                      # Salir del bucle si se recibe un mensaje de eliminación
    of KeyPress:
      let key = XLookupKeysym(cast[PXKeyEvent](event.addr), 0)
      handleKeyPress(key)         # Manejar una pulsación de teclas
      discard XClearWindow(display, window)
      drawPrisma()                # Redibujar el prisma después de manejar una tecla
    else:
      discard

# Procedimiento principal del programa
proc main*() =
  init()                          # Inicializar la ventana y demás componentes
  mainLoop()                      # Iniciar el bucle de eventos
  discard XDestroyWindow(display, window)  # Destruir la ventana al finalizar
  discard XCloseDisplay(display)           # Cerrar la conexión con el display

main()  # Ejecutar el procedimiento principal
