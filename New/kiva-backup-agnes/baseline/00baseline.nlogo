extensions [table matrix array csv py]

breed[AGVs AGV]
breed[pods pod]
breed[jobs job]
breed[emptys empty]
breed[pick-stations pick-station]

globals
[
  total-pod
  total-empty
  pod-size
  pod-list
  time
  next-order-time
  finish-order
  o-cycle-time
  order-count
  stopping
  Stop-Que
  replication
  item-now ;just for placing item
]

emptys-own
[
  order-status
  status
  empty-id
]

pick-stations-own
[
  order
]

pods-own
[
  items
  pod-id
  status
  replenish
  rep-lead-time
]

patches-own
[
  meaning
  intersection-id
]

AGVs-own
[
  count-down
  status
  path-status
  AGV-id
  destination
  xstart
  ystart
  xend
  yend
  u-turn
  straight-first
  availability
  carrying-pod-id
  next-empty-id
  previous-x
  previous-y
  start-time
  q-time
  que-time
  r-cycle-time
]

to setup
  ca
  replication-read
  delete-file
  set-layout ; OK
  py:setup py:python
  output-show "   id       quantity      due date  "
  output-show "------------------------------------"
  generate-order 30
  assign-order-to-pod
  place-agv ; OK
  assigning -1
  reset-ticks
  tick
end

to go
  if not any? turtles [stop]
  ;robot movement
  ask AGVs with [shape = "kiva" or shape = "transparent"]
    [let who-id who st (ifelse
      status = "pick-pod" [pick-pod who-id 0]
      status = "bring-to-picking" [bring-to-picking who-id]
      status = "queuing" [queuing who-id]
      status = "bring-back" [bring-back who-id]
      status = "stop" [stop])]
  ask pods with [replenish = 1][lead-time-count-down]
  checking
  detect-traffic
  ;count output
  if time mod 3600 = 3599 [finished-order 3600]
  ;order & replenishment
  if time = next-order-time + 2 [generate-order 5 update-order assign-order-to-pod update-order next-incoming-order]
  check-pod

  ;replication (number starts from 0)
  ifelse replication <= 29 [if time = 10800 [store-result record-stop-and-go record-replication setup ]][ask turtles [die] carefully [file-delete "replication.csv"][]]

  time-count
  tick
end
;------------------------------------------------------------ SETUP ---------------------------------------------------------------------;
to delete-file
  carefully [file-delete "for pairing.csv"][]
  carefully [file-delete "orders.csv"][]
  carefully [file-delete "item in pod.csv"][]
  carefully [file-delete "Assigned_order_to_pod.csv"][]
  if replication = 0
  [ carefully [file-delete "robot cycle time.csv"][]
    carefully [file-delete "throughput rate.csv"][]
    carefully [file-delete "order cycle time.csv"][]
    carefully [file-delete "stop and go.csv"][]
    carefully [file-delete "replication.csv"][] ]
  file-open "Assigned_order_to_pod.csv" file-type "" file-close
end

to replication-read
  carefully[let rep_ item 0 csv:from-file "Replication.csv" set replication item 0 rep_][set replication 0]
end

