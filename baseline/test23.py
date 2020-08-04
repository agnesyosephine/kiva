# -*- coding: utf-8 -*-
"""
Created on Wed Apr 29 03:04:37 2020

@author: Faturochman Prana
"""

from munkres import Munkres, print_matrix
import csv
import numpy as np

'opening file from csv'
rawnode = 0
with open ('for pairing.csv') as rawdata :
    reader = csv.reader (rawdata, delimiter=",")
    rawcoor= []

    for row in reader :
        rawcoor_ = []
        rawnode = rawnode + 1
        for col in row :
            rawcoor_.append(int(col))
        rawcoor.append(rawcoor_)
    rawcarray=np.asarray(rawcoor)

'generate dummy for array'
distcomb = np.full((robotnode,podnode),0)
oridistcomb = np.full((robotnode,podnode),0)
podid = []
robotid = []

'generate dist manhatan'
podbatchdist = 5
dumycol = 0
dumyrow = 0
dumycom = 0
for rgreedy in range(rawnode):
    dumycom=dumycom+1
    rxcor = rawcarray[rgreedy,0]
    rycor = rawcarray[rgreedy,1]
    pxcor = rawcarray[rgreedy,6]
    pycor = rawcarray[rgreedy,7]
    sxcor = rawcarray[rgreedy,2]
    sycor = rawcarray[rgreedy,3]
    excor = rawcarray[rgreedy,4]
    eycor = rawcarray[rgreedy,5]
    robotid = np.append(robotid,rawcarray[rgreedy,9])
    podid = np.append(podid,rawcarray[rgreedy,10])

    if rawcarray[rgreedy,8]==0:
        uturndist = 0
    else:
        uturndist = 2*podbatchdist

    srxcor = abs(sxcor-rxcor)
    srycor = abs(sycor-rycor)
    esxcor = abs(excor-sxcor)
    esycor = abs(eycor-sycor)
    pexcor = abs(pxcor-excor)
    peycor = abs(pycor-eycor)

    distmanhatan = srxcor+srycor+esxcor+esycor+pexcor+peycor+uturndist
    
    if dumycom%podnode==1:
        dumyrow = dumyrow+1
        dumycol = 0
    else :
        dumycol = dumycol+1
    distcomb[dumyrow-1,dumycol]=distmanhatan
    oridistcomb[dumyrow-1,dumycol]=distmanhatan

podid = np.unique(podid)
robotid = np.unique(robotid)
'hungarian'
matrix = distcomb
indexes = Munkres().compute(matrix)
pairing = []
total = 0
dumyrowraw=0
for row, column in indexes:
    value = oridistcomb[row][column]
    total += value
    pair = [robotid[row],podid[column]]
    pairing = np.append(pairing,pair)
pairing = np.reshape(pairing, (-1,2))
print(f'total distance: ',{total})

return pairing





