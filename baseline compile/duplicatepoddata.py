def DuplicatePodData():
    # import pandas as pd
    # import os
    #Change absolute path into relative
    pod_path = os.getcwd() + "\item in pod.csv" 
    data_pod = pd.read_csv(pod_path)
#    copy file
    copy_path = "temprorary item in pod.csv"
    data_pod.to_csv(copy_path, index = False) 
    return()



