breed [people person]

;===================
people-own 
[
  openness
  current_emotion
  dominence
  energy_level
  gender
]

;===================
patches-own 
[
  emotion
  energy
]

;===================
globals 
[
  mydebug
  Monitored_Person_Gender ;populates the gender of the person being monitored by the graph
  Avg_Emotion ;populates the monitor with the global average emotion for the system
  emotion_range ;used for globally setting range - currently using 60
  open_range ;used for globally setting openness range - currently using 10
  Avg_Diff_Proximity ;populates the monitor with the global average of closest person's emotion - my emotion
  temp_closest ;temp var when calculating closest person
  energy_range ; used for globally setting range - currently using 10
  move_distance ;how far an agent can move each time - set to 1?
  dominence_range ;used for globally setting dominence range - currently using 10
  prev_monitor_person ;used to determine when to clear the graph
                      ; applied
  amIdebugging ; used to turn on/off debugging
]

;===================
to setup
  
  clear-all
  set-patch-size 13 ;5
  resize-world -16 16 -16 16;0 100 0 100
  set amIdebugging false
  set emotion_range 60
  set energy_range 10
  set open_range 10
  set dominence_range 10
  set move_distance Max_Move_Distance
  setup_patches
  let fem_num (Num_People * (100 - Percent_Male) / 100)
  let male_num (Num_People * (Percent_Male / 100))
  create-females fem_num
  create-males male_num
  do_plots
  
end

;===================
to setup_patches
  
  ask patches 
  [
    set emotion -1
    set energy -1
    set pcolor black
  ]
  
  ask n-of ((Percent_Patches_With_Emotion / 100) * count patches) patches 
  [ 
    set emotion random-float emotion_range ;need to adjust to only a subset of patches
    set energy random-float energy_range
    set pcolor get_color emotion 2
  ]
  
end

;===================
to create-females [mycount]
  
  create-people mycount 
  [
    set gender 0 ; means female
    let myrand random-float open_range
    ifelse ((myrand) + (myrand * Female_Openness / 100)) >= 10
    [ 
      set openness 10 
    ]
    [ 
      set openness ((myrand) + (myrand * Female_Openness / 100)) 
    ] ;try to set randomly and up it a little to ensure females' average is higher
    set shape "wperson"
    upd-generic
    if [who] of self = Monitored_Person_Num
    [      
      do_debug "Creating Female"
    ]
  ]
  
end

;===================
to create-males [mycount]
  
  create-people mycount 
  [
    set gender 1 ; means male
    set openness random-float open_range ; just set randomly?
    set shape "person"
    upd-generic
    if [who] of self = Monitored_Person_Num
    [
      do_debug "Creating Male"
    ]
  ]
  
end

;===================
to upd-generic
  set current_emotion random-float emotion_range
  set dominence random-float dominence_range
  set energy_level random-float energy_range
  set color get_color current_emotion 5
  setxy random-xcor random-ycor
  set heading random-float 360 
  set size 1;3
  if [who] of self = Monitored_Person_Num
  [      
    
    do_debug "Upd-generic"
  ]
end

;===================
;END SETUP METHODS
;===================

to go
  step
end

;===================
to step
  
  ask people 
  [
    ;move
    move_people
    let apply_emot [current_emotion] of self
    let apply_ener [energy_level] of self
    let apply_dom [dominence] of self
    let apply_open [openness] of self
    
    ;apply patch emotions!
    if not ([emotion] of patch-here = -1)
    [
      if [who] of self = Monitored_Person_Num
      [      
        
        do_debug word "Applying patch emotion of " [emotion] of patch-here
      ]
      match_emotion [emotion] of patch-here [energy] of patch-here
      
    ]
    
    ;change emotions if meet someone - randomly pick one of them
    ifelse any? other people-on patch-here ;if met someone, let's affect emotion
    [
      ;      set mydebug "Found Someone"   
      let myother one-of other people-on patch-here
      ask myother ;randomly pick one of the others
      [
        set apply_emot [current_emotion] of myother
        set apply_ener [energy_level] of myother
        set apply_dom [dominence] of myother
        set apply_open [openness] of myother
      ]
      if [who] of self = Monitored_Person_Num
      [      
        let temp word [who] of myother ";"
        set temp word temp apply_emot
        set temp word temp ";"
        set temp word temp apply_ener
        set temp word temp ";"
        set temp word temp apply_dom
        set temp word temp ";"
        set temp word temp apply_open
        set temp word temp " - "
        do_debug word "Applying one person's emotion: " temp
      ]
      apply_emotion apply_emot apply_ener apply_dom apply_open
      if [who] of self = Monitored_Person_Num
      [      
        
        do_debug "Applied one person's emotion: "
      ]
    ]
    [
      ;      set mydebug "No one here"
      if [who] of self = Monitored_Person_Num
      [      
        do_debug "No one here"
      ]
    ]
    
    ;random mutation of dominence & openness
    change_personal_params
    
    ;random mutation of emotion
    random_change_emotion
    
    ;random change in energy level of emotion
    change_energy_level
  ]
  
  ;update which patches have emotions & which emotions they have (along with energy)
  upd_patches
  
  tick
  
  ;create graphs
  do_plots
  
end

