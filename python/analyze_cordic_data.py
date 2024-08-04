#! /usr/bin/env python3

import numpy as np
import matplotlib.pyplot as plt

filename = "100.txt"

cordic_data_dtype = np.dtype([
        ("angle_denominator_bits"  , np.int32),
        ("sincos_denominator_bits" , np.int32),
        ("num_stages"              , np.int32),
        ("error"                   , np.float64)
    ])

data = np.loadtxt(filename, cordic_data_dtype)

if True:

    angle_denominator_bits = 32

    selection = data["angle_denominator_bits"] == angle_denominator_bits
    selected_data = data[selection]

    smin = selected_data["sincos_denominator_bits"].min()
    smax = selected_data["sincos_denominator_bits"].max()

    amin = selected_data["angle_denominator_bits"].min()
    amax = selected_data["angle_denominator_bits"].max()

    nmin = selected_data["num_stages"].min()
    nmax = selected_data["num_stages"].max()

    #assert amin == 2
    #assert smin == 0
    #assert nmin == 0

    err = np.full((smax + 1, nmax + 1), fill_value=np.nan)
    for (a, s, n, e) in selected_data:
        if (25 <= s <= 45) and (25 <= n <= 45):
            err[s, n] = e

    plt.imshow(np.log2(err), origin = 'lower', cmap='viridis')
    plt.title("log2(sin_cos_error_1_sigma) for {}-bits angles".format(angle_denominator_bits))
    plt.xlabel("number of stages")
    plt.ylabel("number of sin/cos bits")
    plt.colorbar()
    plt.xlim(24.5, 45.5)
    plt.ylim(24.5, 45.5)
    plt.show()

if False:

    best = {}
    for (a, s, n, e) in data:
        if (a, s) not in best:
            best[(a, s)] = (e, n)
        else:
            if (e, n) < best[(a, s)]:
                best[(a, s)] = (e, n)

    #print(best)

    #best_e = np.full((101, 101), fill_value=np.nan)
    #best_n = np.full((101, 101), fill_value=np.nan)

    #for (k, v) in best.items():
    #    (a, s) = k
    #    (e, n) = v
    #    best_e[a, s] = e
    #    best_n[a, s] = n

    #plt.subplot(2,1,1)
    #plt.imshow(best_n, origin = 'lower', cmap='viridis')
    #plt.subplot(2,1,2)
    #plt.imshow(np.log2(best_e), origin = 'lower', cmap='viridis')
    #plt.show()
