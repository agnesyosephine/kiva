import pandas as pd
import os
import numpy as np
def CheckPriorityOrder(time,podlist):

    assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
    selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
    priorityOrder = []
    for j in range (len(selected_pod.id)):
        if selected_pod.finish_time[j] == 0 and (selected_pod.due_date[j] - (time/3600)) < 1:
            priorityOrder.append(selected_pod.id[j]) 

    if len(priorityOrder) == 0:
        result = 999
    else:
        for i in range (len(priorityOrder)):
            if priorityOrder[i] in podlist:
                result = priorityOrder[i]
            else:
                result = 999   
    return result   