;===================
to move_people
  
  ;determine proximity flag
  ;determine range
  ;find people in range with closest
  ifelse any? other people in-cone Locality Angle 
  [
    ifelse (random 2 = 1) ;if "true" then move towards someone, else move randomly
    [
      ifelse (random 2 = 1) ; if "true" then move towards most like you, else happiest
      [
        ;move towards the most similar person
        let best findsimilar
        set heading towards best
        fd random-float distance best; move_distance
      ]
      [
        ;change heading to random person in-range
        let randpers one-of other people in-cone Locality Angle
        set heading towards randpers
        
        ;move towards them
        fd random-float distance randpers ;move_distance
      ]
    ]
    [
      set heading random-float 360
      fd random-float Max_Move_Distance
    ]
  ]
  [ ;no one within sight, so move randomly
    set heading random-float 360
    fd random-float Max_Move_Distance
  ]
  ;find all people closest to you within range / cone AND most similar to you
  
  ;change heading to go to them
  ;move towards them random amount
  
  
  
end

;===================
to change_energy_level
  ;should I only be going up/down up to 1 for this & only do more when applying emotions?
  ;update energy because time is passing
  let myrandom1 random-float (energy_range - energy_level)
  let myrandom2 random-float (energy_range)
  let myindicator random 3
  ifelse myindicator = 1; if "true" increase energy
  [
    ifelse (energy_level + myrandom1 >= energy_range)
    [
      set energy_level energy_range
    ]
    [
      set energy_level ( energy_level + myrandom1)
    ]
  ]; else if 2 decrease energy, but if 0, do nothing
  [
    if myindicator = 2
    [
      ifelse (energy_level - myrandom2 <= 0)
      [
        set energy_level 0
      ]
      [
        set energy_level ( energy_level - myrandom2)
      ]
    ]
  ]
  
end

;===================
to apply_emotion [myemot myenergy mydom myopen] 
  
  let applied false
  let dom_diff (mydom - [dominence] of self)
  let ener_diff (myenergy - [energy_level] of self)
  let emot_diff (myemot - [current_emotion] of self)
  
  let rand_dom random-float dom_diff
  let rand_ener random-float 1
  let rand_emot random-float 1
  let rand_open random-float 1
  
  if Dominence_Toggle = true ;only apply dominence if turned on
  [
    if (dom_diff > 0) ;if the other person is more dominant then we're going to affect this person more likely
    [
      if (random-float dominence_range < rand_dom) ;randomly affect someone more likely for greater difference in dominence
      [
        if [who] of self = Monitored_Person_Num
        [
          let temp word myemot ":"
          set temp word temp myenergy
          set temp (word temp " " mydom " " dom_diff " " [dominence] of self " ")
          do_debug word "Applying for dominence with emot:ener mydom dom_diff dom_self " temp
        ]
        match_emotion myemot myenergy ;match emotion (but not exactly)
        if [who] of self = Monitored_Person_Num
        [
          do_debug  "Applied dominence"
        ]
        set applied true
      ]
    ]
  ]
  if Openness_Toggle = true ; only apply openness if turned on
  [
    if (random-float open_range < [openness] of self)
    [
      if (random-float open_range < rand_open)
      [
        if not applied
        [
          if [who] of self = Monitored_Person_Num
          [
            let temp word myemot ":"
            set temp word temp myenergy
            set temp (word temp " " [openness] of self " ")
            do_debug word "Applying for openness with emot:ener self_open " temp
          ]
          match_emotion myemot myenergy
          if [who] of self = Monitored_Person_Num
          [
            do_debug "Applied openness"
          ]
          
          set applied true
        ]
      ]
    ]
  ]
  if (ener_diff > 0)
  [
    if (random-float energy_range < rand_ener)
    [
      if not applied
      [
        if [who] of self = Monitored_Person_Num
        [
          let temp word myemot ":"
          set temp word temp myenergy
          set temp (word temp " " ener_diff " " myenergy " " [energy_level] of self " ")
          do_debug word "Applying for energy with emot:ener ener_diff myener self_ener " temp
        ]
        match_emotion myemot myenergy
        if [who] of self = Monitored_Person_Num
        [
          do_debug "Applied energy"
        ]
        
        set applied true
      ]
    ]
  ]
  if (emot_diff < 0) ; if they're more negative than I am then I'm more likely to match them
  [
    if (random-float emotion_range < rand_emot)
    [
      if not applied
      [
        if [who] of self = Monitored_Person_Num
        [
          let temp word myemot ":"
          set temp word temp myenergy
          set temp (word temp " " emot_diff " " [current_emotion] of self " ")
          do_debug word "Applying for emotion difference with emot:ener emot_diff emot_self " temp
        ]
        match_emotion myemot myenergy
        if [who] of self = Monitored_Person_Num
        [
          do_debug "Applied difference"
        ]
        set applied true
      ]
    ]
  ]
  
  ; upd color
  set color get_color [current_emotion] of self 5
  
end

;===================
to match_emotion [myemotion myenergy]
  
  let my_diff random-float (myemotion - [current_emotion] of self)
  if ([current_emotion] of self + my_diff > emotion_range)
  [
    set current_emotion emotion_range
    if [who] of self = Monitored_Person_Num
      [
        do_debug (word "Matching with max value " myemotion " " myenergy " " my_diff " myemotion myenergy mydiff ")
      ]
  ]
  if ([current_emotion] of self + my_diff < 0)
  [
    set current_emotion 0.01
    if [who] of self = Monitored_Person_Num
      [
        do_debug  (word "Matching with min value " myemotion " " myenergy " " my_diff " myemotion myenergy mydiff ")
      ]
  ]
  if (([current_emotion] of self + my_diff >= 0 ) and ([current_emotion] of self + my_diff <= emotion_range))
  [
    set current_emotion ([current_emotion] of self + my_diff)
    if [who] of self = Monitored_Person_Num
      [
        do_debug  (word "Matching with middle value " myemotion " " myenergy " " my_diff " myemotion myenergy mydiff ")
      ]
  ]
  
