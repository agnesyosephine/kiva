def VirtualReplenishment(pod_id):
    import pandas as pd
    import numpy as np
    import os

    pod_path = os.getcwd() + "\item in pod.csv"
    data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty"])

    item = []
    for i in range (len(data_pod.pod_id)):
        if data_pod.pod_id[i] == pod_id:
            data_pod.qty[i] = data_pod.max_qty[i]
            item.append([data_pod.item[i],data_pod.qty[i],data_pod.due_date[i],data_pod.max_qty[i]])
    np.savetxt(pod_path, data_pod, delimiter = ',')  
    return item