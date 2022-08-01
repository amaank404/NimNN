import math
import random
import macros
import json

randomize()

macro initZero(s) =
  quote do:
    for x in 0..<`s`.len: `s`[x] = 0.0
macro initZeroInt(s) =
  quote do:
    for x in 0..<`s`.len: `s`[x] = 0

type
  GenomePart* = object
    fromInput: bool
    toOutput: bool
    neuronIdIn: int
    neuronIdOut: int
    weight: float64
    bias: float64
  Nn* = object
    inputs*, outputs*, neurons*, neurons_new, outputs_new: seq[float64]
    genome*: seq[GenomePart]
    neurons_new_c: seq[int]
    outputs_new_c: seq[int]

proc newNn*(inputs: int, outputs: int, neurons: int, genome: sink seq[GenomePart]): Nn =
  result.inputs = newSeqOfCap[float64](inputs)
  result.outputs = newSeqOfCap[float64](outputs)
  result.neurons = newSeqOfCap[float64](neurons)
  result.neurons_new = newSeqOfCap[float64](neurons)
  result.neurons_new_c = newSeqOfCap[int](neurons)
  result.outputs_new = newSeqOfCap[float64](outputs)
  result.outputs_new_c = newSeqOfCap[int](outputs)
  result.genome = genome
  for _ in 0..<inputs: result.inputs.add 0.0
  for _ in 0..<outputs: result.outputs.add 0.0
  for _ in 0..<neurons: result.neurons.add 0.0
  for _ in 0..<neurons: result.neurons_new.add 0.0
  for _ in 0..<outputs: result.outputs_new.add 0.0
  for _ in 0..<neurons: result.neurons_new_c.add 0
  for _ in 0..<outputs: result.outputs_new_c.add 0

proc simulate*(nn: var Nn) =
  initZero(nn.neurons_new)
  initZero(nn.outputs_new)
  initZeroInt(nn.neurons_new_c)
  initZeroInt(nn.outputs_new_c)
  for x in nn.genome:
    try:
      var oval, ival: float64
      if x.fromInput:
        ival = nn.inputs[x.neuronIdIn]
      else:
        ival = nn.neurons[x.neuronIdIn]
      oval = tanh(ival*x.weight + x.bias)

      if x.toOutput:
        nn.outputs_new[x.neuronIdOut] += oval
        nn.outputs_new_c[x.neuronIdOut].inc()
      else:
        nn.neurons_new[x.neuronIdOut] += oval
        nn.neurons_new_c[x.neuronIdOut].inc()
      for i, v in nn.neurons_new:
        if nn.neurons_new_c[i] == 0: continue
        nn.neurons[i] = v/nn.neurons_new_c[i].float64
      for i, v in nn.outputs_new:
        if nn.outputs_new_c[i] == 0: continue
        nn.outputs[i] = v/nn.outputs_new_c[i].float64
    except IndexDefect:
      discard

proc randomGenomePart*(ic, nc, oc: int): GenomePart =
  result.fromInput = rand(1) == 1
  result.toOutput = rand(1) == 1
  if result.fromInput:
    result.neuronIdIn = rand(0..<ic)
  else:
    result.neuronIdIn = rand(0..<nc)

  if result.toOutput:
    result.neuronIdOut = rand(0..<oc)
  else:
    result.neuronIdOut = rand(0..<nc)

  result.weight = rand(-2.0..2.0)
  result.bias = rand(-1.0..1.0)



proc `%`*(g: seq[GenomePart]): JsonNode =
  var j: JsonNode = %*[]
  for x in g:
    var node = %*
      {
        "fI": x.fromInput,
        "tO": x.toOutput,
        "nIi": x.neuronIdIn,
        "nIo": x.neuronIdOut,
        "w": x.weight,
        "b": x.bias
      }
    j.add(node)
  return j

proc jsonToGenome*(j: JsonNode): seq[GenomePart] =
  for x in j.getElems():
    let genomePart = GenomePart(
      fromInput: x["fI"].getBool(),
      toOutput: x["tO"].getBool(),
      neuronIdIn: x["nIi"].getInt(),
      neuronIdOut: x["nIo"].getInt(),
      weight: x["w"].getFloat(),
      bias: x["b"].getFloat()
    )
    result.add genomePart

proc `%`*(nn: Nn): JsonNode =
  return %*{
    "inputs": nn.inputs.len,
    "outputs": nn.outputs.len,
    "neurons": nn.neurons.len,
    "genome": %nn.genome
  }

proc jsonToNn*(j: JsonNode): Nn =
  return newNn(j["inputs"].getInt(), j["outputs"].getInt(), j["neurons"].getInt(), jsonToGenome(j["genome"]))

## Reproduce the Neural Network with default mutation
## rate at 5% (0.05) and default change rate at 40% (0.4)
proc reproduceNn*(nn: sink Nn, mutation: float64 = 0.05, change_rate: float64 = 0.4): Nn =
  if rand(0.0..1.0) <= mutation:
    for _ in 0..<(change_rate*nn.genome.len.float64).int64:
      nn.genome[rand(0..<nn.genome.len)] = randomGenomePart(nn.inputs.len, nn.neurons.len, nn.outputs.len)
  return nn