to set-layout
  set time time + 1
  let csvmap csv:from-file (word "layout/" layout-file)
  let n 0
  set total-pod 0
  set total-empty 0
  set pod-size 5
  set o-cycle-time []
  let sku-shuffle shuffle range type-of-item
  ask patches [set pcolor 9]
  ask patches
  [
    let listcode item ((pycor - max-pycor) * -1) csvmap
    let itemcode item (pxcor) listcode
    ( ifelse
      itemcode = "pod"
      [ sprout-pods 1
        [ set shape "full square"
          set color sky
          set pod-id total-pod
          place-item pod-id sku-shuffle
          set rep-lead-time 100]
        set meaning "podspace"
        set total-pod total-pod + 1
      ]
      itemcode = "empty"
      [ sprout-emptys 1
        [ set shape "empty space"
          set color 9
          set empty-id total-empty]
        set meaning "empty-space"
        set total-empty total-empty + 1]
      itemcode = "pic"
      [ sprout-pick-stations 1
        [ set shape "person"
          set color black ]
        set meaning "picking-opens"
        set pcolor 9 ]
      itemcode = "rep"
      [ sprout 1
        [ set shape "person"
          set color blue
          stamp
          die ]
        set meaning "picking-opens"
        set pcolor 9 ]
      itemcode = "UR" or itemcode = "UL" or itemcode = "DR" or itemcode = "DL"
      [ set pcolor 9
        set meaning "intersection"
        set intersection-id n
        set n n + 1
      ]
      itemcode = "URC" or itemcode = "ULC" or itemcode = "DRC" or itemcode = "DLC"
      [ set pcolor 9
        set meaning "intersection"
        set intersection-id n
        set n n + 1
      ]
      itemcode = "U"
      [ set pcolor 9
        sprout 1
        [ set shape "direction"
          set color 9
          set heading 0
          stamp die ]
        set meaning "road-up" ]
      itemcode = "D"
      [ set pcolor 9
        sprout 1
        [ set shape "direction"
          set color 9
          set heading 180
          stamp die ]
        set meaning "road-down" ]
      itemcode = "L"
      [ set pcolor 9
        sprout 1
        [ ifelse pycor = 7 or pycor = 8 or pycor = 38 or pycor = 39 [set shape "highway"] [set shape "direction"]
          set color 9
          set heading 270
          stamp die ]
        set meaning "road-left" ]
      itemcode = "R"
      [ set pcolor 9
        sprout 1
        [ ifelse pycor = 7 or pycor = 8 or pycor = 38 or pycor = 39 [set shape "highway"] [set shape "direction"]
          set color 9
          set heading 90
          stamp die ]
        set meaning "road-right" ]
      itemcode = "q" or itemcode = "qi"
      [ sprout 1
        [ set shape "stripes"
          set color black
          set heading 90
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "qq"
      [ sprout 1
        [ set shape "stripes"
          set color black
          set heading 0
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "q1"
      [ sprout 1
        [ set shape "int7"
          set color black
          set heading 0
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "q2"
      [ sprout 1
        [ set shape "int5"
          set color black
          set heading 0
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "q3"
      [ sprout 1
        [ set shape "int3"
          set color black
          set heading 0
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "q4"
      [ sprout 1
        [ set shape "int1"
          set color black
          set heading 0
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "q5"
      [ sprout 1
        [ set shape "int2"
          set color black
          set heading 0
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "q6"
      [ sprout 1
        [ set shape "int6"
          set color black
          set heading 0
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "q7"
      [ sprout 1
        [ set shape "int8"
          set color black
          set heading 0
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "q9"
      [ sprout 1
        [ set shape "int7"
          set color black
          set heading 0
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "q10"
      [ sprout 1
        [ set shape "int5"
          set color black
          set heading 180
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "q11"
      [ sprout 1
        [ set shape "int1"
          set color black
          set heading 180
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "qi2"
      [ sprout 1
        [ set shape "int4"
          set color black
          set heading 0
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "qi3"
      [ sprout 1
        [ set shape "int9"
          set color black
          set heading 180
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "qo"
      [ sprout 1
        [ set shape "arrow1"
          set color black
          set heading 0
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      itemcode = "qo2"
      [ sprout 1
        [ set shape "arrow1"
          set color black
          set heading 180
          stamp
          die ]
        set pcolor 9
        set meaning "queue" ]
      [ set pcolor 9 ])
  ]
end

to place-agv
  let agvloc csv:from-file (word "AGV/" AGV-location-file)
  let n 0
  loop
  [ ifelse n < AGV-number
    [ let agvcode item n agvloc
      ask patches with [pxcor = item 0 agvcode and pycor = item 1 agvcode]
      [ sprout-AGVs 1
        [ set AGV-id n
          set size 0.9
          set color 9
          set availability 1
          set shape "kiva"
          set status "pick-pod"
          set count-down round(random-poisson 15)
          set next-empty-id (total-empty + AGV-id + 1)
          ( ifelse
            item 2 agvcode = "up"
            [ set heading 0 ]
            item 2 agvcode = "down"
            [ set heading 180 ]
            item 2 agvcode = "right"
            [ set heading 90 ]
            [ set heading 270 ] )
          pair-pick-pod AGV-id
        ] ] ]
    [stop]
    set n n + 1]
end

to place-item [pod-id- sku-shuffle]
  ask pods with [pod-id = pod-id-]
  [ set items []
    let n 0
    loop
    [ ifelse n < sku-per-pod
      [ let sku []
        let item-type item item-now sku-shuffle

        ; generate random number 5~15 with Poisson distribution for item qty in pod
        let qty random-poisson 10
        while [qty < 5 or qty > 15]
        [set qty random-poisson 10]

        let due 999
        set sku insert-item 0 sku item-type
        set sku insert-item 1 sku qty
        set sku insert-item 2 sku due
        set sku insert-item 3 sku qty
        set items insert-item n items sku

        ;record in excel
        file-open "item in pod.csv"
        file-type pod-id- file-type "," file-type item-type file-type "," file-type qty file-type "," file-type due file-type "," file-type qty file-type "\n"
        file-close

        set n n + 1
        ifelse item-now + 1 = length sku-shuffle [set item-now 0] [set item-now item-now + 1]
      print item-type]
      [stop]]]
end

;------------------------------------------------------------ ORDER & REPLENISHMENT ---------------------------------------------------------------------;
to virtual-replenish [id]
  py:set "pod_id" id
  (py:run
    "import virtualRep"
    "item = virtualRep.VirtualReplenishment(pod_id)")
  let pod_item_now py:runresult "item"
  ask pods with [pod-id = pod-id] [set replenish 0 set items pod_item_now]
end

to next-incoming-order
  let n round(random-exponential 20)
  set next-order-time time + n
end

to time-count
  set time time + 1
end

to generate-order [num]
  let n 0
  loop
  [ ifelse n < num
    [ ;random generator
      let item-type random type-of-item
      let qty (random-poisson 5) + 1
      let due (random 5) + 1

      ;export excel
      file-open "orders.csv"
      file-type item-type file-type "," file-type qty file-type "," file-type due file-type "\n"
      file-close
      set n n + 1]
    [ stop]]
end

to update-order
  let row []
  clear-output
  output-show "   id       quantity      due date  "
  output-show "------------------------------------"
  file-open "orders.csv"
  if not file-at-end?
  [let result csv:from-row file-read-line
    while [not file-at-end?]
    [ set row csv:from-row file-read-line

      let item-type item 0 row
      let qty item 1 row
      let due item 2 row

      ;show output
      ifelse item-type < 10
      [output-show (word "   0" item-type "          " qty "              " due "     ")]
      [output-show (word "   " item-type "          " qty "              " due "     ")]]]

    file-close
end

;------------------------------------------------------------ OUTPUT ---------------------------------------------------------------------;

to finished-order [cycle]
  py:set "time" time
  py:set "cycle" cycle
  (py:run
    "import FinishOrder"
    "count = FinishOrder.FinishOrderCount(time,cycle)")
  set finish-order py:runresult "count"
  file-open "throughput rate.csv"
  file-type finish-order file-type "\n"
  file-close
end

to count-order-cycle-time [podid]
  py:set "time" time
  py:set "podid" podid
  (py:run
    "import countingThroughput"
    "order_cycle_time = countingThroughput.countThroughput(time,podid)")
  let result py:runresult "order_cycle_time"
  set o-cycle-time insert-item length o-cycle-time o-cycle-time result
end

to plot-order-ct
  if length o-cycle-time != 0
  [ file-open "order cycle time.csv"
    foreach o-cycle-time
    [ x -> let m item 0 x  plot m file-type m file-type "\n"]
    file-close
    set o-cycle-time []
  ]
end

to count-robot-cycle-time
  set r-cycle-time time - start-time
  file-open "robot cycle time.csv"
  file-type r-cycle-time file-type "\n"
  file-close
end

to record-stop-and-go
  file-open "stop and go.csv"
  file-type stopping file-type "\n"
  file-close
end

to record-replication
  set replication replication + 1
  carefully [file-delete "Replication.csv"][]
  file-open "Replication.csv" file-type replication file-close
end

to store-result
  export-plot "Robot Cycle Time" (word "/result/robot cycle time" replication ".csv")
  export-plot "Robot traveling Time" (word "/result/robot traveling time" replication ".csv")
end

;------------------------------------------------------------ SWITCH POD & EMPTY ---------------------------------------------------------------------;

to check-pod
  let n 0
  ask patches with [meaning = "podspace" or meaning = "empty-space"]
  [ let xc pxcor let yc pycor
    if not any? turtles with [xcor = xc and ycor = yc]
    [ sprout-emptys 1
      [ set shape "empty space"
        set color 9
        set total-empty total-empty + 1
        while [any? emptys with [empty-id = n]]
          [ set n n + 1]
        set empty-id n]
      set meaning "empty-space"]]
end

to switch-empty [xc yc id]
  let n 0
  ask AGVs with [who = id] [set n next-empty-id]
  ask patches with [pxcor = xc and pycor = yc]
  [ if not any? emptys with [xcor = xc and ycor = yc]
    [ sprout-emptys 1
      [ set shape "empty space"
        set color 9
        set total-empty total-empty + 1
        while [any? emptys with [empty-id = n]]
          [ set n n + 1]
        set empty-id n]
      set meaning "empty-space"]
    ask pods with [xcor = xc and ycor = yc]
    [set shape "empty space" set color 9]]
end

to switch-pod [xc yc id]
  let transfer-pod-id 0
  let transfer-empty-id empty-id
  let items_ 0 let status_ 0 let replenish_ 0
  ask AGVs with [who = id] [set transfer-pod-id carrying-pod-id set next-empty-id transfer-empty-id]
  ask pods with [pod-id = transfer-pod-id] [set pod-id -1 set items_ items set status_ status set replenish_ replenish]
  ask patches with [pxcor = xc and pycor = yc]
  [ sprout-pods 1
    [ set shape "full square"
      set color sky
      set pod-id transfer-pod-id
      set items items_
      set status status_
      set replenish replenish_]
    set meaning "podspace"]
  ask pods with [pod-id = -1][die]
  ask emptys with [xcor = xc and ycor = yc][die]
end

to reduce-qty [pod_id]
  py:set "podid" pod_id
  py:set "time" time
  (py:run
    "import reduceQty"
    "item = reduceQty.reduceQtyInPod(podid,time)"
    "import replenishIndicator"
    "rep = replenishIndicator.replenishmentIndicator(podid)")
  let pod_item_now py:runresult "item"
  let rep py:runresult "rep"
  ask pods with [pod-id = pod_id][set items pod_item_now set replenish rep]
  count-order-cycle-time pod_id
end

to selected-pods [assignment-result]
  let m 0
  let x 0
  let y 0
  loop
  [ ifelse m < length assignment-result
    [ ask pods with [pod-id = item m assignment-result]
      [ set shape "shelf"
        set size 1
        set color 138
        set x xcor
        set y ycor]
      set m m + 1]
    [stop]]
end

;------------------------------------------------------------ ASSIGNMENT ---------------------------------------------------------------------;

to assign-order-to-pod
  let time_ time
  if time_ = 1 [ set time_ round (random-exponential -30)]
  py:set "time" time_
  (py:run
    "import assignmentOP"
    "result = assignmentOP.assignOP(time)")
  set pod-list py:runresult "result"
  set pod-list remove-duplicates pod-list

  selected-pods pod-list
end

to pair-pick-pod [id]
  ;for assignment
  let looping-agv 0
  let looping-pod 0
  let xjob 0 let yjob 0
  let max-pod-to-assign 0
  ifelse length pod-list  > 2 * AGV-number [set max-pod-to-assign (2 * AGV-number)] [set max-pod-to-assign length pod-list ]
  loop ;for every AGV
  [ set looping-pod 0 ;one AGV with each pod
    ifelse looping-agv < AGV-number
    [ loop ;for every pod
      [ ifelse looping-pod < max-pod-to-assign
        [ ask pods with [pod-id = item looping-pod pod-list] [set xjob xcor set yjob ycor let n pod-id ask AGVs with [AGV-id = id] [set destination n]]
          starting-intersection id destination
          ending-intersection id destination
          file-open "for pairing.csv"
          file-type xcor file-type "," file-type ycor file-type "," file-type xstart file-type "," file-type ystart file-type "," file-type xend file-type "," file-type yend file-type "," file-type xjob file-type "," file-type yjob file-type "," file-type u-turn file-type "," file-type AGV-id file-type "," file-type destination file-type "\n"
          file-close]
        [stop]
        set looping-pod looping-pod + 1]]
    [stop]
    set looping-agv looping-agv + 1
  ]
end

to pair-next [id]
  ifelse not any? pods with [shape = "shelf"];no selected pod left
  [ask AGVs with [AGV-id = id][set status "stop"]]
  ;for assignment
  [ let looping-agv 0
    let looping-pod 0
    let xjob 0 let yjob 0
    let max-pod-to-assign 0
    ifelse length pod-list > 2 [set max-pod-to-assign 2] [set max-pod-to-assign length pod-list]
    set looping-pod 0 ;one AGV with each pod
    loop ;for every pod
    [ ifelse looping-pod < max-pod-to-assign
      [ ask pods with [pod-id = item looping-pod pod-list] [set xjob xcor set yjob ycor let n pod-id ask AGVs with [AGV-id = id] [set destination n]]
        starting-intersection id destination
        ending-intersection id destination
        file-open "for pairing.csv"
        file-type xcor file-type "," file-type ycor file-type "," file-type xstart file-type "," file-type ystart file-type "," file-type xend file-type "," file-type yend file-type "," file-type xjob file-type "," file-type yjob file-type "," file-type u-turn file-type "," file-type AGV-id file-type "," file-type destination file-type "\n"
        file-close
        set looping-pod looping-pod + 1]
      [stop]]]
end

to assigning [num]
  if not empty? pod-list;no selected pod left
  [let pod-to-assign 0
    let available-AGV 0
    ( ifelse
      num = -1 and length pod-list  > AGV-number * 2 [set pod-to-assign AGV-number * 2 set available-AGV AGV-number]
      num = -1 and length pod-list  <= AGV-number * 2 [set pod-to-assign length pod-list  set available-AGV AGV-number]
      num != -1 and length pod-list  > 1 [set pod-to-assign 2 set available-AGV 1]
      num != -1 and length pod-list  <= 1 [set pod-to-assign 1 set available-AGV 1])

    let assignment 0
    ifelse pod-to-assign != 1
    [ py:set "robotnode" available-AGV
      py:set "podnode" pod-to-assign
      (py:run
        "import assignmentRP"
        "result = assignmentRP.AssignmentRobotToPod(robotnode,podnode)")
      let result py:runresult "result"
;      print(result)
      set assignment table:from-list result

      ;selecting
      ifelse num = -1
      [ ask AGVs [ let a AGV-id let b 0 set availability 1
        ask pods with [pod-id = table:get assignment a] [set status 1 set b pod-id] set destination b
        starting-intersection AGV-id destination
        ending-intersection AGV-id destination
        set carrying-pod-id destination
        set start-time time
        set pod-list remove b pod-list]]
      [ ask AGVs with [AGV-id = num] [ let a AGV-id let b 0 set availability 1
        ask pods with [pod-id = table:get assignment a] [set status 1 set b pod-id] set destination b
        starting-intersection AGV-id destination
        ending-intersection AGV-id destination
        set carrying-pod-id destination
        set start-time time
        set pod-list remove b pod-list]]]
    [ask AGVs with [AGV-id = num] [ let a AGV-id let b 0 set availability 1
      ask pods with [pod-id = item 0 pod-list] [set status 1 set b pod-id] set destination b
      starting-intersection AGV-id destination
      ending-intersection AGV-id destination
      set carrying-pod-id destination
      set start-time time
      set pod-list remove b pod-list]]
    carefully [file-delete "for pairing.csv"][]]
end

to assigning-empty
  let y-bound 38
  let max-pod-to-assign 0
  let available-AGV 0
  ask AGVs with [availability = 0][set available-AGV available-AGV + 1]
  while [max-pod-to-assign < (available-AGV * 2)]
  [ set y-bound (y-bound - pod-size + 1)
    set max-pod-to-assign 0
    ask emptys with [ycor > y-bound and status != 1][set max-pod-to-assign max-pod-to-assign + 1]]
  py:set "robotnode" available-AGV
  py:set "podnode" max-pod-to-assign
  (py:run
    "import assignmentRP"
    "result = assignmentRP.AssignmentRobotToPod(robotnode,podnode)")
  let result py:runresult "result"
;  print(result)
  let assignment table:from-list result

  ;selecting
  ask AGVs with [availability = 0] [ let a AGV-id let b 0  set availability 1
    ask emptys with [empty-id = table:get assignment a] [set status 1 set b empty-id set total-empty total-empty - 1] set destination b
    starting-intersection-return AGV-id destination
    ending-intersection-return AGV-id destination
    set path-status "on-the-way"]
  carefully [file-delete "for pairing.csv"][]
end

to pair-empty-loc [id]
  ;for assignment
  let looping-agv 0
  let looping-pod 0
  let xjob 0 let yjob 0
  let y-bound 38
  let max-pod-to-assign 0
  let available-AGV 0
  ask AGVs with [availability = 0] [set available-AGV available-AGV + 1]
  while [max-pod-to-assign < (available-AGV * 2)]
  [ set y-bound (y-bound - pod-size + 1)
    set max-pod-to-assign 0
    ask emptys with [ycor > y-bound and status != 1][set max-pod-to-assign max-pod-to-assign + 1]]
  ask emptys with [ycor > y-bound and status != 1] [set xjob xcor set yjob ycor let n empty-id
    ask AGVs with [AGV-id = id]
    [ set destination n
      starting-intersection-return id destination
      ending-intersection-return id destination
      file-open "for pairing.csv"
      file-type xcor file-type "," file-type ycor file-type "," file-type xstart file-type "," file-type ystart file-type "," file-type xend file-type "," file-type yend file-type "," file-type xjob file-type "," file-type yjob file-type "," file-type u-turn file-type "," file-type AGV-id file-type "," file-type destination file-type "\n"
      file-close]]

  ;check start&end
;  ask AGVs with [AGV-id = id] [ let n xstart let m ystart let o xend let p yend let q color ask patches with [pxcor = n and pycor = m] [set pcolor q]
;  ask patches with [pxcor = o and pycor = p] [set pcolor q]]
end

to starting-intersection-return [id jobloc]
  ask AGVs with [AGV-id = id] [set ystart 39
    ( ifelse
      xcor < 10 [set xstart 4]
      xcor < 16 and xcor > 9 [set xstart 10]
      xcor < 22 and xcor > 15 [set xstart 16]
      xcor < 28 and xcor > 21 [set xstart 22]
      xcor >= 28 [set xstart 28])]
end

to ending-intersection-return [id jobloc]
  let xjob 0 let yjob 0 let m 0 let n 0 let o 0
  ask emptys with [empty-id = jobloc] [set xjob xcor set yjob ycor]
  ask AGVs with [AGV-id = id]
  [ set u-turn 0 set straight-first 0 ;return value
    ;determine xend
    ask patches with [pxcor = xjob - 1 and pycor = yjob] [if meaning != "podspace" and meaning != "empty-space" [set m 1]]
    ifelse m = 1 [set xend xjob - 1] [set xend xjob + 1]
    set o xend

    ;determine yend
    ask patches with [pxcor = o and pycor = yjob] [if meaning = "road-up" [set n 1]]
    ifelse n = 0
    [(ifelse
      yjob < 14 [set yend 14 set straight-first 1]
      yjob < 20 and yjob > 14 [set yend 20 set straight-first 1]
      yjob < 26 and yjob > 20 [set yend 26 set straight-first 1]
      yjob < 32 and yjob > 26 [set yend 32]
      [ifelse xcor < xend [set yend 38] [set yend 39]])]
    [(ifelse
      yjob < 14 [set yend 8 set straight-first 1]
      yjob < 20 and yjob > 14 [set yend 14 set straight-first 1]
      yjob < 26 and ycor > 20 [set yend 20 set straight-first 1]
      yjob < 32 and yjob > 26 [set yend 26 set straight-first 1]
      [set yend 32])
      set u-turn 3
      set straight-first 1
    ]
    (ifelse
      u-turn = 3 and xcor < xend and yend mod 4 = 2 [set straight-first 1]
      u-turn = 3 and xcor > xend and yend mod 4 = 0 [set straight-first 1]
      xcor > xend and yend mod 4 = 0 [set straight-first 1]
      xcor < xend and yend mod 4 = 2 and yend != 38 and yend != 39 [set straight-first 1])]
end

to starting-intersection [id jobloc]
  let xjob 0 let yjob 0
  ask pods with [pod-id = jobloc] [set xjob xcor set yjob ycor]
  ask AGVs with [AGV-id = id]
  [ let n xcor
    ifelse ycor < yjob
    ;SEARCHING INTERSECTION UP DIRECTION
    [ (ifelse
      ycor < 14 [set ystart 14]
      ycor < 20 and ycor > 14 [set ystart 20]
      ycor < 26 and ycor > 20 [set ystart 26]
      ycor < 32 and ycor > 26 [set ystart 32]
      [set ystart 38])
      (ifelse
        xcor mod 2 = 0
        [ask patches with [pxcor = (n + 1) and pycor = 38] [ifelse meaning = "intersection" [ask AGVs with [AGV-id = id] [set xstart (n + 1)]] [ask AGVs with [AGV-id = id] [set xstart (n - 1)]]]]
        xcor mod 2 = 1
        [ask patches with [pxcor = (n + 2) and pycor = 38] [ifelse meaning = "intersection"  [ask AGVs with [AGV-id = id] [set xstart (n + 2)]] [ask AGVs with [AGV-id = id] [set xstart (n - 2)]]]])]

    ;SEARCHING INTERSECTION DOWN DIRECTION
    [(ifelse
      ycor < 14 [set ystart 8]
      ycor < 20 and ycor > 14 [set ystart 14]
      ycor < 26 and ycor > 20 [set ystart 20]
      ycor < 32 and ycor > 26 [set ystart 26]
      [set ystart 32])
      (ifelse
        xcor mod 2 = 1
        [ask patches with [pxcor = (n + 1) and pycor = 38] [ifelse meaning = "intersection" [ask AGVs with [AGV-id = id] [set xstart (n + 1)]] [ask AGVs with [AGV-id = id] [set xstart (n - 1)]]]]
        xcor mod 2 = 0
        [ask patches with [pxcor = (n + 2) and pycor = 38] [ifelse meaning = "intersection" [ask AGVs with [AGV-id = id] [set xstart (n + 2)]] [ask AGVs with [AGV-id = id] [set xstart (n - 2)]]]])]]
end

to ending-intersection [id jobloc]
  let xjob 0 let yjob 0 let a 0 let b 0
  ask pods with [pod-id = jobloc] [set xjob xcor set yjob ycor]
  ask AGVs with [AGV-id = id]
  [ set u-turn 0 set straight-first 0 ;return value
    let n xjob set u-turn 0
    ;ROBOT COME FROM UP DIRECTION
    ifelse ycor > yjob
    [ set a 1
      (ifelse
        yjob < 14 [set yend 14]
        yjob < 20 and yjob > 14 [set yend 20]
        yjob < 26 and yjob > 20 [set yend 26]
        yjob < 32 and yjob > 26 [set yend 32]
        [set yend 38])]

    ;ROBOT COME FROM DOWN DIRECTION
    [(ifelse
      yjob < 14 [set yend 8]
      yjob < 20 and yjob > 14 [set yend 14]
      yjob < 26 and yjob > 20 [set yend 20]
      yjob < 32 and yjob > 26 [set yend 26]
      [set yend 32])]

    ifelse in-one-y-block? id jobloc
    ;special case, in one y block -> must have same y starting & ending point
    [if yend != ystart [change-yend a] set u-turn 1]

    ;special case, different aisle direction, can't go directly
    [ if yend = ystart
      [(ifelse
        xstart < xjob and abs(xstart - xjob) > 3 and abs(ystart) mod 4 != 2 [change-yend a]
        xstart > xjob and abs(xstart - xjob) > 3 and abs(ystart) mod 4 != 0 [change-yend a])]]

    ;determine x end
    ( ifelse
      yjob < yend [if xjob mod 2 = 1 [set b 1]] ;down direction
      yjob > yend [if xjob mod 2 = 0 [set b 1]]) ;up direction
    ifelse b = 1
    [ ask patches with [pxcor = (n + 1) and pycor = 32] [ifelse meaning = "intersection" [ask AGVs with [AGV-id = id] [set xend (n + 1) set b 1]] [ask AGVs with [AGV-id = id] [set xend (n - 1)]]]]
    [ ask patches with [pxcor = (n + 2) and pycor = 32] [ifelse meaning = "intersection" [ask AGVs with [AGV-id = id] [set xend (n + 2) set b 1]] [ask AGVs with [AGV-id = id] [set xend (n - 2)]]]]
    set path-status "go-to-aisle"
    ]
end

to change-yend [a]
  ( ifelse
    a = 1 and yend = 14 [set yend 8]
    a = 1 and yend = 20 [set yend 14]
    a = 1 and yend = 26 [set yend 20]
    a = 1 and yend = 32 [set yend 26]
    a = 1 and yend = 38 [set yend 32]
    a = 0 and yend = 8 [set yend 14]
    a = 0 and yend = 14 [set yend 20]
    a = 0 and yend = 20 [set yend 26]
    a = 0 and yend = 26 [set yend 32]
    a = 0 and yend = 32 [set yend 38])
end

;------------------------------------------------------------ TRAFFIC ---------------------------------------------------------------------;

to detect-traffic
  ask patches with [meaning = "intersection"]
  [ let num-AGV count AGVs in-radius 2
    ifelse num-AGV > 1 [set pcolor red][set pcolor 9]]
end

;------------------------------------------------------------ MOVE ---------------------------------------------------------------------;
to pick-pod [b block]
  let xjob 0 let yjob 0
  ask AGVs with [who = b]
  [ let n destination
    ask pods with [pod-id = n] [set xjob xcor set yjob ycor]
    ( ifelse
      path-status = "go-to-aisle" [go-to-aisle yjob]
      path-status = "reaching-destination" [reaching-destination xjob yjob]
      path-status = "on-the-way" [on-the-way if path-status = "arrive"[set block 1]]
      path-status = "arrive" [bring-pod-out if block = 1 [block-road "?" AGV-id set block 0] ask pods with [pod-id = n and shape != "empty space"][switch-empty xjob yjob b]])]
end

to go-to-aisle [yjob]
  ;ROBOT LOCATION BELOW THE POD
  ifelse xcor != xstart
  [(ifelse
    xcor < xstart and heading = 270 [move-to patch-ahead 0 rt 180 not-collide]
    xcor > xstart and heading = 90 [move-to patch-ahead 0 rt 180 not-collide]
    [not-collide])
    ifelse in-one-block? AGV-id destination and ycor = yjob [set path-status "reaching-destination"] [set path-status "go-to-aisle"]]
  [ let m 0
    ask patch-here [if meaning = "road-down" [set m 1]]
    ( ifelse
      m = 1 and heading = 270 [move-to patch-ahead 0 lt 90 not-collide]
      m = 1 and heading = 90 [move-to patch-ahead 0 rt 90 not-collide]
      m = 0 and heading = 270 [move-to patch-ahead 0 rt 90 not-collide]
      m = 0 and heading = 90 [move-to patch-ahead 0 lt 90 not-collide])
    ifelse in-one-block? AGV-id destination [set path-status "reaching-destination"] [set path-status "on-the-way"]]
end

to on-the-way
  let m 0
  ask patch-here [if meaning = "intersection" [set m 1]]
  ifelse m = 1
  [( ifelse
    xcor = xstart and ycor = ystart and right-way? [ifelse can-turn-left? [move-to patch-ahead 0 lt 90 not-collide] [move-to patch-ahead 0 rt 90 not-collide]]
    going-further? [ifelse can-turn-left? [move-to patch-ahead 0 lt 90 not-collide] [move-to patch-ahead 0 rt 90 not-collide]]
    end-point? and heading = 90 [ifelse can-turn-left? [move-to patch-ahead 0 lt 90 not-collide] [move-to patch-ahead 0 rt 90 not-collide] set path-status "reaching-destination"]
    end-point? and heading = 270 [ifelse can-turn-left? [move-to patch-ahead 0 lt 90 not-collide] [move-to patch-ahead 0 rt 90 not-collide] set path-status "reaching-destination"]
    end-point? and heading = 0 [set path-status "reaching-destination"]
    end-point? and heading = 180 [set path-status "reaching-destination"]
    turning? [ifelse can-turn-left? [move-to patch-ahead 0 lt 90 not-collide] [move-to patch-ahead 0 rt 90 not-collide]]
    u-turn = 3 and ycor = yend and not right-turn? [set u-turn 4]
    [not-collide])]
  [not-collide]
end

to reaching-destination [xj yj]
  let m 0
  ask patch-here [if meaning = "podspace" or meaning = "empty-space" [set m 1]]
  ( ifelse
    ycor = yj and xcor != xj and m = 0
    [(ifelse
      xcor < xj and heading = 0 [move-to patch-ahead 0 rt 90 not-collide]
      xcor < xj and heading = 180 [move-to patch-ahead 0 lt 90 not-collide]
      xcor > xj and heading = 0 [move-to patch-ahead 0 lt 90 not-collide]
      xcor > xj and heading = 180 [move-to patch-ahead 0 rt 90 not-collide]
      [not-collide])]
    ycor = yj and xcor = xj [set path-status "arrive"]
    m = 1 [not-collide]
    [not-collide])
end

to bring-pod-out
  let m 0
  let n 0
  ask patch-ahead 1 [if meaning = "road-up" or meaning = "road-down" [set n 1]]
  ask patch-here
  [(ifelse
    meaning = "empty-space" and n = 0 [set m 1]
    meaning = "road-up" [set m 2]
    meaning = "road-down" [set m 3])]
  (ifelse
    m = 0 [not-collide]
    m = 1 [move-to patch-ahead 0 lt 180 not-collide]
    m = 2 and heading = 270 [move-to patch-ahead 0 rt 90 not-collide set status "bring-to-picking"]
    m = 2 and heading = 90 [move-to patch-ahead 0 lt 90 not-collide set status "bring-to-picking"]
    m = 3 and heading = 270 [move-to patch-ahead 0 lt 90 not-collide set status "bring-to-picking"]
    m = 3 and heading = 90 [move-to patch-ahead 0 rt 90 not-collide set status "bring-to-picking"])
end

to bring-to-picking [n]
  let m 0
  ask patch-here [if meaning = "intersection" [set m 1]]
  ask AGV n
  [ if ycor >= 38 and ycor < 43 and q-time = 0 and any? AGVs-on patch-ahead 1 [set q-time time]
    if ycor = 43 and q-time = 0 [set q-time time]
    ifelse m = 1
    [ (ifelse
      heading = 90 and ycor = 38 and xcor = 7 [move-to patch-ahead 0 lt 90 not-collide]
      heading = 90 and ycor = 38 and xcor = 13 [move-to patch-ahead 0 lt 90 not-collide]
      heading = 90 and ycor = 38 and xcor = 19 [move-to patch-ahead 0 lt 90 not-collide]
      heading = 90 and ycor = 38 and xcor = 25 [move-to patch-ahead 0 lt 90 not-collide]
      heading = 90 and ycor = 38 and xcor = 31 [move-to patch-ahead 0 lt 90 not-collide]

      heading = 270 and can-turn-right? [move-to patch-ahead 0 rt 90 not-collide]
      heading = 90 and can-turn-left? [move-to patch-ahead 0 lt 90 not-collide]
      heading = 0 and xcor = 1 and can-turn-right? [move-to patch-ahead 0 rt 90 not-collide]
      heading = 180 and can-turn-right? [move-to patch-ahead 0 rt 90 not-collide]
      heading = 180 and can-turn-left? and xcor != 34 [move-to patch-ahead 0 lt 90 not-collide]
      heading = 180 and ycor = 8 [move-to patch-ahead 0 rt 90 not-collide]
      heading = 0 and xcor = 1 and ycor = 38 [move-to patch-ahead 0 rt 90 not-collide]
      heading = 270 and xcor = 1 and ycor = 8 [move-to patch-ahead 0 rt 90 not-collide]
      heading = 180 and xcor = 34 and ycor = 8 [move-to patch-ahead 0 rt 90 not-collide]
      heading = 90 and xcor = 34 and ycor = 38 [move-to patch-ahead 0 rt 90 not-collide]
      heading = 270 and xcor = 1 [move-to patch-ahead 0 rt 90 not-collide]
      heading = 90 and xcor = 34 [move-to patch-ahead 0 rt 90 not-collide]
      [not-collide])]

    [(ifelse
      ycor = 43 and  xcor = 7 [set status "queuing"]
      ycor = 43 and  xcor = 13 [set status "queuing"]
      ycor = 43 and  xcor = 19 [set status "queuing"]
      ycor = 43 and  xcor = 25 [set status "queuing"]
      ycor = 43 and  xcor = 31 [set status "queuing"]
      [not-collide])]]
end

to queuing [n]
  ask AGV n
  [ if path-status != "on-the-way" [set availability 0]
    (ifelse
    ycor = 45 and xcor mod 6 = 1 and heading = 0 [move-to patch-ahead 0 lt 90 not-collide]
    ycor = 45 and xcor mod 6 = 4 [stay]
    [not-collide])
    ]
end

to not-collide
  let AGV-ahead one-of AGVs-on patch-ahead 1
  let n 0 let heading-ahead abs(heading - 180) let m 0
  let id AGV-id let AGV-ahead-who 0
  carefully[ask AGV-ahead [if AGV-id = id [set n 1] if hidden? [set m 1] if heading = heading-ahead [set heading-ahead "deadlock"] set AGV-ahead-who who]][]
  (ifelse
    AGV-ahead = nobody or m = 1 [set previous-x xcor set previous-y ycor ifelse heading = 180 and ycor - 1 <= 8 [set shape "transparent"] [set shape "kiva" set color 9 set size 0.9] fd 1]
    n = 1 [fd 1 ask AGV-ahead [die]]
    heading-ahead = "deadlock" and n != 1 [resolve who resolve AGV-ahead-who])
  if AGV-ahead != nobody or n = 1 [
    if previous-x != xcor or previous-y != ycor
    [set previous-x xcor set previous-y ycor  ifelse status = "queuing" [set Stop-Que Stop-Que + 1] [set stopping stopping + 1]]]
  ask AGVs with [shape = "dot"][let status-change 0 let dot-id agv-id ask AGVs with [AGV-id = dot-id][if path-status != "arrive" [set status-change 1]] if status-change = 1 [die]]
end

to bring-back [id]
  let xjob 0 let yjob 0
  ask AGVs with [who = id]
  [ let n destination
    ask emptys with [empty-id = n] [set xjob xcor set yjob ycor]
    ( ifelse
      path-status = "reaching-destination" [reaching-destination xjob yjob]
      path-status = "on-the-way" [on-the-way]
      path-status = "arrive" [ask emptys with [empty-id = n][switch-pod xjob yjob id] count-robot-cycle-time set status "pick-pod" pair-next AGV-id assigning AGV-id block-road xstart AGV-id])]
end

to block-road [xc id]
  let yc ycor
  if xc = "?"
  [ set xc xcor
    ask patches with [pxcor = xc - 1 and pycor = yc][ifelse meaning = "road-down" or meaning = "road-up" [set xc xc - 1][set xc xc + 1]]]
  ask patches with [pxcor = xc and pycor = yc]
  [ sprout-AGVs 1
    [ set size 0.9
      set color red
      set shape "dot"
      set availability 2
      set AGV-id id
      set status yc]]
end

to checking
  ask AGVs
  [if xcor = 0 or xcor = 35 [
    let destination_ destination let under-pod 0 let xc 0 let yc 0
    ask pods with [pod-id = destination_][set destination_ who set xc xcor set yc ycor]
    move-to turtle destination_ ]]
end

to resolve [who-id]
  let destination_ 0 let under-pod 0 let xc 0 let yc 0
  ask AGVs with [who = who-id]
  [ set destination_ destination
    ask pods with [pod-id = destination_][set destination_ who set xc xcor set yc ycor]
    ask patch-here [if meaning = "empty-space" or meaning = "podspace" [set under-pod 1]]
    if under-pod = 1 [ifelse xc = xcor and yc = ycor [ht][move-to turtle destination_ set path-status "arrive"]]]
end

to stay
  set count-down count-down - 1   ;decrement-timer
  if count-down = 0
    [
      move-to patch-ahead 0 lt 90
      not-collide
      set label ""
      reset-count-down
      reduce-qty carrying-pod-id
      set que-time time - q-time
      set status "bring-back"
      if path-status != "on-the-way"
      [ ask AGVs with [availability = 0]
        [pair-empty-loc AGV-id]
        assigning-empty]
    ]
end

to lead-time-count-down
  set rep-lead-time rep-lead-time - 1
  if rep-lead-time <= 0
  [ set rep-lead-time 100
    virtual-replenish pod-id]
end

to reset-count-down
  set count-down round(random-poisson 15)
  set label ""
end

to-report in-one-block? [id jobloc]
  let xjob 0 let yjob 0
  let n 0
  ask pods with [pod-id = jobloc] [set xjob xcor set yjob ycor]
  ask AGVs with [AGV-id = id]
  [ if ycor > 8 and ycor < 14 and yjob > 8 and yjob < 14 and abs(xcor - xjob) <= 4 [set n 1]
    if ycor > 14 and ycor < 20 and yjob > 14 and yjob < 20 and abs(xcor - xjob) <= 4 [set n 1]
    if ycor > 20 and ycor < 26 and yjob > 20 and yjob < 26 and abs(xcor - xjob) <= 4 [set n 1]
    if ycor > 26 and ycor < 32 and yjob > 26 and yjob < 32 and abs(xcor - xjob) <= 4 [set n 1]
    if ycor > 32 and ycor < 38 and yjob > 32 and yjob < 38 and abs(xcor - xjob) <= 4 [set n 1]]
  if n = 1 [report true]
  report false
end

to-report in-one-y-block? [id jobloc]
  let xjob 0 let yjob 0
  let n 0
  ask pods with [pod-id = jobloc] [set xjob xcor set yjob ycor]
  ask AGVs with [AGV-id = id]
  [ if ycor > 8 and ycor < 14 and yjob > 8 and yjob < 14 [set n 1]
    if ycor > 14 and ycor < 20 and yjob > 14 and yjob < 20 [set n 1]
    if ycor > 20 and ycor < 26 and yjob > 20 and yjob < 26 [set n 1]
    if ycor > 26 and ycor < 32 and yjob > 26 and yjob < 32 [set n 1]
    if ycor > 32 and ycor < 38 and yjob > 32 and yjob < 38 [set n 1]]
  if n = 1 [report true]
  report false
end

to-report rerouting? [id jobloc]
  let xjob 0 let yjob 0
  ask pods with [pod-id = jobloc] [set xjob xcor set yjob ycor]
  if not in-one-block? id jobloc and abs(ycor - yjob) = 1 [report true]
  report false
end

to-report going-further?
  if heading = 90 and xend < xcor and xcor != xstart and xcor != xend and ycor != ystart and ycor != yend [report true]
  if heading = 180 and xend > xcor and xcor != xstart and xcor != xend and ycor != ystart and ycor != yend [report true]
  report false
end

to-report turning?
  if straight-first = 1 and xcor = xstart and ycor = ystart [report false]
  if straight-first = 1 and xcor = xstart and ycor = ystart - 1 [report false]

;  if straight-first

  if u-turn = 3 and straight-first = 1 and ycor != yend [report false]

  if straight-first = 2 and ycor = yend and right-turn? [report true]

  ;direct manhattan
  if xcor = xstart and ycor != ystart and xcor != xend and ycor = yend and right-turn? and straight-first != 2 [report true]
  if xcor != xstart and ycor = ystart and xcor = xend and ycor != yend and right-turn? and straight-first != 2  [report true]
  if xcor = xstart and ycor = ystart and xcor != xend and ycor = yend and right-turn? and straight-first != 2  [report true]

  ;can't turn with direct manhattan, need to turn before reaching start&end point intersection
  if xcor = xstart and right-turn? [report true]
  if xcor = xend and right-turn? [report true]

  if xcor != xstart and ycor != ystart and xcor != xend and ycor = yend and right-turn? [report true]
  if xcor != xstart and ycor != ystart and xcor = xend and ycor != yend and right-turn? [report true]

  if u-turn = 4 and right-turn? and going-further? [report true]

  if corner? [report true]
  report false
end

to-report right-way? ;direct destination
  if heading = 0 and can-turn-left? and xcor > xend [report true]
  if heading = 0 and can-turn-right? and xcor < xend [report true]
  if heading = 90 and can-turn-left? and xcor < xend [report true]
  if heading = 90 and can-turn-right? and xcor > xend [report true]
  report false
end

to-report corner? ;corner warehouse
  if heading = 270 and xcor = 1 [report true]
  if heading = 90 and xcor = 34 [report true]
  if heading = 180 and ycor = 8 and xcor = 34 [report true]
  if heading = 0 and ycor = 38 and xcor = 1 [report true]
  if heading = 270 and xcor = 4 and ycor = 39 [report true]
  report false
end

to-report right-turn? ;compare heading, destination, and current location to make the right turn
  if heading = 180 and xcor < xend and can-turn-left? [report true] ;down
  if heading = 180 and xcor > xend and can-turn-right? [report true]
  if heading = 270 and ycor < yend and can-turn-right? [report true] ;left
  if heading = 270 and ycor > yend and can-turn-left? [report true]
  if heading = 0 and xcor < xend and can-turn-right? [report true] ;up
  if heading = 0 and xcor > xend and can-turn-left? [report true]
  if heading = 90 and ycor < yend and can-turn-left? [report true] ;right
  if heading = 90 and ycor > yend and can-turn-right? [report true]
  report false
end

to-report end-point?
  if xcor = xend and ycor = yend [report true]
  report false
end

to-report can-turn-right?
  if heading = 270 and xcor mod 2 = 1 [report true]
  if heading = 90 and xcor mod 2 = 0 [report true]
  if heading = 0 and abs(pycor) mod 4 = 2 [report true]
  if heading = 180 and abs(pycor) mod 4 = 0 [report true]
  if heading = 180 and pycor = 39 [report true]
  if meaning = "cornerintersection" [report true]
  report false
end

to-report can-turn-left?
  if heading = 270 and xcor mod 2 = 0 [report true]
  if heading = 90 and xcor mod 2 = 1 [report true]
  if heading = 0 and abs(pycor) mod 4 = 0 [report true]
  if heading = 180 and abs(pycor) mod 4 = 2 [report true]
  if heading = 0 and pycor = 39 [report true]
  if heading = 180 and pycor = 7 [report true]
  report false
end
@#$#@#$#@
GRAPHICS-WINDOW
180
28
656
635
-1
-1
13.0
1
10
1
1
1
0
1
1
1
0
35
0
45
0
0
1
ticks
30.0

INPUTBOX
726
35
887
95
Layout-file
layout set 2.csv
1
0
String

INPUTBOX
727
102
888
162
AGV-location-file
AGV set 1.csv
1
0
String

SLIDER
726
440
848
473
AGV-number
AGV-number
0
50
20.0
1
1
NIL
HORIZONTAL

BUTTON
35
62
98
95
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
726
234
887
294
Order-set
order set 1.csv
1
0
String

OUTPUT
912
32
1309
424
11

INPUTBOX
727
168
887
228
item-in-pod
pod set 1.csv
1
0
String

INPUTBOX
727
300
887
360
type-of-item
800.0
1
0
Number

INPUTBOX
727
365
888
425
sku-per-pod
2.0
1
0
Number

BUTTON
35
108
98
141
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
726
497
926
647
Throughput Rate
Hours
Items
0.0
50.0
0.0
500.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if time = 1 [plot 0] if time mod 3600 = 0 [plot finish-order]"

MONITOR
1375
511
1477
556
Stop & Go
stopping
17
1
11

MONITOR
1376
565
1477
610
Stopping in Que
Stop-Que
17
1
11

PLOT
938
498
1138
648
Robot Cycle Time
Task
Time
0.0
50.0
0.0
150.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "ask AGVs with [r-cycle-time != 0][plot r-cycle-time]"

PLOT
1150
499
1350
649
Robot Traveling Time
Task
Time
0.0
50.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "ask AGVs with [r-cycle-time != 0][plot r-cycle-time - que-time set que-time 0 set q-time 0  set r-cycle-time 0]"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

arrow1
true
0
Rectangle -7500403 true true 135 165 165 195
Rectangle -7500403 true true 135 105 165 135
Rectangle -7500403 true true 135 -15 165 15
Rectangle -7500403 true true 135 45 165 75
Polygon -7500403 true true 105 210 195 210 150 300

arrow2
true
0
Rectangle -7500403 true true 0 0 300 300
Polygon -1 true false 30 225 150 75 270 225 150 90

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

car top
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 true 210 165 195 165
Line -7500403 true 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

circle 3
true
0
Circle -7500403 true true 96 96 108

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

direction
true
0
Rectangle -7500403 true true 0 0 300 300
Polygon -16777216 true false 0 225 150 75 300 225 150 90

dot
false
0
Circle -7500403 true true 90 90 120

empty space
false
14
Rectangle -7500403 true false 0 0 300 345
Rectangle -7500403 true false 6 5 292 294
Rectangle -16777216 true true 14 13 284 285

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

full square
false
0
Rectangle -7500403 true true 0 0 300 345
Rectangle -16777216 true false 6 5 292 294
Rectangle -7500403 true true 14 13 284 285

fulll square 1
false
0
Rectangle -7500403 true true 8 8 294 292

highway
true
0
Rectangle -7500403 true true 0 0 300 300
Polygon -14835848 true false 0 225 150 75 300 225 150 90

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

int1
true
0
Rectangle -7500403 true true -60 135 15 165
Rectangle -7500403 true true 45 135 75 165
Rectangle -7500403 true true 105 135 135 165
Rectangle -7500403 true true 225 135 255 165
Rectangle -7500403 true true 165 135 195 165
Rectangle -7500403 true true 285 135 315 165
Polygon -7500403 true true 150 195 105 285 195 285

int2
true
0
Rectangle -7500403 true true 135 225 165 255
Rectangle -7500403 true true 255 135 285 165
Polygon -7500403 true true 165 105 165 195 75 150
Rectangle -7500403 true true 195 135 225 165
Rectangle -7500403 true true 135 285 165 315

int3
true
0
Rectangle -7500403 true true 135 45 165 75
Rectangle -7500403 true true 45 135 75 165
Polygon -7500403 true true 195 105 195 195 105 150
Rectangle -7500403 true true 135 -15 165 15
Rectangle -7500403 true true -15 135 15 165

int4
true
0
Rectangle -7500403 true true 225 135 255 165
Rectangle -7500403 true true 135 -15 165 15
Rectangle -7500403 true true 285 135 315 165
Rectangle -7500403 true true 135 225 165 255
Polygon -7500403 true true 105 135 195 135 150 45
Rectangle -7500403 true true 135 285 165 315
Rectangle -7500403 true true 135 165 165 195

int5
true
0
Rectangle -7500403 true true -60 135 15 165
Rectangle -7500403 true true 45 135 75 165
Rectangle -7500403 true true 105 135 135 165
Rectangle -7500403 true true 225 135 255 165
Rectangle -7500403 true true 165 135 195 165
Rectangle -7500403 true true 285 135 315 165
Polygon -7500403 true true 105 195 195 195 150 285

int6
true
0
Rectangle -7500403 true true 135 45 165 75
Rectangle -7500403 true true 255 135 285 165
Polygon -7500403 true true 165 105 165 195 75 150
Rectangle -7500403 true true 195 135 225 165
Rectangle -7500403 true true 135 -15 165 15

int7
true
0
Rectangle -7500403 true true 135 225 165 255
Rectangle -7500403 true true 45 135 75 165
Polygon -7500403 true true 195 105 195 195 105 150
Rectangle -7500403 true true -15 135 15 165
Rectangle -7500403 true true 135 285 165 315

int8
true
0
Rectangle -7500403 true true 135 45 165 75
Rectangle -7500403 true true 45 135 75 165
Polygon -7500403 true true 195 105 195 195 105 150
Rectangle -7500403 true true -15 135 15 165
Rectangle -7500403 true true 135 -15 165 15

int9
true
0
Rectangle -7500403 true true 45 135 75 165
Rectangle -7500403 true true 135 -15 165 15
Rectangle -7500403 true true -15 135 15 165
Rectangle -7500403 true true 135 225 165 255
Polygon -7500403 true true 105 135 195 135 150 45
Rectangle -7500403 true true 135 285 165 315
Rectangle -7500403 true true 135 165 165 195

kiva
true
0
Circle -16777216 true false 15 15 90
Circle -16777216 true false 195 15 90
Rectangle -955883 true false 45 195 255 285
Circle -955883 true false 15 195 90
Circle -955883 true false 195 195 90
Rectangle -16777216 true false 45 15 255 105
Rectangle -955883 true false 15 45 285 240
Polygon -7500403 true true 270 165 210 195 210 105 270 135
Polygon -7500403 true true 135 30 105 90 195 90 165 30
Polygon -7500403 true true 135 270 105 210 195 210 165 270
Polygon -7500403 true true 30 135 90 105 90 195 30 165
Polygon -7500403 true true 105 90 90 105 90 195 105 210 195 210 210 195 210 105 195 90
Circle -16777216 true false 105 105 90

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

road2
true
0
Rectangle -7500403 true true 0 0 300 300
Rectangle -1 true false 60 255 225 390

road3
true
0
Rectangle -7500403 false true 0 0 300 300

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

shelf
false
15
Rectangle -16777216 true false 0 0 300 300
Rectangle -1 true true 21 22 278 278
Rectangle -16777216 true false -304 24 -4 324
Rectangle -5825686 true false 30 159 270 264
Rectangle -5825686 true false 179 35 269 140
Rectangle -5825686 true false 31 35 166 140

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

station
true
0
Rectangle -7500403 true true 0 0 345 300
Rectangle -1 true false -15 75 315 150
Rectangle -1 true false -30 225 300 300

stripes
true
0
Rectangle -7500403 true true -60 135 15 165
Rectangle -7500403 true true 45 135 75 165
Rectangle -7500403 true true 105 135 135 165
Rectangle -7500403 true true 225 135 255 165
Rectangle -7500403 true true 165 135 195 165
Rectangle -7500403 true true 285 135 315 165

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tile water
false
0
Rectangle -7500403 true true -1 0 299 300
Polygon -1 true false 105 259 180 290 212 299 168 271 103 255 32 221 1 216 35 234
Polygon -1 true false 300 161 248 127 195 107 245 141 300 167
Polygon -1 true false 0 157 45 181 79 194 45 166 0 151
Polygon -1 true false 179 42 105 12 60 0 120 30 180 45 254 77 299 93 254 63
Polygon -1 true false 99 91 50 71 0 57 51 81 165 135
Polygon -1 true false 194 224 258 254 295 261 211 221 144 199

transparent
true
0

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.0-RC2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
