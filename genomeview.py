from pyvis.network import Network
import webbrowser
import argparse
import json
from typing import List

def view(genome: List[dict], inodes = [], onodes = [], bnodes = []):
    net = Network()
    oid = [f'o{x}' for x in range(len(onodes))]
    iid = [f'i{x}' for x in range(len(inodes))]
    bid = [f'n{x}' for x in range(len(bnodes))]
    aid=  oid + iid + bid
    net.add_nodes(iid, label=inodes)
    net.add_nodes(oid, label=onodes)
    net.add_nodes(bid, label=bnodes)

    for x in genome:
        src = ('i' if x["fI"] else 'n')+str(x["nIi"])
        if src not in aid:
            continue
        to =  ('o' if x["tO"] else 'n')+str(x["nIo"])
        if to not in aid:
            continue
        net.add_edge(src, to, physics=True, width=1+abs(x["w"]*10+x["b"]), color='red' if x["w"] < 0.0 else 'green')

    net.show_buttons()

    f = open("genome.html", 'w')
    f.write(net.generate_html())
    f.close()

    webbrowser.open_new_tab("genome.html")

parser = argparse.ArgumentParser()
parser.add_argument("-x", "--index", help="Index to load from", type=int, default=0)
parser.add_argument("-g", "--generation", help="Generation to load creature from", type=int, default=-1)
parser.add_argument("-i", "--inodes", help="File with inode labels", default="labels/inodes.txt")
parser.add_argument("-o", "--onodes", help="File with onode labels", default="labels/onodes.txt")
parser.add_argument("file", help="File to read gnomes from", default="simdata.json", nargs="?")
args = parser.parse_args()

inodes = open(args.inodes).read().strip().splitlines()
onodes = open(args.onodes).read().strip().splitlines()

jdata = json.load(open(args.file))
d = jdata["selected"][args.generation][args.index]
bnodes = [f"N{x}" for x in range(d["neurons"])]
view(d["genome"], inodes, onodes, bnodes)