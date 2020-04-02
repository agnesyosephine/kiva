def SortByDueDate():
    import numpy as np
    import random, math, copy
    import string
    import csv
    import os

    path = os.getcwd() + "\order\order set 1.csv"
    a = open(path,'r')
    order = [ line.split() for line in a]

    fixorder = []
    list0 = []
    for i in order:
        list1 = []
        for j in i:
            if j != '/':
                k = int(j)
                list1.append(k)
        list0.append(list1)
    orders = list0

    def takeSecond(elem):
        return elem[2]

    orders.sort(key = takeSecond)
    return orders