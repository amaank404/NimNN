import sdl2

type SDLException = object of Exception

const
  screenHeight = 500
  screenWidth = 500
  scaleFactor = 3

var running = false

template sdlFailIf(cond: typed, reason: string) =
  if cond: raise SDLException.newException(
    reason & ", SDL error: " & $getError()
  )
    
proc main() =
  sdlFailIf(not init(INIT_VIDEO)): "Unable to initialize sdl2"

  let window = createWindow("NNView", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, screenWidth*scaleFactor, screenHeight*scaleFactor, SDL_WINDOW_SHOWN)
  sdlFailIf window.isNil: "Unable to create a window"
  defer: window.destroy()
  
  let renderer = window.createRenderer(-1, Renderer_Accelerated or Renderer_PresentVsync)
  sdlFailIf renderer.isNil: "Unable to create a rendered for window"
  defer: renderer.destroy()

  running = true

  renderer.setDrawColor(255, 255, 255)
  var event = defaultEvent
  while running:
    # Event Loop
    event = defaultEvent
    while pollEvent(event):
      case event.kind
      of QuitEvent:
        running = false
      else:
        discard
    renderer.clear()
    renderer.present()


when isMainModule:
  main()