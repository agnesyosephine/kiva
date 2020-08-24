import csv
import numpy as np
import pandas as pd
from copy import deepcopy
from munkres import Munkres, print_matrix
import os

def takeSecond(elem):
    return elem[2]

def balancing(matrix):
    row = len(matrix)
    column = len(matrix[0])
    if row < column:
        zero = np.zeros(column)
        pivotMax = row
        pivotMin = column
        i = pivotMin -1
        for i in range(pivotMin,pivotMax):
            matrix = np.vstack((matrix,zero))
    else:
        zero = np.zeros(row)
        pivotMax = row
        pivotMin = column
        i = pivotMax -1
        for i in range(pivotMin,pivotMax):
            matrix = np.hstack((matrix,np.atleast_2d(zero).T))
    return matrix
           
def manhatanDistance(xStart, yStart, xEnd, yEnd):
    return abs(xStart - xEnd) + abs(yStart - yEnd)

robotnode = 8
podnode = 16
'opening file from csv'
rawnode = 0
with open ('pairing full.csv') as rawdata :
    reader = csv.reader (rawdata, delimiter=",")
    rawcoor= []
    for row in reader :
        rawcoor_ = []
        rawnode = rawnode + 1
        for col in row :
            rawcoor_.append(int(col))
        rawcoor.append(rawcoor_)
        rawcarray=np.asarray(rawcoor)
        rawcarray= pd.DataFrame(rawcoor,
                            columns=['robotxcor','robotycor', 'xstart', 
                                     'ystart','xend','yend','xdestination', 
                                     'ydestination','uturn' ,'agvid','destinationid'])
'Sorting by agv-ID & destination-ID'    
for_pairing_path = os.getcwd() + "\pairing full.csv"
sorted_rawcarray = rawcarray.sort_values(by=['agvid','destinationid'])
rawcarray = sorted_rawcarray.to_numpy()

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
matrix2 = balancing(matrix)
oridistcomb_balance = np.int32(balancing(oridistcomb))
used = deepcopy(matrix2)
indexes = Munkres().compute(used)
pairing = np.empty((0,2), int)
total = 0
dumyrowraw=0
for row, column in indexes:
    if column >= len(oridistcomb[0]):
        continue
    value = oridistcomb[row][column]
    total += value
    pair = np.array([[robotid[row],podid[column]]])
    pairing = np.append(pairing,pair, axis=0)
# return pairing

'© 2008-2019 Brian M. Clapper (Munkres Algorithm)' 
