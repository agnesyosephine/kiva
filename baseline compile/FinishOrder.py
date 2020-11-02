import pandas as pd
import numpy as np
import os
def FinishOrderCount(time,cycle):

    assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
    selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])

    count = 0
    for i in range (len(selected_pod)):
    	if selected_pod.finish_time[i] <= time and selected_pod.finish_time[i] > (time - cycle):
    		count = count + selected_pod.qty[i]
    return count
