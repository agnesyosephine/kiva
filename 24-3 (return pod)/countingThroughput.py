def countThroughput(time,cycle):
    import pandas as pd
    import numpy as np
    import os

    assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
    selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
    cycle_time = 0
    total_finished_order = 0
    for i in range (len(selected_pod)):
        if selected_pod.finish_time[i] <= time and selected_pod.finish_time[i] > (time - cycle) :
            cycle_time = cycle_time + (selected_pod.finish_time[i] - selected_pod.time[i])
            total_finished_order = total_finished_order + 1
    avg_cycle_time = cycle_time / total_finished_order
    return avg_cycle_time
