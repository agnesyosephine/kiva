def randomAGV(numAGV, numIdx):
    from random import sample
    return sample(range(0,numIdx), numAGV)