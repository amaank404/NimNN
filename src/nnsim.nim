import nn
import math
import random
import os
import json
import argparse
import progress
import strutils
import therapist

randomize()

var
  ic = 5
  oc = 4
  nc = 4
  ccount = 100
  simcount = 150
  gsize = 10
  psize = 100
  mutation_rate = 0.1
  change_rate = 0.2
  progressBarWidth = 30
  aimrect = [[45, 45], [50, 50]]

type
  Creature = object
    x, y: int
    nn: Nn
  SimDataPart = object
    x: int
    y: int
  Point = array[2, float64]

proc distance(p: Point, q: Point): float64 =
  sqrt((p[0]-q[0])^2+(p[1]-q[1])^2)

proc `%`(c: SimDataPart): JsonNode =
  return %* {
    "x": c.x,
    "y": c.y,
  }

proc anyBool(bools: seq[bool]): bool =
  for x in bools:
    if x: return true
  return false

proc inRect(c: Creature, rect: array[2, array[2, int]]): bool =
  return (c.x in rect[0][0]..rect[1][0]) and (c.y in rect[0][1]..rect[1][1])

proc newCreature(nn: sink Nn): Creature =
  result.x = rand(0..<psize)
  result.y = rand(0..<psize)
  while result.inRect(aimrect):
    result.x = rand(0..<psize)
    result.y = rand(0..<psize)
  result.nn = nn

proc simulate(c: var Creature) =
  c.nn.inputs[0] = c.x / psize
  c.nn.inputs[1] = (psize - c.x) / psize
  c.nn.inputs[2] = c.y / psize
  c.nn.inputs[3] = (psize - c.y) / psize
  c.nn.inputs[4] = distance([(aimrect[0][0]+aimrect[1][0])/2, (aimrect[0][1]+aimrect[1][1])/2], [c.x.float64, c.y.float64]) / psize.toFloat
  c.nn.simulate()

  if c.nn.outputs[0] > -0.3 and c.x > 0:
    c.x -= 1
  if c.nn.outputs[1] > -0.3 and c.x < psize:
    c.x += 1
  if c.nn.outputs[2] > -0.3 and c.y > 0:
    c.y -= 1
  if c.nn.outputs[3] > -0.3 and c.y < psize:
    c.y += 1

