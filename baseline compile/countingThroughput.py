def countThroughput(time,podid):
    import pandas as pd
    import numpy as np
    import os

    assigned_path = os.getcwd() + "/Assigned_order_to_pod.csv"
    selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
    order_cycle_time = []
    for i in range (len(selected_pod)):
        if selected_pod.finish_time[i] == time and selected_pod.id[i] == podid :
            order_cycle_time.append(selected_pod.finish_time[i] - selected_pod.time[i])
    
    return order_cycle_time
