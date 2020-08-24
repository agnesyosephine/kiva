# -*- coding: utf-8 -*-
"""
Created on Fri Jul 10 14:40:43 2020

@author: Chaterine
"""

def assignOP(time):
    import pandas as pd
    import os
    import numpy as np
    
    order_path = os.getcwd() + "\orders.csv"
    pod_path = os.getcwd() + "\item in pod.csv"
    assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
    
    hasil_order_path = os.getcwd() + "\hasil orders2.csv"
    hasil_pod_path = os.getcwd() + "\hasil item in pod2.csv"
    hasil_assigned_path = os.getcwd() + "\hasil Assigned_order_to_pod2.csv"
    
    selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
    data_order = pd.read_csv(order_path, names = ["item", "qty", "due_date"])
    data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty"])
    data_order = data_order.sort_values(by=['due_date','qty'])
    data_order = data_order.reset_index(drop=True)

    no_match = []
    opsiPod = []
    #changed b into notAssigned
    notAssigned = []
    for j in range (len(data_order.item)):
        for i in range (len(data_pod.item)):
            if data_pod.item[i] == data_order.item[j] and data_pod.qty[i] >= data_order.qty[j]:
                data_pod.qty[i] -= data_order.qty[j]
                data_pod.due_date[i] = data_order.due_date[j]
                selected_pod.loc[len(selected_pod)] = [data_pod.pod_id[i],data_pod.due_date[i],data_order.qty[j],time,0]
                break;
        if j == (len(data_pod.item)-1):
            no_match.append(j)
            notAssigned.append([data_order.item[j],data_order.qty[j],data_order.due_date[j]])

    selected_pod = selected_pod.sort_values(by= ['due_date','qty'])
    selected_pod = selected_pod.reset_index(drop=True)

    result = selected_pod[selected_pod["finish_time"] == 0].id.values.tolist()
    # np.savetxt(hasil_assigned_path,selected_pod, delimiter = ',')
    # np.savetxt(hasil_order_path, notAssigned, delimiter = ',')
    # np.savetxt(hasil_pod_path, data_pod, delimiter = ',')  
    return result
# import pandas as pd
# import os
# import numpy as np
# time = 0
# order_path = os.getcwd() + "\orders-test.csv"
# pod_path = os.getcwd() + "\item in pod-test.csv"
# assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"

# hasil_order_path = os.getcwd() + "\hasil orders2.csv"
# hasil_pod_path = os.getcwd() + "\hasil item in pod2.csv"
# hasil_assigned_path = os.getcwd() + "\hasil Assigned_order_to_pod2.csv"

# selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
# data_order = pd.read_csv(order_path, names = ["item", "qty", "due_date"])
# data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty"])
# data_order = data_order.sort_values(by=['due_date','qty'])
# data_order = data_order.reset_index(drop=True)

# no_match = []
# opsiPod = []
# #changed b into notAssigned
# notAssigned = []
# for j in range (len(data_order.item)):
#     for i in range (len(data_pod.item)):
#         if data_pod.item[i] == data_order.item[j] and data_pod.qty[i] >= data_order.qty[j]:
#             print(data_pod.pod_id[i])
#             data_pod.qty[i] -= data_order.qty[j]
#             data_pod.due_date[i] = data_order.due_date[j]
#             selected_pod.loc[len(selected_pod)] = [data_pod.pod_id[i],data_pod.due_date[i],data_order.qty[j],time,0]
#             break;
#     if j == (len(data_pod.item)-1):
#         no_match.append(j)
#         notAssigned.append([data_order.item[j],data_order.qty[j],data_order.due_date[j]])

# selected_pod = selected_pod.sort_values(by= ['due_date','qty'])
# selected_pod = selected_pod.reset_index(drop=True)

# result = selected_pod[selected_pod["finish_time"] == 0].id.values.tolist()
    # np.savetxt(hasil_assigned_path,selected_pod, delimiter = ',')
    # np.savetxt(hasil_order_path, notAssigned, delimiter = ',')
    # np.savetxt(hasil_pod_path, data_pod, delimiter = ',')  