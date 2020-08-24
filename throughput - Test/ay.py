# -*- coding: utf-8 -*-
"""
Created on Wed Jul 15 00:06:46 2020

@author: Chaterine
"""


import pandas as pd
import os
import numpy as np

item_limit = itemType
order_path = os.getcwd() + "\orders.csv"
pod_path = os.getcwd() + "\item in pod.csv"
assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
history_order_path = os.getcwd() + "\order history.csv"
likelihood_path = os.getcwd() + "\likelihood.csv"

data_order = pd.read_csv(order_path, names = ["item", "qty", "due_date"])
data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty"])
selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
history_order = pd.read_csv(history_order_path, names = ["item", "qty", "due_date"])
likelihood_data = pd.read_csv(likelihood_path, names = ["item","tot-qty","likelihood-rate"])

OrderQty = history_order.groupby(['item'],as_index=False)['qty'].sum()

for i in range(item_limit):
    if OrderQty['item'][i] != i:
        row_value = {"item":i,"qty":0}
        OrderQty = OrderQty.append(row_value, ignore_index=True)
        OrderQty = OrderQty.sort_values(by=['item'])
        OrderQty = OrderQty.reset_index(drop=True)
        
data = []
for i in range(len(OrderQty.item)):
    sum_lh = OrderQty['qty'][i]/total_item * 100
    data.append(sum_lh)

df2 = pd.DataFrame(data, columns = ['likelihood'])
order_ = [OrderQty, df2] 
LR_data = pd.concat(order_, axis=1)
likelihood_data = pd.DataFrame(LR_data,columns=['item','qty','likelihood'])
LR_data = LR_data.values.tolist()
likelihood_data.to_csv(likelihood_path, index=False, header=False, encoding='utf-8-sig')


#a = CountLikelihoodRate(50,752)
#a

   
