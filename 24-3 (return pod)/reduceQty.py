def reduceQtyInPod(podid):
    import pandas as pd
    import os

    pod_path = os.getcwd() + "\item in pod.csv"
    data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty"])

    item = []
    for i in range (len(data_pod.pod_id)):
        if data_pod.pod_id[i] == podid:
            item.append([data_pod.item[i],data_pod.qty[i],data_pod.due_date[i],data_pod.max_qty[i]])

    return item