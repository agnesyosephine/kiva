
# coding: utf-8

# In[8]:


def PodLocation():
    import numpy as np
    import random, math, copy
    import string
    import csv

    with open('D:\\KIVA\\2019 8 August\\8-16\\layout\\layout set 1.csv') as f:
        reader = csv.reader(f,delimiter = ",")
        layout = []
        for row in reader:
            layout.append(row)

    podcoorx = []
    podcoory = []
    for x in range (len(layout)):
        i = layout[x]
        for y in range(len(i)) :
            j = i[y]
            if j == 'pod':
                podcoorx.append(x)
                podcoory.append(y)

    Location = np.c_[podcoorx,podcoory]
    Location.tolist()
    return Location

