#!/usr/bin/env python
# script to generate gaussian taps for various radii
# see http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/ for more info

row = [1]

for i in range(1,25):
    a = row + [0]
    b = [0] + row
    row = []
    for n in range(0,i):
        row.append(a[n] + b[n])

    taps = []
    rsum = 0
    count = 0
    for t in row:
        if t >= 2**(i-9):
            taps += [t]
            rsum += t

    taps = taps[len(taps)/2:]

    taps = [t*1.0/rsum for t in taps]

    # without using linear offsets
    # print [t*1.0/rsum for t in taps]

    # using linear offsets
    offsets = [0]
    weights = [taps[0]]

    taps = taps[1:]
    k = 1
    while len(taps) >= 2:
        a,b,taps = taps[0], taps[1], taps[2:]

        weights += [a + b]
        offsets += [(k*a + (k + 1)*b)/(a + b)]

        k += 2

    weights += [taps]

    print i, offsets, weights
