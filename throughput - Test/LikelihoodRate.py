def CountLikelihoodRate(itemType,total_item):
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
    data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty"],index_col=False)
    selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
    history_order = pd.read_csv(history_order_path, names = ["item", "qty", "due_date"])
    likelihood_data = pd.read_csv(likelihood_path, names = ["item","tot-qty","likelihood-rate"])
    
    SumOrderQty = history_order.groupby(['item'],as_index=False)['qty'].sum() #Data groupby Order with sum of qty
    
    for i in range(item_limit):
        if  i >= len(SumOrderQty.index) or SumOrderQty['item'][i] :
            row_value = {"item":i,"qty":0}
            SumOrderQty = SumOrderQty.append(row_value, ignore_index=True)
            SumOrderQty = SumOrderQty.sort_values(by=['item'])
            SumOrderQty = SumOrderQty.reset_index(drop=True)
            
    likelihood_score = [] #Storing likelihood score
    for i in range(len(SumOrderQty.item)):
        sum_lh =   SumOrderQty['qty'][i]/total_item * 100
        likelihood_score.append(sum_lh)
    
    df2 = pd.DataFrame(likelihood_score, columns = ['likelihood'])
    order_ = [SumOrderQty, df2] 
    LR_data = pd.concat(order_, axis=1)
    likelihood_data = pd.DataFrame(LR_data,columns=['item','qty','likelihood'])
    LR_data = LR_data.values.tolist()
    likelihood_data.to_csv(likelihood_path, index=False, header=False, encoding='utf-8-sig')
    
    return LR_data


#a = CountLikelihoodRate(50,752)
#a

   