end

;===================
to change_personal_params 
  
  ;update openness by mutation only
  let myrandom1 random-float (open_range - openness)
  let myrandom2 random-float (open_range)
  let myindicator random 100
  if myindicator < Percent_Mutation_of_Openness ; if "true" change openness
  [
    let myindicator5 random 3
    ifelse (myindicator5 = 1) ; if "true" increase openness
    [
      ifelse (openness + myrandom1 >= open_range)
      [
        set openness open_range
      ]
      [
        set openness ( openness + myrandom1)
      ]
    ]; else if 2 decrease openness, but if 0, do nothing
    [
      if myindicator = 2
      [
        ifelse (openness - myrandom2 <= 0)
        [
          set openness 0
        ]
        [
          set openness ( openness - myrandom2)
        ]
      ]
    ]
  ]
  
  ;update dominence by mutation only
  let myrandom3 random-float (dominence_range - dominence)
  let myrandom4 random-float (dominence_range)
  let myindicator2 random 100
  if myindicator2 < Percent_Mutation_of_Dominence ; if "true" change dominence
  [
    let myindicator6 random 3
    ifelse(myindicator6 = 1) ; if "true" increase dominence
    [
      ifelse (dominence + myrandom3 >= dominence_range)
      [
        set dominence dominence_range
      ]
      [
        set dominence ( dominence + myrandom3)
      ]
    ]; else if 2 decrease openness, but if 0, do nothing
    [
      if myindicator2 = 2
      [
        ifelse (dominence - myrandom4 <= 0)
        [
          set dominence 0
        ]
        [
          set dominence ( dominence - myrandom4)
        ]
      ]
    ]
  ]
  
end

;===================
to random_change_emotion 
  
  ;update emotion by mutation only
  let myrandom1 random-float (emotion_range - current_emotion)
  let myrandom2 random-float (emotion_range)
  let myindicator random 100
  if myindicator < Percent_Mutation_of_Emotions ; if "true" change emotion
  [
    let myindicator2 random 3
    ifelse (myindicator2 = 1) ; increase emotion
    [
      ;      set mydebug word mydebug  " - Mutation"
      ifelse (current_emotion + myrandom1 >= emotion_range)
      [
        ; output-print "Mutated with greater than emotion_range"
        set current_emotion emotion_range
        if [who] of self = Monitored_Person_Num
        [
          do_debug "Random Mutate Max"
        ]
      ]
      [
        set current_emotion ( current_emotion + myrandom1)
        if [who] of self = Monitored_Person_Num
        [
          do_debug "Random Mutate Up"
        ]
      ]
    ]; else if 2 decrease openness, but if 0, do nothing
    [
      if myindicator2 = 2
      [
        ifelse (current_emotion - myrandom2 <= 0)
        [
          set current_emotion 0.01
          if [who] of self = Monitored_Person_Num
          [
            do_debug "Random Mutate Min"
          ]
        ]
        [
          set current_emotion ( current_emotion - myrandom2)
          if [who] of self = Monitored_Person_Num
          [
            do_debug "Random Mutate Down"
          ]
        ]
      ]
    ]
  ]
  
end

;===================
to upd_patches
  
  setup_patches
  
end

;===================
to invoke_event
  
  ;check for event mood
  let ev_val get_val Event_Emotion
  
  ;invoke for all people
  ask people 
  [
    
    if random-float 10 <= Event_Energy ;randomly decide whether to affect the person based on the energy of the emotion
    [
      let chg random (ev_val - current_emotion) ; will give negative if myval is less than my current emotion
      ifelse (current_emotion + chg >= emotion_range) 
      [
        set current_emotion emotion_range
        if [who] of self = Monitored_Person_Num
        [
          do_debug "Applying event Max"
        ]
      ]
      [
        ifelse (current_emotion + chg <= 0)
        [
          set current_emotion 0.01
          if [who] of self = Monitored_Person_Num
          [
            do_debug "Applying event Min"
          ]
        ]
        [
          set current_emotion current_emotion + chg
          if [who] of self = Monitored_Person_Num
          [
            do_debug "Applying event"
          ]
        ]
      ]
    ]
    
    ; upd color
    set color get_color current_emotion 5
    insert_plot_line ;ev_val Event_Emotion
  ]
  
end

;======================
;END RUN METHODS
;
;START REPORTER METHODS
;======================

to-report get_pen_color[mynum]
  ifelse mynum > 50 [
    report yellow ;reset to range of 42-49 - yellow - Joy
  ][
  ifelse mynum > 40 [
    report magenta ;reset to range of 122-129 - magenta/purple - Love
  ][
  ifelse mynum > 30 [
    report brown ;reset to range of 32-39 - brown - Ambivalence
  ][
  ifelse mynum > 20 [
    report blue ;reset to range of 102-109 - blue - Sadness
  ][
  ifelse mynum > 10 [
    report green ;reset to range of 52-59 - green - Fear
  ][
  ifelse mynum >= 0 [
    report red ;reset to range of 12-19 - red - Anger
  ][
  report black ;UNKNOWN - gray
  ]]]]]]
  
