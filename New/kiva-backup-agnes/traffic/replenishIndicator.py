def replenishmentIndicator(podid):
    import pandas as pd
    import numpy as np
    import os

    pod_path = os.getcwd() + "\item in pod.csv"
    data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty"])

    rep = 0
    totalQty = 0
    remainingQty = 0
    for i in range (len(data_pod.pod_id)):
        if data_pod.pod_id[i] == podid:
            totalQty += data_pod.max_qty[i]
            remainingQty += data_pod.qty[i]
    if remainingQty <= (totalQty/2):
        rep = 1

    return rep