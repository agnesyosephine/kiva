def assignOP(time):
    import pandas as pd
    import os
    import numpy as np
    
    order_path = os.getcwd() + "\orders.csv"
    pod_path = os.getcwd() + "\item in pod.csv"
    assigned_path = os.getcwd() + "\Assigned_order_to_pod.csv"
    history_order_path = os.getcwd() +"\order history.csv"
    likelihood_path = os.getcwd() + "\likelihood.csv"
    
    data_order = pd.read_csv(order_path, names = ["item", "qty", "due_date"])
    data_pod = pd.read_csv(pod_path, names = ["pod_id", "item", "qty", "due_date", "max_qty","likelihood_rate"])
    selected_pod = pd.read_csv(assigned_path, names = ["id","due_date","qty","time","finish_time"])
    history_order = pd.read_csv(history_order_path, names = ["item", "qty", "due_date"])
    likelihood_data = pd.read_csv(likelihood_path, names = ["item","tot-qty","likelihood_rate"])
    
    columns = ['likelihood_rate']
    data_pod = data_pod.drop(columns=['likelihood_rate'])
    LR_value = pd.DataFrame(columns=columns)
    likelihood_list =[]
    for k in data_pod.item:
        for l in likelihood_data.item:
            if k == l:
                likelihood_list.append(likelihood_data.likelihood_rate[l])
                break
    
    likelihood_series = pd.DataFrame(likelihood_list,columns=['likelihood_rate'])
    data_pod.insert(5,'likelihood_rate',likelihood_series, True)
    data_order = data_order.sort_values(by=['due_date','qty'])
    data_order = data_order.reset_index(drop=True)
    data_pod = data_pod.sort_values(by=['due_date','likelihood_rate'],ascending=[True,False]) #sort by due date and likelihood-rate
    data_pod = data_pod.reset_index(drop=True)
    no_match = []
    opsiPod = []
    
    inside_pod = data_pod[data_pod["item"]==0].values
    #changed b into notAssigned
    notAssigned = []
    for j in range (len(data_order.item)):
        for i in range (len(data_pod.item)):
            if data_pod.item[i] == data_order.item[j] and data_pod.qty[i] >= data_order.qty[j]:
                data_order_xx = data_order.loc[data_order['qty']== j]
                if data_order_xx.empty is False:
                    data_pod.loc[data_pod['qty'] == i] -= data_order.loc[data_order['qty']== j]
                #data_pod.qty[i] -= data_order.qty[j]
                data_order_xx = data_order.loc[data_order['due_date'] == j]
                if data_order_xx.empty is False:
                    data_pod.loc[data_pod['due_date'] == i] = data_order.loc[data_order['due_date'] == j]
                #data_pod.due_date[i] = data_order.due_date[j]
                selected_pod.loc[len(selected_pod)] = [data_pod.pod_id[i],data_pod.due_date[i],data_order.qty[j],time,0]
                break;
        if j == (len(data_pod.item)-1):
            no_match.append(j)
            notAssigned.append([data_order.item[j],data_order.qty[j],data_order.due_date[j]])
    
    selected_pod = selected_pod.sort_values(by= ['due_date','qty'])
    selected_pod = selected_pod.reset_index(drop=True)
    
    selected_clean = selected_pod[selected_pod["finish_time"] == 0].id.values.tolist()
    selected_clean = list(dict.fromkeys(selected_clean))  #remove same id
    result = []
    counter = 0
    for m in selected_clean:
        sum_qty = sum(selected_pod[selected_pod["id"] == m].qty.tolist())
        result.append([selected_clean[counter],sum_qty])
        counter +=1
    np.savetxt(assigned_path,selected_pod, delimiter = ',')
    np.savetxt(order_path, notAssigned, delimiter = ',')
    np.savetxt(pod_path, data_pod, delimiter = ',') 
    return result
 
#a = assignOP(1)
#a

#from munkres import Munkres, print_matrix
#import csv
#import numpy as np
#
#'opening file from csv'
#rawnode = 0
#with open ('for pairing.csv') as rawdata :
#    reader = csv.reader (rawdata, delimiter=",")
#    rawcoor= []
#
#    for row in reader :
#        rawcoor_ = []
#        rawnode = rawnode + 1
#        for col in row :
#            rawcoor_.append(int(col))
#        rawcoor.append(rawcoor_)
#    rawcarray=np.asarray(rawcoor)
#
#'generate dummy for array'
#distcomb = np.full((robotnode,podnode),0)
#oridistcomb = np.full((robotnode,podnode),0)
#podid = []
#robotid = []
#
#'generate dist manhatan'
#podbatchdist = 5
#dumycol = 0
#dumyrow = 0
#dumycom = 0
#for rgreedy in range(rawnode):
#    dumycom=dumycom+1
#    rxcor = rawcarray[rgreedy,0]
#    rycor = rawcarray[rgreedy,1]
#    pxcor = rawcarray[rgreedy,6]
#    pycor = rawcarray[rgreedy,7]
#    sxcor = rawcarray[rgreedy,2]
#    sycor = rawcarray[rgreedy,3]
#    excor = rawcarray[rgreedy,4]
#    eycor = rawcarray[rgreedy,5]
#    robotid = np.append(robotid,rawcarray[rgreedy,9])
#    podid = np.append(podid,rawcarray[rgreedy,10])
#
#    if rawcarray[rgreedy,8]==0:
#        uturndist = 0
#    else:
#        uturndist = 2*podbatchdist
#
#    srxcor = abs(sxcor-rxcor)
#    srycor = abs(sycor-rycor)
#    esxcor = abs(excor-sxcor)
#    esycor = abs(eycor-sycor)
#    pexcor = abs(pxcor-excor)
#    peycor = abs(pycor-eycor)
#
#    distmanhatan = srxcor+srycor+esxcor+esycor+pexcor+peycor+uturndist
#
#    if dumycom%podnode==1:
#        dumyrow = dumyrow+1
#        dumycol = 0
#    else :
#        dumycol = dumycol+1
#    distcomb[dumyrow-1,dumycol]=distmanhatan
#    oridistcomb[dumyrow-1,dumycol]=distmanhatan
#
#podid = np.unique(podid)
#robotid = np.unique(robotid)
#'hungarian'
#matrix = distcomb
#indexes = Munkres().compute(matrix)
#pairing = []
#total = 0
#dumyrowraw=0
#for row, column in indexes:
#    value = oridistcomb[row][column]
#    total += value
#    pair = [robotid[row],podid[column]]
#    pairing = np.append(pairing,pair)
#pairing = np.reshape(pairing, (-1,2))
#print(f'total distance: ',{total})
#
#return pairing