end

;===================
to-report findsimilar 
  
  ;grab any one person in sight to start with
  let best one-of other people in-cone Locality Angle
  ;store the emotion of "self"
  let mycompare current_emotion
  
  ;ask each person in sight to see if they're more similar than the current best
  ask other people in-cone Locality Angle
  [
    if abs (current_emotion - mycompare) < [current_emotion] of best
    [
      set best self
    ]
  ]
  
  ;return the most similar person in-sight
  report best
  
end

;===================
to-report get_string [myval]
  
  
  ifelse (myval > 50 and myval <= 60)
  [
    report "Joy"
  ][
  ifelse (myval > 40 and myval <= 50)
  [
    report "Love"
  ][
  ifelse (myval > 30 and myval <= 40)
  [
    report "Ambivalence"
  ][
  ifelse (myval > 20 and myval <= 30)
  [
    report "Sadness"
  ][
  ifelse (myval > 10 and myval <= 20)
  [
    report "Fear"
  ][
  ifelse (myval >= 0 and myval <= 10)
  [
    report "Anger"
  ][
  report "Unknown"
  ]]]]]]
  
end

;===================
to-report get_val[mystring]
  
  ;used ONLY for applying event emotion with some "randomness" on the level of emotion
  ifelse mystring = "Joy" 
  [
    report random-float 10 + 50
  ]
  [
    ifelse mystring = "Love" 
    [
      report random-float 10 + 40
    ]
    [
      ifelse mystring = "Sadness" 
      [
        report random-float 10 + 20
      ]
      [
        ifelse mystring = "Fear" 
        [
          report random-float 10 + 10
        ]
        [
          ifelse mystring = "Ambivalence" 
          [
            report random-float 10 + 30
          ]
          [
            ifelse mystring = "Anger" 
            [
              report random-float 10
            ]
            [
              report -1
            ]
          ]
        ]
      ]
    ]
  ]
  
end

;===================
to-report get_color[mynum incr]
  ifelse mynum > 50 [
    report 40 + incr ;reset to range of 42-49 - yellow - Joy
  ][
  ifelse mynum > 40 [
    report 120 + incr ;reset to range of 122-129 - magenta/purple - Love
  ][
  ifelse mynum > 30 [
    report 30 + incr ;reset to range of 32-39 - brown - Ambivalence
  ][
  ifelse mynum > 20 [
    report 100 + incr ;reset to range of 102-109 - blue - Sadness
  ][
  ifelse mynum > 10 [
    report 50 + incr ;reset to range of 52-59 - green - Fear
  ][
  ifelse mynum >= 0 [
    report 10 + incr ;reset to range of 12-19 - red - Anger
  ][
  ifelse (incr = 2)
  [
    report black
  ]
  [
    ifelse (incr = 8)
    [
      report white
    ]
    [
      report incr
    ]
  ] ;UNKNOWN - gray
  ]]]]]]
  
end

;======================
;END REPORTER METHODS
;
;START PLOT METHODS
;======================

to do_plots
  
  ;gender_count
  ;mood_bar
;  do_emotion_counts
  ;average emotion
  set Avg_Emotion get_string mean [current_emotion] of people
  get_average
  do_avg_emotions
  do_emotion_counts_hist
  ;average closest proximity
  do_avg_closest
  ;average difference in emotion to closest proximity
  do_avg_prox_emotion
  ;counts of patch emotions affecting people
  do_patch_counts
  ;counts of global emotions used
  
  ;graph one person's emotions over time
  do_one_person_emotions
  
end

;===================
to get_average
  let joycount count people with [color > 40 and color < 50]
  let lovecount count people with [color > 120 and color < 130]
  let Ambivalencecount count people with [color > 30 and color < 40]
  let sadcount count people with [color > 100 and color < 110]
  let fearcount count people with [color > 50 and color < 60]
  let angercount count people with [color > 10 and color < 20]
  let unknown count people with [(get_string current_emotion) = "Unknown"]
  ;use 1 for anger, 2 for fear, 3 for sad, 4 for Ambivalence, 5 for love, 6 for joy, 0 for unknown
  let average ((angercount) + (fearcount * 2) + (sadcount * 3) + (Ambivalencecount * 4) + (lovecount * 5) + (joycount * 6)) / (count people)
  let mystring "Unknown"
  
end

;===================
to do_emotion_counts
  
  set-current-plot "Emotion_Counts"
  set-current-plot-pen "Joy"
  plot count people with [color > 40 and color < 50] ;yellow
  set-current-plot-pen "Love"
  plot count people with [color > 120 and color < 130] ;magenta
  set-current-plot-pen "Ambivalence"
  plot count people with [color > 30 and color < 40] ;brown
  set-current-plot-pen "Sadness"
  plot count people with [color > 100 and color < 110] ;blue
  set-current-plot-pen "Fear"
  plot count people with [color > 50 and color < 60] ;green
  set-current-plot-pen "Anger"
  plot count people with [color > 10 and color < 20] ;red
  
end

