def DuplicatePodData():
    import pandas as pd
    import os
    pod_path = os.getcwd() + "\item in pod.csv"
    data_pod = pd.read_csv(pod_path)
    data_pod.to_csv(r"G:\\Pranacahya\Kiva\KIVA-Main\kiva\24-3 (return pod)\\temporary item in pod.csv", index = False)
    return()



