def totOP(time):
    import pandas as pd
    import os
    import numpy as np
    
    order_path = os.getcwd() + "\orders.csv"
    pod_path = os.getcwd() + "\item in pod.csv"
    assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
    selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
    #calculate total order qty in a pod
    totorder_pod = selected_pod.groupby(['id'], as_index=False)['qty'].sum()
    totorder_pod = pd.DataFrame(totorder_pod,columns=['id','qty'])
    totorder_pod = totorder_pod.values.tolist()
    return totorder_pod

#check
# a = totOP(15)
# a

#import pandas as pd
#import os
#import numpy as np

#order_path = os.getcwd() + "\orders.csv"
#pod_path = os.getcwd() + "\item in pod.csv"
#assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
#selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
##calculate total order qty in a pod
#totorder_pod = selected_pod.groupby(['id'], as_index=False)['qty'].sum()
#totorder_pod = pd.DataFrame(totorder_pod,columns=['id','qty'])
#totorder_pod = totorder_pod.values.tolist()
# return totorder_pod