;===================
to do_avg_closest ; *************************************FIX**********************************
  let mylist []
  ask people [
    
    let closestpers self
    ask min-one-of people in-cone Locality Angle [sqrt (((xcor - [xcor] of closestpers) * (xcor - [xcor] of closestpers)) + ((ycor - [ycor] of closestpers) * (ycor - [ycor] of closestpers)))]
    [
      ;do difference
      let mydiff abs ([current_emotion] of closestpers - [current_emotion] of self)
      ;add value to the list
      set mylist lput mydiff mylist
    ]
  ]
  set Avg_Diff_Proximity mean mylist
end

;===================
to do_avg_prox_emotion 
  
  set-current-plot "Average_Proximity"
  set-current-plot-pen "default"
  
  let mytotal 0
  ask people [
    set mytotal (mytotal + distance min-one-of other people [distance myself])
  ]
  set mytotal mytotal / count people
  
  plot mytotal
  
  let myval (get_string mean [ mean [ current_emotion] of people in-radius Locality] of people)
  
end

;====================
to do_patch_counts
  
  set-current-plot "Emotion_Counts"
  let total 0
  set-current-plot-pen "Joy"
  plot-pen-up plotxy ticks total
  set total total  + count people with [current_emotion > 50 and current_emotion <= 60] ;yellow
  plot-pen-down plotxy ticks total
  set-current-plot-pen "Love"
  plot-pen-up plotxy ticks total
  set total total + count people with [current_emotion > 40 and current_emotion <= 50] ;magenta
  plot-pen-down plotxy ticks total
  set-current-plot-pen "Ambivalence"
  plot-pen-up plotxy ticks total
  set total total + count people with [current_emotion > 30 and current_emotion <= 40] ;brown
  plot-pen-down plotxy ticks total
  set-current-plot-pen "Sadness"
  plot-pen-up plotxy ticks total
  set total total + count people with [current_emotion > 20 and current_emotion <= 30] ;blue
  plot-pen-down plotxy ticks total
  set-current-plot-pen "Fear"
  plot-pen-up plotxy ticks total
  set total total + count people with [current_emotion > 10 and current_emotion <= 20] ;green
  plot-pen-down plotxy ticks total
  set-current-plot-pen "Anger"
  plot-pen-up plotxy ticks total
  set total total + count people with [current_emotion >= 0 and current_emotion <= 10] ;red
  plot-pen-down plotxy ticks total
  set-current-plot-pen "Unknown"
  plot-pen-up plotxy ticks total
  set total total + count people with [color = black] ;brown
  plot-pen-down plotxy ticks total
  
  
end

;===================
to do_one_person_emotions
  
  set-current-plot "One_Person_Emotion"
  
  ifelse (prev_monitor_person = Monitored_Person_Num)
  [
    ifelse (ticks < 475)
    [
      set-plot-x-range 0 500
    ]
    [
      set-plot-x-range (ticks - 475) (ticks + 25)
    ]
  ]
  [
    set prev_monitor_person  Monitored_Person_Num
    clear-plot
    set-plot-x-range ticks ticks + 500
  ]
  let mypers one-of people with [who = Monitored_Person_Num]
  let myval [current_emotion] of mypers
  
  ask mypers
  [
    if (any? other people-on patch-here)
    [
      set-current-plot-pen "Interaction"
      set-plot-pen-color black
      set-plot-pen-mode 2
      set-plot-pen-interval 4
      plot-pen-down
      plotxy ticks [current_emotion] of mypers
      plot-pen-up
    ]
  ]
  set-current-plot-pen "Unknown"
  set-plot-pen-color get_pen_color myval
  
  
  plotxy ticks [current_emotion] of mypers
  set-current-plot-pen "Joy"
  set-current-plot-pen "Love"
  set-current-plot-pen "Ambivalence"
  set-current-plot-pen "Sadness"
  set-current-plot-pen "Fear"
  set-current-plot-pen "Anger"
  set-current-plot-pen "Unknown"
  
  ifelse ([gender] of mypers = 1)
  [  
    set Monitored_Person_Gender "male"
  ]
  [
    set Monitored_Person_Gender "female"
  ]
  
end


;===================
to do_avg_emotions
  
  set-current-plot "Average_Emotion"
  
  
  let myval ( mean [current_emotion] of people )
  
  set-current-plot-pen "Unknown"
  set-plot-pen-color get_pen_color myval
  
  
  plot myval
  set-current-plot-pen "Joy"
  set-current-plot-pen "Love"
  set-current-plot-pen "Ambivalence"
  set-current-plot-pen "Sadness"
  set-current-plot-pen "Fear"
  set-current-plot-pen "Anger"
  set-current-plot-pen "Unknown"
  
  
end

;===================
to insert_plot_line
  set-current-plot "Average_Emotion"
  set-current-plot-pen "Event"
  plot-pen-up
  plotxy ticks 0
  plot-pen-down
  plotxy ticks plot-y-max
  plot-pen-up
  
  set-current-plot "One_Person_Emotion"
  set-current-plot-pen "Event"
  plot-pen-up
  plotxy ticks 0
  plot-pen-down
  plotxy ticks plot-y-max
  plot-pen-up
  
  
  
end

