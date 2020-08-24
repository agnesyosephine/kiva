def generateItem(typeItem):
    import random
    import numpy as np
    
    typeItem = 50
    x = np.random.sample(typeItem)
    data = np.linspace(0,typeItem - 1, num=typeItem)
    np.random.shuffle(data)

    return data  