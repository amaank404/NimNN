# Package

version       = "1.0.0"
author        = "xcodz-dot"
description   = "Neural Networks from scratch"
license       = "MIT"
srcDir        = "src"
bin           = @["nnview", "nnsim"]


# Dependencies

requires "nim >= 1.6.0"
requires "argparse >= 3.0.0"
requires "progress >= 1.1.3"
requires "sdl2 >= 2.0.1"
requires "therapist >= 0.2"