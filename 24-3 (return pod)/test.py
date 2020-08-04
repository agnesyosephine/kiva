# -*- coding: utf-8 -*-

def takeSecond(elem):
    return elem[2]

def balancing(matrix):
    row = len(matrix)
    column = len(matrix[0])
    dummy = []
    for i in range (column):
        dummy.append(9999)
    for i in range(row):
        dummy.append
    if row > column:
        pivotMax = row
        pivotMin = column
    else:
        pivotMax = column
        pivotMin = row
    # i = pivotMin -1
    # for i in range(pivotMin,pivotMax):
    #     matrix = np.vstack((matrix, dummy))
    for i in range(pivotMin,pivotMax):
        matrix = np.vstack((matrix,dummy))
    return matrix
           
def manhatanDistance(xStart, yStart, xEnd, yEnd):
    return( abs(xStart - xEnd)+ abs(yStart - yEnd))
    
"""
Created on Tue Apr 28 17:32:47 2020

@author: Faturochman Prana
"""

from munkres import Munkres, print_matrix
import csv
import numpy as np
import pandas as pd

'opening file from csv'
rawnode = 0 
robotnode = 5
podnode = 83

with open ('for pairing.csv') as rawdata :
    reader = csv.reader (rawdata, delimiter=",")
    rawcoor= []

    for row in reader :
        rawcoor_ = []
        rawnode = rawnode + 1
        for col in row :
            rawcoor_.append(int(col))
        rawcoor.append(rawcoor_)
    rawcarray= pd.DataFrame(rawcoor,
                             columns=['robotxcor','robotycor', 'xstart', 
                                      'ystart','xend','yend','xdestination', 
                                      'ydestination','uturn' ,'agvid','destinationid'])

'Sorting by agv-ID & destination-ID'    
sorted_rawcarray = rawcarray.sort_values(by=['agvid','destinationid'])
rawcarray = sorted_rawcarray.to_numpy()

'generate dummy for array'
distcomb = np.full((robotnode,podnode),0)
oridistcomb = np.full((robotnode,podnode),0)
agv_pod_matchID = np.full((robotnode,podnode),0)
podid = []
robotid = []
listDistanceManhatan = []

'generate dist manhatan'
podbatchdist = 5
dumycol = 0
dumyrow = 0
dumycom = 0

for rgreedy in range(rawnode):
    distmanhatan = 0
    dumycom=dumycom+1
    robot_xcor = rawcarray[rgreedy,0]
    robot_ycor = rawcarray[rgreedy,1]
    pod_xcor = rawcarray[rgreedy,6]
    pod_ycor = rawcarray[rgreedy,7]
    startNode_xcor = rawcarray[rgreedy,2]
    startNode_ycor = rawcarray[rgreedy,3]
    endNode_xcor = rawcarray[rgreedy,4]
    endNode_ycor = rawcarray[rgreedy,5]
    robotid = np.append(robotid,rawcarray[rgreedy,9])
    podid = np.append(podid,rawcarray[rgreedy,10])
    if rawcarray[rgreedy,8]==0:
        uturndist = 0
    else:
        uturndist = 2*podbatchdist
    distmanhatan += manhatanDistance(startNode_xcor, startNode_ycor, robot_xcor, robot_ycor)
    distmanhatan += manhatanDistance(endNode_xcor, endNode_ycor, startNode_xcor, startNode_ycor)
    distmanhatan += manhatanDistance(pod_xcor, pod_ycor, endNode_xcor, endNode_ycor)
    distmanhatan += uturndist
    listDistanceManhatan.append([robotid[rgreedy],distmanhatan,rawcarray[rgreedy,10]])
 
    if dumycom%podnode==1:
        print(dumycom)
        dumyrow = dumyrow+1
        dumycol = 0
    else :
        dumycol = dumycol+1
    distcomb[dumyrow-1,dumycol]=distmanhatan
    oridistcomb[dumyrow-1,dumycol]=distmanhatan
    agv_pod_matchID[dumyrow-1,dumycol] = rawcarray[rgreedy,10]

podid = np.unique(podid)
robotid = np.unique(robotid)
'hungarian'
matrix = distcomb
balance = balancing(matrix)
balance = balance.T
indexes = Munkres().compute(matrix)
# oridistcomb = balancing(oridistcomb)
# indexes = Munkres().compute(matrix)
row = len(balance)
column = len(balance[0])
pairing = []
total = 0
dumyrowraw=0
for row, column in indexes:
    print({row},{column})
    value = oridistcomb[row][column]
    total += value
    pair = [robotid[row],podid[column]]
    pairing = np.append(pairing,pair)
pairing = np.reshape(pairing, (-1,2))
print('total distance: ',{total})

'© 2008-2019 Brian M. Clapper (Munkres Algorithm)' 
