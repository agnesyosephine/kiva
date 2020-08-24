# -*- coding: utf-8 -*-
"""
Created on Tue Jul 14 15:14:38 2020

@author: Chaterine
"""

import pandas as pd
import os
import numpy as np

time = 0
order_path = os.getcwd() + "\orders.csv"
pod_path = os.getcwd() + "\item in pod.csv"
assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
history_order_path = os.getcwd() +"\order history.csv"
likelihood_path = os.getcwd() + "\likelihood.csv"

data_order = pd.read_csv(order_path, names = ["item", "qty", "due_date"])
data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty","likelihood_rate"])
selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
history_order = pd.read_csv(history_order_path, names = ["item", "qty", "due_date"])
likelihood_data = pd.read_csv(likelihood_path, names = ["item","tot-qty","likelihood_rate"])

columns = ['likelihood_rate']
data_pod = data_pod.drop(columns=['likelihood_rate'])
LR_value = pd.DataFrame(columns=columns)
likelihood_list =[]
for k in data_pod.item:
    for l in likelihood_data.item:
        if k == l:
        #data_pod.item[k] == likelihood_data.item[l]:
            #bool(data_pod) == bool(likelihood)
            likelihood_list.append(likelihood_data.likelihood_rate[l])
            break
    print(k)

likelihood_series = pd.DataFrame(likelihood_list,columns=['likelihood_rate'])
data_pod.insert(5,'likelihood_rate',likelihood_series, True)
data_order = data_order.sort_values(by=['due_date','qty'])
data_order = data_order.reset_index(drop=True)
data_pod = data_pod.sort_values(by=['due_date','likelihood_rate'],ascending=[True,False]) #sort by due date and likelihood-rate
data_pod = data_pod.reset_index(drop=True)
no_match = []
opsiPod = []

inside_pod = data_pod[data_pod["item"]==0].values
#changed b into notAssigned
notAssigned = []
for j in range (len(data_order.item)):
    for i in range (len(data_pod.item)):
        if data_pod.item[i] == data_order.item[j] and data_pod.qty[i] >= data_order.qty[j]:
            data_pod.loc[data_pod['qty'] == i] -= data_order.loc[data_order['qty']== j]
            #data_pod.qty[i] -= data_order.qty[j]
            data_pod.loc[data_pod['due_date'] == i] = data_order.loc[data_order['due_date'] == j]
            #data_pod.due_date[i] = data_order.due_date[j]
            selected_pod.loc[len(selected_pod)] = [data_pod.pod_id[i],data_pod.due_date[i],data_order.qty[j],time,0]
            break;
    if j == (len(data_pod.item)-1):
        no_match.append(j)
        notAssigned.append([data_order.item[j],data_order.qty[j],data_order.due_date[j]])

selected_pod = selected_pod.sort_values(by= ['due_date','qty'])
selected_pod = selected_pod.reset_index(drop=True)


selected_clean = selected_pod[selected_pod["finish_time"] == 0].id.values.tolist()
selected_clean = list(dict.fromkeys(selected_clean))  #remove same id
result = []
counter = 0
for m in selected_clean:
    sum_qty = sum(selected_pod[selected_pod["id"] == m].qty.tolist())
    result.append([selected_clean[counter],sum_qty])
    counter +=1
np.savetxt(assigned_path,selected_pod, delimiter = ',')
np.savetxt(order_path, notAssigned, delimiter = ',')
np.savetxt(pod_path, data_pod, delimiter = ',') 