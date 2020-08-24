# -*- coding: utf-8 -*-
"""
Created on Sat Jul 11 16:15:43 2020

@author: Chaterine
"""

from munkres import Munkres, print_matrix
import numpy as np
import pandas as pd


matrix = [[28,39,41,0,0],
          [16,15,39,0,0],
          [29,30,54,0,0],
          [34,37,25,0,0],
          [48,33,9,0,0]]

df = pd.read_csv('test_munkres.csv', header=None)
ndarray = df.values
out = Munkres().compute(matrix)
total = 0
for i, j in out:
    total += matrix[i][j]
print(total)
