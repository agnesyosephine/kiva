def assignOP():
    import pandas as pd
    import os
    import numpy as np
    
    order_path = os.getcwd() + "\orders.csv"
    pod_path = os.getcwd() + "\item in pod.csv"
    assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
    data_order = pd.read_csv(order_path, names = ["item", "qty", "due_date"])
    data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date"])
    data_order = data_order.sort_values(by=['due_date','qty'])
    data_order = data_order.reset_index(drop=True)
    data_pod = data_pod.sort_values(by=['qty'])
    data_pod = data_pod.reset_index(drop=True)
    no_match = []
    opsiPod = []
    #changed b into notAssigned
    notAssigned = []
    for j in range (len(data_order.item)):
        for i in range (len(data_pod.item)):
            if data_pod.item[i] == data_order.item[j] and data_pod.qty[i] >= data_order.qty[j]:
                data_pod.qty[i] -= data_order.qty[j]
                opsiPod.append([data_pod.pod_id[i],data_pod.due_date[i]])
                break;
        if j == (len(data_pod.item)-1):
            no_match.append(j)
            notAssigned.append([data_order.item[j],data_order.qty[j],data_order.due_date[j]])

    np.savetxt(order_path, notAssigned, delimiter = ',')
    np.savetxt(pod_path, data_pod, delimiter = ',')
    np.savetxt(assigned_path, opsiPod, delimiter = ",")    
    return opsiPod
#import pandas as pd
#import os
#import numpy as np
#
#assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
#order_path = os.getcwd() + "\orders.csv"
#pod_path = os.getcwd() + "\item in pod.csv"
#data_order = pd.read_csv(order_path, names = ["item", "qty", "due_date"])
#data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date"])
#data_pod = data_pod.sort_values(by=['qty'])
#data_pod = data_pod.reset_index(drop=True)
#no_match = []
#selected_pod = []
#opsiPod = []
#b = []
#data_order = data_order.sort_values(by=['due_date','qty'])
#data_order = data_order.reset_index(drop=True)
#for j in range (len(data_order)): 
#    for i in range (len(data_pod)):
#        print(data_pod.pod_id[i])
#        if data_pod.item[i] == data_order.item[j] and data_pod.qty[i] >= data_order.qty[j]:
#            data_pod.qty[i] -= data_order.qty[j]
#            opsiPod.append([data_pod.pod_id[i], data_order.due_date[j]])
#            break  
#np.savetxt(assigned_path, opsiPod, delimiter = ",")       
