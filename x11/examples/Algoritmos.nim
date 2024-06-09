
import ../x11/xlib
import ../x11/xutil
import ../x11/x
import ../x11/xi2
import ../x11/xinput2


import math

proc pixelX(x: int): int =
  const xCenter = 500
  var xPixel: int
  assert x >= -xCenter and x <= xCenter, "x excede los parámetros"
  xPixel = xCenter + x
  return xPixel

proc pixelY(y: int): int =
  const yCenter = 300
  var yPixel: int
  assert y >= -yCenter and y <= yCenter, "y excede los parámetros"
  yPixel = yCenter - y
  return yPixel

proc plotLine(x0: int, y0: int, x1: int, y1: int, display: PDisplay, window: Window, graphicsContext: GC) =
    var
        dx = abs(x1-x0)
        dy = -abs(y1-y0)
        err = dx+dy
        newx0 = x0
        newy0 = y0
        e2, sx, sy: int 
        
    
    if newx0 < x1:
        sx = 1
    else:
        sx = -1
    if newy0 < y1:
        sy = 1
    else:
        sy = -1

    while true:
        discard XDrawPoint(display, window, graphicsContext, cint(pixelX(newx0)), cint(pixelY(newy0)))
        e2 = 2*err
        if e2 >= dy:
            if newx0 == x1:
                return
            err += dy
            newx0 += sx

        if e2 <= dx:
            if newy0 == y1:
                return
            err += dx
            newy0 += sy

proc plotQuadBezierSeg(x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, display: PDisplay, window: Window, graphicsContext: GC) =
    var
        sx = x2 - x1
        sy = y2 - y1
        xy: int
        newx0 = x0
        newx2 = x2
        newy0 = y0
        newy2 = y2
        xx = x0 - x1
        yy = y0 - y1
        dx: float
        dy: float
        err: float
        cur = xx * sy - yy * sx
        newy1: bool

    assert xx * sx <= 0 and yy * sy <= 0, "sign of gradient must not change"
    
    if sx * sx + sy * sy > xx * xx + yy * yy:
        newx2 = x0
        newx0 = sx + x1
        newy2 = y0
        newy0 = sy + y1
        cur = cur*(-1)

    if cur != 0:
        xx += sx
        if newx0 < newx2:
            sx = 1
        else:
            sx = -1
        xx *= sx
        yy += sy
        if newy0 < newy2:
            sy = 1
        else:
            sy = -1
        yy *= sy
        xy = 2 * xx * yy
        xx *= xx
        yy *= yy
        if cur*sx*sy < 0:
            xx = (-1)*xx
            yy = (-1)*yy
            xy = (-1)*xy
            cur = (-1)*cur
        dx = 4.0 * sy.float * cur.float * (x1.float - newx0.float) + xx.float - xy.float
        dy = 4.0 * sx.float * cur.float * (newy0.float - y1.float) + yy.float - xy.float
        xx += xx
        yy += yy
        err = dx + dy + xy.float 
        while dy < 0 and dx > 0:
            discard XDrawPoint(display, window, graphicsContext, cint(pixelX(newx0)), cint(pixelY(newy0)))
            if newx0 == newx2 and newy0 == newy2:
                return
            if 2 * err < dx:
                newy1 = true
            else:
                newy1 = false
            if 2 * err > dy:
                newx0 += sx
                dx -= xy.float
                dy += yy.float
                err += dy
            if newy1:
                newy0 += sy
                dy -= xy.float
                dx += xx.float
                err += dx
    plotLine(newx0,newy0,newx2,newy2, display, window, graphicsContext)

proc plotQuadBezier*(x0: int, y0: int, x1: int, y1: int, x2: int, y2: int, display: PDisplay, window: Window, graphicsContext: GC) =
    var
        x = x0-x1
        y = y0-y1
        t = float(x0-2*x1+x2)
        r: float
        newx0 = x0 
        newx2 = x2 
        newy0 = y0 
        newy2 = y2
        newx1 = x1
        newy1 = y1

    if x*(newx2-x1) > 0:
        if y*(newy2-y1) > 0:
            if abs(float(newy0-2*y1+newy2)/t*x.float) > float(abs(y)):
                newx0 = x2
                newx2 = x+x1
                newy0 = newy2
                newy2 = y+y1
        t = (newx0.float-x1.float)/t #Pendiente que x0 tomar
        r = (1-t)*((1-t)*newy0.float+2.0*t*y1.float)+t*t*newy2.float;
        t = (newx0.float*newx2.float-x1.float*x1.float)*t/(newx0.float-x1.float)
        x = int(floor(t+0.5))
        y = int(floor(r+0.5))
        r = (y1.float-newy0.float)*(t-newx0.float)/(x1.float-newx0.float)+newy0.float
        plotQuadBezierSeg(newx0,newy0,x,int(floor(r+0.5)),x,y,display,window,graphicsContext)
        r = (y1.float-newy2.float)*(t-newx2.float)/(x1.float-newx2.float)+newy2.float
        newx1 = x
        newx0 = newx1
        newy0 = y
        newy1 = int(floor(r+0.5))
    if (newy0-newy1)*(newy2-newy1) > 0:
        t = newy0.float-2*newy1.float+newy2.float
        t = (newy0.float-newy1.float)/t
        r = (1-t)*((1-t)*newx0.float+2.0*t*newx1.float)+t*t*newx2.float
        t = (newy0.float*newy2.float-newy1.float*newy1.float)*t/(newy0.float-newy1.float)
        x = int(floor(r+0.5))
        y = int(floor(t+0.5))
        r = (newx1.float-newx0.float)*(t-newy0.float)/(newy1.float-newy0.float)+newx0.float
        plotQuadBezierSeg(newx0,newy0,int(floor(r+0.5)),y,x,y,display,window,graphicsContext)
        r = (newx1.float-newx2.float)*(t-newy2.float)/(newy1.float-newy2.float)+newx2.float
        newx0 = x
        newx1 = int(floor(r+0.5))
        newy1 = y
        newy0 = newy1
    plotQuadBezierSeg(newx0,newy0,newx1,newy1,newx2,newy2,display,window,graphicsContext)
