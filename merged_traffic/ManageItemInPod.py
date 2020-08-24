# -*- coding: utf-8 -*-
"""
Created on Tue Jul 21 23:31:18 2020

@author: Chaterine
"""
def reduceItemInPod(pod_id):
    import pandas as pd
    import os
    import numpy as np
    
    assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
    update_pod_path = os.getcwd() + "\Replicate pod data.csv"
    
    selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
    data_pod_reduce = pd.read_csv(update_pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty"])
    data_pod_reduce = data_pod_reduce[data_pod_reduce.pod_id != pod_id]
    data_pod_reduce.to_csv(update_pod_path, index = False) 
    return data_pod_reduce
    
def addItemInPod(pod_id):
    import pandas as pd
    import os
    import numpy as np
    
    assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
    update_pod_path = os.getcwd() + "\Replicate pod data.csv"
    pod_path = os.getcwd() + "\item in pod.csv"
    
    selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
    static_item_in_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty"])
    data_pod_add = pd.read_csv(update_pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty"])
    df = static_item_in_pod[static_item_in_pod.pod_id == pod_id]
    data_pod_add = data_pod_add.append(df,ignore_index=True)
    data_pod_add.to_csv(update_pod_path, index = False) 
    return data_pod_add
