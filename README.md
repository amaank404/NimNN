# NimNN
Nim Neural Networks (genetic). This is a simple program
written without any prior knowledge about neural network
algorithms. This is a command line program and `nnsim.exe --help`
should give out to you all available options for you to
choose from.

## Demo
I have a demo for the same available at my webpage. Click
[here](https://xcodz-dot.github.io/), A video shall be presented
to you under My Projects section.

## Build
you can build the latest release by cloning this repository
and you need choosenim installation (`nim`, `nimble`)

```bash
nimble -d:release build nnsim  # Using release significantly boosts performance
nnsim --help
```

For even faster builds. You can try this:

```bash
nimble -d:release --mm:orc --deepcopy:on build nnsim  # 2x better performance.
nnsim --help
```

If you want, you can try compiling it with danger mode and it should
run fine and faster. But unexpected things can happen on unexpected command line
arguments. Doing so is thus not recommended.

## Download (Without build)
If you do not want to compile this package, release builds
are already provided [here](https://github.com/xcodz-dot/NimNN/releases).

## Scripts
There are a few scripts written in python from my old Neural Network
project that was written in python. Those scripts have been modified
now to work with this program's output `simdata.json`. 

### `view.py`
You can view simulation in real time if you had saved the data with
`-f` or `-i` while simulating. use `python view.py --help` for usage
information

### `genomeview.py`
You can view the brain of a neural network using this script, do
note that using this requires you to have the 
[`/labels`](https://github.com/xcodz-dot/NimNN/tree/master/labels) 
downloaded. use `python genomeview.py --help` for more information.
