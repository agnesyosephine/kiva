def assignOP():
    import pandas as pd
    import os
    import numpy as np
    
    order_path = os.getcwd() + "\orders.csv"
    pod_path = os.getcwd() + "\item in pod.csv"
    data_order = pd.read_csv(order_path, names = ["item", "qty", "due_date"])
    data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date"])

    no_match = []
    selected_pod = []
    b = []
    for j in range (len(data_order.item)):
        a = []
        for i in range (len(data_pod.item)):
            if data_pod.item[i] == data_order.item[j] and data_pod.qty[i] >= data_order.qty[j]:
                data_pod.qty[i] = data_pod.qty[i] - data_order.qty[j]
                data_pod.due_date[i] = data_order.due_date[j]
                a.append([data_pod.pod_id[i],data_pod.due_date[i]])
        match = pd.DataFrame(a, columns=['id', 'due_date'])
        match.sort_values(by=['due_date'])
        if match.empty:
            no_match.append(j)
            b.append([data_order.item[j],data_order.qty[j],data_order.due_date[j]])
        else:
            selected_pod.append(match.id[0])

    np.savetxt(order_path, b, delimiter = ',')
    np.savetxt(pod_path, data_pod, delimiter = ',')
    return selected_pod