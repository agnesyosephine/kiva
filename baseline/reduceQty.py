def reduceQtyInPod(podid,time):
    import pandas as pd
    import numpy as np
    import os

    pod_path = os.getcwd() + "\item in pod.csv"
    assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
    data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty"])
    selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])

    item = []
    for i in range (len(data_pod.pod_id)):
        if data_pod.pod_id[i] == podid:
            item.append([data_pod.item[i],data_pod.qty[i],data_pod.due_date[i],data_pod.max_qty[i]])
    for i in range (len(selected_pod)):
    	if selected_pod.id[i] == podid and selected_pod.finish_time[i] <= 0:
    		selected_pod.finish_time[i] = time
    np.savetxt(assigned_path,selected_pod, delimiter = ',')

    return item