to do_emotion_counts_hist
  set-current-plot "Emotion Counts"
  clear-plot
  set-current-plot-pen "Joy"
  set-plot-pen-mode 1
  set-plot-pen-interval 5
  plot-pen-up
  plotxy 3 0
  plot-pen-down
  plotxy 3 count people with [get_string current_emotion = "Joy"]
  plot-pen-up
  set-current-plot-pen "Love"
  set-plot-pen-mode 1
  set-plot-pen-interval 5
  plot-pen-up
  plotxy 10 0
  plot-pen-down
  plotxy 10 count people with [get_string current_emotion = "Love"]
  plot-pen-up
  
  set-current-plot-pen "Ambivalence"
  set-plot-pen-mode 1
  set-plot-pen-interval 5
  plot-pen-up
  plotxy 17 0
  plot-pen-down
  plotxy 17 count people with [get_string current_emotion = "Ambivalence"]
  plot-pen-up
  
  set-current-plot-pen "Sadness"
  set-plot-pen-mode 1
  set-plot-pen-interval 5
  plot-pen-up
  plotxy 24 0
  plot-pen-down
  plotxy 24 count people with [get_string current_emotion = "Sadness"]
  plot-pen-up
  
  set-current-plot-pen "Fear"
  set-plot-pen-mode 1
  set-plot-pen-interval 5
  plot-pen-up
  plotxy 31 0
  plot-pen-down
  plotxy 31 count people with [get_string current_emotion = "Fear"]
  plot-pen-up
  
  set-current-plot-pen "Anger"
  set-plot-pen-mode 1
  set-plot-pen-interval 5
  plot-pen-up
  plotxy 38 0
  plot-pen-down
  plotxy 38 count people with [get_string current_emotion = "Anger"]
  plot-pen-up
  
  set-current-plot-pen "Unknown"
  set-plot-pen-mode 1
  set-plot-pen-interval 5
  plot-pen-up
  plotxy 45 0
  plot-pen-down
  plotxy 45 count people with [get_string current_emotion = "Unknown"]
  plot-pen-up
  
  
end