proc main() =
  let spec = (
    generate: newCountArg(@["-g", "--generate"], help="Generate the creatures", multi=false),
    load: newFileArg(@["-l", "--load"], help="Load the initial creatures from a file (with extension)", defaultVal=""),
    output: newStringArg(@["-o", "--out"], help="Name of the output file (without extension) for storing Simulation Data", required=true),
    include_all: newCountArg(@["-i", "--include-all"], help="Include all additional simulation data such as intermediate creatures, position data at all points", multi=false),
    include_final: newCountArg(@["-f", "--include-final"], help="Include final simulation data, excluding intermediate (Reduces file size, memory consumption Significantly)", multi=false),
    count: newIntArg(@["-c", "--count"], help="Generation Count", defaultVal=1),
    ncount: newIntArg(@["-n", "--ncount"], help="Neurons Count", defaultVal=nc),
    genome_len: newIntArg(@["-b", "--genome-len"], help="Genome Length", defaultVal=gsize),
    psize: newIntArg(@["-p", "--psize"], help="Play area size", defaultVal=psize),
    scount: newIntArg(@["-s", "--scount"], help="Simulator cycles to do per generation", defaultVal=simcount),
    ccount: newIntArg(@["-q", "--ccount"], help="Creatures count", defaultVal=ccount),
    mutation_rate: newFloatArg(@["-m", "--mutation"], help="Mutation rate (should be between 0.0, 1.0 or undefined behaviour will occur)", defaultVal=mutation_rate),
    change_rate: newFloatArg(@["-x", "--change"], help="Change rate (should be between 0.0, 1.0 or undefined behaviour will occur)", defaultVal=change_rate),
    aimrect: newStringArg(@["-a", "--aimrect"], help="Aim Rectangle in format `x,y:x,y`", defaultVal="45,45:50,50"),
    help: newHelpArg(@["-h", "--help"], help="Show this help message")
  )
  spec.parseOrQuit(prolog="Neural Network Simulator / Trainer")
  if spec.generate.count == 0 and spec.load.value == "":
    raise UsageError.newException("Either --generate or --load options should be provided")
  if spec.include_all.count == 1 and spec.include_final.count == 1:
    raise UsageError.newException("--include-all and --include-final can not be used together")

  var simulatorCounts = spec.count.value
  nc = spec.ncount.value
  simcount = spec.scount.value
  ccount = spec.ccount.value
  gsize = spec.genome_len.value
  psize = spec.psize.value
  mutation_rate = spec.mutation_rate.value
  change_rate = spec.change_rate.value

  try:
    var newAimRect: array[2, array[2, int]]
    let t1 = spec.aimrect.value.split(':', 1)
    let p1 = t1[0].split(',', 1)
    let p2 = t1[1].split(',', 1)
    newAimRect[0][0] = p1[0].parseInt()
    newAimRect[0][1] = p1[1].parseInt()
    newAimRect[1][0] = p2[0].parseInt()
    newAimRect[1][1] = p2[1].parseInt()
    aimrect = newAimRect
  except ValueError:
    raise UsageError.newException("Please provide a valid aim rectangle, `$1` could not be parsed" % [spec.aimrect.value])

  var creatures: seq[Creature] = @[];

  if spec.generate.count == 1:
    echo "Generating Initial Creatures: ", ccount
    var bar = newProgressBar(total = ccount, width=progressBarWidth)
    bar.start()

    for _ in 1..ccount:
      var genome: seq[GenomePart]
      for _ in 1..gsize:
        genome.add randomGenomePart(ic, nc, oc)
      let nn = newNn(ic, oc, nc, genome)
      creatures.add(newCreature(nn))
      bar.increment()

    bar.finish()
  else:
    echo "Loading from file: ", spec.load.value
    let data = parseFile(spec.load.value)
    if data{"selected"}.getElems.len == 0:
      raise UsageError.newException("No selected creatures were found in provided file: $1" % [spec.load.value])

    var bar = newProgressBar(total=data["selected"][^1].getElems.len, width=progressBarWidth)
    bar.start()
    for x in data["selected"][^1].getElems():
      let nn = jsonToNn(x)
      bar.increment()
      creatures.add(newCreature(nn))
    bar.finish()

  # At this point, we are done with loading creatures
  # and now, we shall simulate them
  echo "Simulating ",spec.count.value," Generations"
  var bar = newProgressBar(total = simulatorCounts, width = progressBarWidth)
  bar.start()
  var allSimulationData: seq[seq[seq[SimDataPart]]] = @[];
  var allSelectedData: seq[seq[Nn]] = @[];
  for s in 1..simulatorCounts:
    var simulationData: seq[seq[SimDataPart]] = @[];
    for _ in 1..simcount:
      var sdata: seq[SimDataPart] = @[]
      for x in creatures.mitems:
        simulate(x)
        sdata.add SimDataPart(x:x.x, y:x.y)
      simulationData.add(sdata)
    if (s == simulatorCounts and spec.include_final.count == 1) or spec.include_all.count == 1:
      allSimulationData.add simulationData
    # Reproduction Stage

    # Check if any of the creatures managed to reach the green spot
    var skipRectCheck = false;
    var inRectCheckResults: seq[bool] = newSeqOfCap[bool](creatures.len())
    for x in creatures:
      inRectCheckResults.add inRect(x, aimrect)
    if not anyBool(inRectCheckResults):
      creatures.setLen(0)  # Clear the sequence
      for x in 0..<ceil(ccount/10).int:
        var genome: seq[GenomePart]
        for _ in 1..gsize:
          genome.add randomGenomePart(ic, nc, oc)
        let nn = newNn(ic, oc, nc, genome)
        creatures.add(newCreature(nn))
      skipRectCheck = true

    var nextNn: seq[Nn] = @[]
    while true:
      for x in creatures.mitems:
        if inRect(x, aimrect) or skipRectCheck:
          let newNn = reproduceNn(deepCopy(x.nn), mutation_rate, change_rate)
          nextNn.add newNn
          if nextNn.len == ccount:
            break
          
      if nextNn.len == ccount:
        break

    var nextCreatures: seq[Creature] = newSeqOfCap[Creature](ccount)
    for x in nextNn:
      nextCreatures.add newCreature(x)
    
    creatures.setLen(0)
    for x in nextCreatures:
      creatures.add(x)

    bar.increment()
    if s == simulatorCounts or spec.include_final.count == 0:
        allSelectedData.add nextNn

  bar.finish()
  var jsonobj = newJObject()
  jsonobj["selected"] = %*[]
  echo "Processing Json"
  for x in allSelectedData:
    jsonobj["selected"].add %x
  jsonobj["metadata"] = %*{
    "ccount": creatures.len,
    "simcount": simcount,
    "aimrect": aimrect,
    "psize": psize
  }
  if spec.include_all.count == 1 or spec.include_final.count == 1:
    jsonobj["simdata"] = %allSimulationData
  echo "Formatting Json"
  let jsonStr = $jsonobj
  echo "Writing to file"
  writeFile(spec.output.value & ".json", jsonStr)

when isMainModule:
  main()
