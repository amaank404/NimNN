import pygame
import json
import argparse
from typing import List
import hashlib

def colorise(genome: List[dict]):
    colors = hashlib.md5(str(genome).encode("ascii")).digest()[:3]
    r = int(300-((colors[0]+150)//1.6))
    g = int(300-((colors[1]+150)//1.6))
    b = int(300-((colors[2]+150)//1.6))

    # Dominate Colors
    if r > g and r > b:
        r = int((r + 255) / 2)
        g = int((g + 200) / 2)
        b = int((b + 200) / 2)
    if g > r and g > b:
        r = int((r + 200) / 2)
        g = int((g + 255) / 2)
        b = int((b + 200) / 2)
    if b > g and b > r:
        r = int((r + 200) / 2)
        g = int((g + 200) / 2)
        b = int((b + 255) / 2)
    return (r, g, b)

parser = argparse.ArgumentParser()
parser.add_argument("simdata", help="Simulation Data file")
parser.add_argument("-u", "--uncontrolled", action="store_true", help="If the simulation is to be carried out without "
                                                                      "inputs")
parser.add_argument("-i", "--iteration", help="Iteration to load (default: last,-1)", default=-1, type=int)
parser.add_argument("-f", "--fps", help="FPS (default: 30)", default=30, type=int)
args = parser.parse_args()

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)

pygame.init()
screensize = (0, 0)
window = pygame.display.set_mode(screensize)
screensize = min(window.get_rect().w, window.get_rect().h)
jsondata = json.load(open(args.simdata))
simdata = jsondata["simdata"][args.iteration]
selecteddata = jsondata["selected"][args.iteration]
AIMRECT = jsondata["metadata"]["aimrect"]
AIMRECT = pygame.Rect(AIMRECT[0], (AIMRECT[1][0]-AIMRECT[0][0]+1, AIMRECT[1][1]-AIMRECT[0][1]+1))
colors = [colorise(x) for x in selecteddata]
running = True
clock = pygame.time.Clock()
FPS = args.fps
print("LOADED")

subsurface = pygame.Surface((jsondata["metadata"]["psize"]+1, jsondata["metadata"]["psize"]+1))
simcont = False
current_frame = 0
msgfin = True

while running:
    for ev in pygame.event.get():
        if ev.type == pygame.QUIT:
            running = False
        if ev.type == pygame.KEYDOWN:
            if ev.key == pygame.K_RIGHT:
                simcont = True
        if ev.type == pygame.KEYUP:
            if ev.key == pygame.K_RIGHT:
                simcont = False
            if ev.key == pygame.K_DOWN:
                running = False
    clock.tick(FPS)
    if simcont or args.uncontrolled:
        subsurface.fill(WHITE)
        
        # Do Stuff
        if current_frame + 1 == len(simdata):
            if msgfin:
                print("FINISHED")
                msgfin = False
            if args.uncontrolled:
                running = False
            continue
        frame = simdata[current_frame]
        current_frame += 1

        pygame.draw.rect(subsurface, (200, 255, 200), AIMRECT)
        pixellock = pygame.PixelArray(subsurface)

        for i, x in enumerate(frame):
            pixellock[x["x"], x["y"]] = colors[i]

        del pixellock

        surftoblit = pygame.transform.scale(subsurface, (screensize, screensize))
        surftoblitrect = surftoblit.get_rect()
        surftoblitrect.center = window.get_rect().center
        window.blit(surftoblit, surftoblitrect)
        pygame.display.update()

pygame.quit()
