#!/usr/bin/env python3

import argparse
import math

parser = argparse.ArgumentParser(prog="negaigaeshi.py", description="calculate Negai-gaeishi results")
parser.add_argument('integers', metavar='G', type=int, nargs=5, help='Genho-before [K]aeshi-30 K-300 K-3000 K-30000')
args = parser.parse_args()
G = args.integers

I1 = sum(G[1:5]) - 33330
#F2 = round((sum(G[1:5])  / 33330 - 1) * 100, 1)
F2 = math.floor((sum(G[1:5])  / 33330 - 1) * 1000) / 10
I3 = G[0] + sum(G[1:5]) - 33330

print('願いがえし(%d+%d+%d+%d)=>+%d(%.1f%%) 元宝残高:%d=>%d' % (G[1], G[2], G[3], G[4], I1, F2, G[0], I3))