to do_debug [printvalue]
  
  if amIdebugging
  [
    
    ask one-of people with [who = Monitored_Person_Num]
    [
      let temp word "Tick # " ticks
      set temp word temp " - "
      set temp word temp printvalue
      set temp word  temp " "
      file-print word temp [current_emotion] of self
      output-print word temp [current_emotion] of self
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
265
10
704
470
16
16
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
-16
16
-16
16
0
0
1
ticks

BUTTON
10
10
74
43
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
85
10
174
43
Step Once
step
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
184
10
247
43
Run
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

INPUTBOX
163
53
248
113
Num_People
100
1
0
Number

SLIDER
200
120
233
295
Percent_Male
Percent_Male
0
100
46
1
1
NIL
VERTICAL

SWITCH
10
180
150
213
Dominence_Toggle
Dominence_Toggle
0
1
-1000

SWITCH
10
215
150
248
Openness_Toggle
Openness_Toggle
0
1
-1000

SLIDER
10
390
245
423
Percent_Patches_With_Emotion
Percent_Patches_With_Emotion
0
100
10
.1
1
NIL
HORIZONTAL

SLIDER
10
305
235
338
Locality
Locality
0
26
4
1
1
NIL
HORIZONTAL

SLIDER
10
425
245
458
Percent_Mutation_of_Emotions
Percent_Mutation_of_Emotions
0
10
1
.01
1
NIL
HORIZONTAL

BUTTON
10
135
149
168
Invoke Emotional Event
invoke_event
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

CHOOSER
9
52
147
97
Event_Emotion
Event_Emotion
"Joy" "Love" "Neutral" "Sadness" "Fear" "Anger"
5

SLIDER
9
100
148
133
Event_Energy
Event_Energy
0
10
6
1
1
NIL
HORIZONTAL

SLIDER
10
260
182
293
Female_Openness
Female_Openness
0
50
10
.1
1
NIL
HORIZONTAL

PLOT
1015
10
1215
165
Emotion_Counts
Time
Count of Patches
0.0
60.0
0.0
10.0
true
true
PENS
"Joy" 1.0 0 -1184463 true
"Love" 1.0 0 -5825686 true
"Ambivalence" 1.0 0 -6459832 true
"Sadness" 1.0 0 -13345367 true
"Fear" 1.0 0 -10899396 true
"Anger" 1.0 0 -2674135 true
"Unknown" 1.0 0 -16777216 true

PLOT
495
480
695
645
Average_Proximity
Time
Average Proximity
0.0
60.0
0.0
5.0
true
false
PENS
"default" 1.0 0 -16777216 false

MONITOR
1025
195
1132
240
Average Emotion
Avg_Emotion
17
1
11

SLIDER
10
340
235
373
Angle
Angle
0
360
180
1
1
NIL
HORIZONTAL

PLOT
720
330
1000
480
One_Person_Emotion
Time
Emotion
0.0
50.0
0.0
60.0
true
true
PENS
"Joy" 1.0 0 -1184463 true
"Love" 1.0 0 -5825686 true
"Ambivalence" 1.0 0 -6459832 true
"Sadness" 1.0 0 -13345367 true
"Fear" 1.0 0 -10899396 true
"Anger" 1.0 0 -2674135 true
"Unknown" 1.0 0 -16777216 false
"Event" 1.0 0 -2064490 false
"Interaction" 1.0 2 -16777216 false

INPUTBOX
1010
345
1162
405
Monitored_Person_Num
5
1
0
Number

SLIDER
10
460
245
493
Percent_Mutation_of_Dominence
Percent_Mutation_of_Dominence
0
10
1
.01
1
NIL
HORIZONTAL

SLIDER
10
495
247
528
Percent_Mutation_of_Openness
Percent_Mutation_of_Openness
0
10
1
.01
1
NIL
HORIZONTAL

PLOT
720
165
1000
325
Average_Emotion
Time
Average Emotion
0.0
10.0
0.0
60.0
true
true
PENS
"Joy" 1.0 0 -1184463 true
"Love" 1.0 0 -5825686 true
"Ambivalence" 1.0 0 -6459832 true
"Sadness" 1.0 0 -13345367 true
"Fear" 1.0 0 -10899396 true
"Anger" 1.0 0 -2674135 true
"Unknown" 1.0 0 -16777216 false
"Event" 1.0 0 -2064490 false

PLOT
720
10
1000
160
Emotion Counts
 Joy   Luv Amb  Sad  Fear Mad Unk
Count
0.0
55.0
0.0
50.0
true
true
PENS
"Joy" 1.0 0 -1184463 true
"Love" 1.0 0 -5825686 true
"Ambivalence" 1.0 0 -6459832 true
"Sadness" 1.0 0 -13345367 true
"Fear" 1.0 0 -10899396 true
"Anger" 1.0 0 -2674135 true
"Unknown" 1.0 0 -16777216 true

MONITOR
1010
415
1167
460
NIL
Monitored_Person_Gender
17
1
11

SLIDER
315
495
487
528
Max_Move_Distance
Max_Move_Distance
0
10
4
1
1
NIL
HORIZONTAL

@#$#@#$#@
WHAT IS IT?
-----------
This tries to model the concept of Emotional Contagion.  This is a theory of how moods & emotions affect us.  It implies that each of us have the ability to “infect” others with our own emotions, depending on the emotion, the energy level of the emotion being presented, and how open we are to receive / transmit feelings.  The tendency is for the masses to copy each other’s behaviors and emotions.  Managers & team leaders or other people with dominance roles tend to be more contagious with their emotions than others.  Women tend to be the recipient of this contagion effect more often than men.  And, overall, people tend to be attracted to similar emotions as they are feeling.

From Wikipedia on Emotional Contagion:
--------------------------------------
Emotional contagion is the tendency to catch and feel emotions  that are similar to and influenced by those of others. One view developed by John Cacioppo of the underlying mechanism is that it represents a tendency to automatically mimic and synchronize facial expressions, vocalizations, postures, and movements with those of another person and, consequently, to converge emotionally.[1]  A broader definition of the phenomenon was suggested by Sigal G. Barsade—"a process in which a person or group influences the emotions or behavior of another person or group through the conscious or unconscious induction of emotion states and behavioral attitudes".

Emotional contagion may be involved in mob psychology crowd behaviors, like collective fear, disgust, or moral outrage, but also emotional interactions in smaller groups such as work negotiation, teaching and persuasion/propaganda  contexts. It is also the phenomenon when a person (especially a child) appears distressed because another person is distressed, or happy because they are happy. The ability to transfer moods appears to be innate in humans. Emotional contagion and empathy have an interesting relationship; for without an ability to differentiate between personal and pre-personal experience (see individuation), they appear the same. In The Art of Loving, Erich Fromm explores the autonomy necessary for empathy which is not found in contagion. Fromm extolled the virtues of humans taking independent action and using reason to establish moral values rather than adhering to authoritarian moral values.[clarification needed] Recognizing emotions and acknowledging their cause can be one way to avoid emotional contagion. Transfers of emotions have been studied in different situations and settings. Social and physiological causes are the two largest areas of research.

In addition to the social contexts discussed above, emotional contagion is a concept that has been studied within organizations. In their examination of the three institutions that rape work is performed in, Schrock, Leaf, and Rohr (2008) discuss that organizations, like societies, have emotion cultures that consist of languages, rituals, and meaning systems, including rules about the feelings workers should, and should not, feel and display. They state that the concept of emotion culture is quite similar to the notion of "emotion climate" (p. 46), which has also been synonymously referred to as morale, organizational morale, and corporate morale.[citation needed] Furthermore, Worline, Wrzesniewski, and Rafaeli (2002) make mention that organizations have an overall "emotional capability" (p. 318), while McColl-Kennedy and Smith (2006) examine the concept of "emotional contagion" (p. 255) specifically in customer interactions. These terms are arguably all attempting to describe a similar phenomenon; each term is different from one another in subtle and somewhat indistinguishable ways. Future research might consider where and how the meanings of these terms intersect, as well as how they differ.


HOW IT WORKS
------------
Agents are initially created as either male or female.  They are also given (randomly) different current emotions, energy of that emotion, a dominence / ranking within the society, and a scale of their openness to others' emotions.  Women are given a more likely openness rating than men, based on the slider for the system.  Patches are randomly given an emotion to represent a localized "event" that could impact a person's emotions.

As the system runs, the agents move around the world randomly, but will look for people with "similar" emotions within their visible range to move towards if possible, or will move towards the happiest people they can see.  If they bump into another agent, OR land on a patch that is currently hosting a random emotion, they will be randomly impacted to change their current emotion because of that event or interaction.  

Certain criteria can be turned on/off for determining the effects of an interaction / event, including dominence and openness.  Global events can be invoked with a specific emotion to simulate things such as "9/11" or other society-wide events.

Their dominence vs the other agent's dominence rating will affect how likely they are to adjust to the other's emotion (the greater the difference of their dominence ratings & the higher the other agent's rating is, the more likely they are to align closely with the other agent's emotion).  Their openness to change will also affect how likely they are to take on the other agent's emotions.  And finally, the energy that the patch or other agent is evoking the emotion with will affect the likelihood of modifying their emotion.


HOW TO USE IT
-------------
- Setup button - resets the world & creates the agents, their attributes, and patches, initialized
- Step Once button - runs one tick of events
- Run button - runs step continually
- Num_People - identifies how many people to create in the world (only applied when you click Setup)
- Event_Emotion - drop down to choose the emotion to incur when you click the Invoke Event button (only applied upon clicking Invoke Event button)
- Event_Energy - slider to choose a value from 0-10 for how strongly the emotion should be evoked when you click the Invoke Event button (only applied upon clicking Invoke Event button)
- Invoke Event button - Invokes an event of Event_Emotion & Event_Energy to all the agents in the system
- Percent_Male - slider to choose percentage of male vs female agents to create (only applied when you click Setup)
- Dominence_Toggle - turns on / off the effects of the dominence trait in the system for applying emotions upon interactions & events
- Openness_Toggle - turns on / off the effects of the openness trait in the system for applying emotions upon interactions & events
- Percent_Patches_With_Emotion - determines what percentage of patches should represent a local emotional event (is applied with each tick)
- Percent_Mutation_of_Emotions - determines what percentage of agents at each tick should randomly "mutate" their emotion, regardless of whether there is any interaction or event incurred
- Locality - determines how far away an agent can see, in order to look for another agent with similar emotions to move towards
- Angle - determines the visible arc in front of a person (ie peripheral vision) that they can see, in order to look for another agent with similar emotions to move towards
- Max_Move_Distance - maximum distance that an agent can move on one tick (although it is a random amount up to that distance)
- Female_Openness - Used to determine how much more likely women are to be open than men (only applied when you click Setup)
- Percent_Mutation_Dominence - determines what percentage of agents at each tick should randomly "mutate" their dominence, to simulate rises & falls of hierarchy
- Percent_Mutation_Openness - determines what percentage of agents at each tick should randomly "mutate" their openness, to simulate changes due to experiences

GRAPHS
- Monitored_Person_Num - who # of the person you want to monitor the emotions for (will clear graph if you change this mid-run)
- Monitored_Person_Gender - gender of the person with who = Monitored_Person_Num
- One_Person_Emotion Graph - graph of the monitored person's emotion over time - vertical pink lines are global events that are occurring, and black dots are when the agent is interacting with another agent
- Average_Emotion Graph - graph of the average emotion of all agents over time - vertical pink lines are global events that area occurring
- Average_Emotion - shows the name of the average emotion of all agents currently
- Emotion_Counts Graph - shows a bar graph of all agents bucketed into their emotions
- Average_Proximity Graph - shows how close agents are to each other (closest agent is used)
--->Need to add one for how similar (on average) each agent is to their closest neighbor

THINGS TO NOTICE
----------------
If you increase the visibility range for the agents, you'll notice that they flock together.  Lower visibility ranges do not cause any flocking.

Also, if you invoke an event, not all people are affected, it may take several invokations in order to get everyone to align with that event's mood.

A single person's emotions can vary drastically & spike from one extreme to the other.  This may be due to the patches having events & affecting the person.

If you set Locality = 7 & Angle = 360, you can get clusterings of people (I got 4 clusters based upon the point in time where I made the change from a previously started run).  This clustering merged into 3 groups after running a little longer with the same settings & when run long enough, incurred a single clustering of agents.  However, this occurred primarily when a bug was in the system which spiked people to the extreme emotions.

Looking at the distribution of emotions in the system, you'll notice they follow a relatively bell-shaped distribution, meaning we have more people with middle-ground to neutral emotions most of the time.


THINGS TO TRY
-------------
- Turn on / off the dominence or openness attributes from affecting the agents.
- Invoke different global emotional events (in rapid sequence, differing emotions, etc)
- Change the locality / angle of visibility for each agent (Angle = 360 means they can see all around them, Locality = 26 means they can see the entire board)
- Modify the world to allow or disallow wrapping


EXTENDING THE MODEL
-------------------
- Might want to try allowing opposing emotions
- Different application of emotions which applies all components in one decision
- Use the energy of the emotion to trigger amount of change
- Allowing for the reverse emotion to occur 
- Add graph for how similar the closest person is to each agent.
- Might add ability to color agents based on dominence, openness, energy, OR emotion with a click of a button?
- Allow patches to be colored (or not) based on a toggle
- Highlight the person being monitored based on a toggle?
- Allow people to move towards closest person, and allow them to move past them if moving towards them


NETLOGO FEATURES
----------------
- Use of in-cone for providing only locality within peripheral & in-front of person visibility.  
- Manually plotting "histogram" to show bar charts over time
- Ability to track one person's emotions over time


RELATED MODELS
--------------
None?


CREDITS AND REFERENCES
----------------------
Wikipedia for Emotional Contagion Theory high-level details which were utilized in the creation of this model.

Created by Christine Talbot 2010
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

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

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

dot
false
0
Circle -7500403 true true 90 90 120

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

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

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

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

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

wperson
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 90 240 120 180 120
Polygon -7500403 true true 105 90 60 90 60 120 120 120
Polygon -7500403 true true 120 195 75 300 225 300 180 195 120 195
Rectangle -7500403 true true 60 135 105 90

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
1
@#$#@#$#@
