#! /usr/bin/env -S python3 -u

import argparse
from fractions import Fraction
import random
import itertools
import multiprocessing
import pickle

import numpy as np
from mpmath import mp
import matplotlib.pyplot as plt

# We need to do this globally to support multiprocessing.
mp.prec = 150


def cordic_initial_radius(n: int) -> mp.mpf:
    pr = mp.mpf(1.0)
    q = mp.mpf(1.0)
    for k in range(n):
        pr *= (1.0 + q)
        q *= 0.25
    return 1.0 / mp.sqrt(pr)


def divide_by_shift(numerator: int, shift_bits: int) -> int:
    denominator = 1 << shift_bits
    f = Fraction(numerator, denominator)
    return round(f)


class CORDIC:
    def __init__(self, angle_denominator_bits: int, sincos_denominator_bits: int, num_stages: int):
        assert angle_denominator_bits >= 2
        self.sincos_denominator = 1 << sincos_denominator_bits
        self.angle_denominator = 1 << angle_denominator_bits
        self.half_angle = 1 << (angle_denominator_bits - 1)
        self.quarter_angle = 1 << (angle_denominator_bits - 2)
        self.delta_angles = []
        while len(self.delta_angles) != num_stages:
        #while True:
            k = len(self.delta_angles)
            delta_angle = int(mp.nint(mp.atan(mp.mpf(0.5) ** k) / (2.0 * mp.pi) * self.angle_denominator))
            #if delta_angle == 0:
            #   break
            self.delta_angles.append(delta_angle)
        self.initial_radius = int(mp.nint(cordic_initial_radius(len(self.delta_angles)) * self.sincos_denominator))
    def __call__(self, angle_int: int) -> tuple[int, int]:
        angle_int = (angle_int + self.half_angle) % self.angle_denominator - self.half_angle
        if angle_int >= 0:
            return self._eval(0, +self.initial_radius, angle_int - self.quarter_angle)
        else:
            return self._eval(0, -self.initial_radius, angle_int + self.quarter_angle)
    def _eval(self, x: int, y: int, angle_residue: int) -> tuple[int, int]:
        for (k, delta_angle) in enumerate(self.delta_angles):
            if angle_residue >= 0:
                (x, y) = (
                    divide_by_shift((x << k) - y, k),
                    divide_by_shift((y << k) + x, k)
                )
                angle_residue -= delta_angle
            else:
                (x, y) = (
                    divide_by_shift((x << k) + y, k),
                    divide_by_shift((y << k) - x, k)
                )
                angle_residue += delta_angle
        return (x, y)



#for abits in range(8, 65, 8):
#   for scbits in range(8,65, 8):
#       for num_steps in range(0, 81):
#           cordic = CORDIC(abits, scbits, num_steps)
#           c_errors = []
#           s_errors = []
#           random.seed(123)
#           for k in range(10000):
#               angle = mp.rand()
#               angle_int = int(mp.nint(angle * cordic.angle_denominator))
#               (x_int, y_int) =  cordic(angle_int)
#               x = mp.fraction(x_int, cordic.sincos_denominator)
#               y = mp.fraction(y_int, cordic.sincos_denominator)
#
#               c = mp.cos(angle * (2.0 * mp.pi))
#               s = mp.sin(angle * (2.0 * mp.pi))
#
#               c_errors.append(float(x - c))
#               s_errors.append(float(y - s))
#
#           c_errors = np.asarray(c_errors)
#           s_errors = np.asarray(s_errors)
#
#           sigma = np.concatenate((c_errors, s_errors)).std()
#           print(abits, scbits, num_steps, sigma)


def runner(angle_denominator_bits: int, sincos_denominator_bits: int, num_stages: int, test_angles) -> tuple[int, int, int, float]:
    c_errors = []
    s_errors = []
    cordic = CORDIC(angle_denominator_bits, sincos_denominator_bits, num_stages)
    for (angle, cosine, sine) in test_angles:
        angle_int = int(mp.nint(angle * cordic.angle_denominator))
        (x_int, y_int) =  cordic(angle_int)
        x = mp.fraction(x_int, cordic.sincos_denominator)
        y = mp.fraction(y_int, cordic.sincos_denominator)
        c_errors.append(x - cosine)
        s_errors.append(y - sine)

    error = np.std(c_errors + s_errors)

    return (angle_denominator_bits, sincos_denominator_bits, num_stages, error)


def main():

    parser = argparse.ArgumentParser()
    parser.add_argument("max_value", type=int)

    args = parser.parse_args()

    random.seed(123)
    test_angles = []
    while len(test_angles) != 10000:
        angle = mp.rand()
        angle_radians = angle * (2 * mp.pi)
        cosine = mp.cos(angle_radians)
        sine = mp.sin(angle_radians)
        test_angles.append((angle, cosine, sine))

    angle_denominator_bits_values = range(2, 1 + args.max_value)
    sincos_denominator_bits_values = range(0, 1 + args.max_value)
    num_stages_values = range(0, 1 + args.max_value)

    cases = list(itertools.product(angle_denominator_bits_values, sincos_denominator_bits_values, num_stages_values, [test_angles]))

    pool = multiprocessing.Pool()

    #results = itertools.starmap(runner, cases)
    results = pool.starmap(runner, cases)
    for (angle_denominator_bits, sincos_denominator_bits, num_stages, error) in results:
        print(angle_denominator_bits, sincos_denominator_bits, num_stages, error)


if __name__ == "__main__":
    main()
