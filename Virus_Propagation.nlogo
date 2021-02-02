turtles-own
[
  sick ;; if true, the turtle is sick
  sick_duration ;; how many times (in days), the turtle has been sick
  immune ;; if true, the turtle is immunised to the virus
  barrier_gesture ;; if true, the turtle respects barrier gestures
  initial_patch ;; to save the initial patch of the turtle to limit its movement
]

globals [
  mouse_was_down ;; use to handle click on turtle
  %immune ;; % of turtle immune
  %sick ;; % of turtle sick
  %safe ;; % of turtle safe(=healthy)
  #die ;; number of turtle who died
]

;; Setup function
to setup
  clear-all
  ask patches [
  set pcolor white ;; color the area in white, personnal choice, you can remove this line if you want
  ]
  let sick_people (population_size * percentage_sick / 100)
  let immune_people (population_size * percentage_immune / 100)
  let barrier_gesture_people (population_size * percentage_respect_barrier_gesture / 100)

  ifelse (percentage_sick + percentage_immune > 100) ;; check mathematics things
  [
    print "/!\\ The sum of the percentages of sick and immune people are up to 100... /!\\"
  ]
  [
  create-turtles sick_people ;; setup sick people
    [
      setup-turtle
      set sick True
      set color red
      set immune False
  ]
  create-turtles immune_people ;; setup immune people
    [
      setup-turtle
      set sick False
      set color blue
      set immune True
  ]
  create-turtles (population_size - sick_people - immune_people) ;; setup safe people
    [
      setup-turtle
      set sick False
      set color green
      set immune False
  ]

    ask turtles [ ;; update turtle size according to the shape
    ifelse (turtles_shape = "circle")
      [
      set size 1
      ]
      [
      set size 2
      ]
    ]
  set barrier_gesture_people min (list barrier_gesture_people count turtles with [ not sick and not immune ])
  ask n-of barrier_gesture_people turtles with [ not sick and not immune ] [ ;; setup turtle who respect barrier gesture
      set barrier_gesture True

      if (not sick) [
      set color turquoise
      ]
    ]

  update-global-variables
  set #die 0
  reset-ticks
]
end

;; Procedure to setup turtle with default value
to setup-turtle;;turtle procedure
  setxy random-xcor random-ycor ;; random position for each turtle
  set initial_patch patch-here
  set shape turtles_shape
  set barrier_gesture False
  set sick_duration 0
end

;; Procedure call at each tick when the button go is pressed
to go
  go-once
end

to go-once
  ifelse (not lockdown) [
    ask turtles [
      move
      if (sick = True) [
        infect
      ]
      update-turtle-state
    ]
  ]
  [
    let move_turtles ( 0.1 * count turtles) ;; if we are in a lockdown situation : we approximate that only 10% of the agent will move at each tick
    ask n-of move_turtles turtles [
      move
      if (sick = True) [ ;; If the turtle is sick, do the infection procedure
        infect
      ]
      update-turtle-state
    ]
  ]
  update-global-variables
  tick
end

;; Procedure call when the button show-turtles-info is pressed, when you click on a turtle we will get information about it
to show-turtles-info
  check-mouse
end

;; Procedure call at each tick to make the turtles move
to move ;;turtle procedure
  if (not isolation or (isolation and not sick)) [
    let last_patch patch-here
    rt random-float 90 - random-float 90
    fd 1
    if xcor > max-pxcor ;; Keep the turtles in the area
    [ set xcor max-pxcor ]
    if ycor > max-pycor
    [ set ycor max-pycor ]

    if xcor < min-pxcor
    [ set xcor min-pxcor ]
    if ycor < min-pycor
    [ set ycor min-pycor ]

    let distance_from_initial distance initial_patch
    if (distance_from_initial > radius_deplacement) ;; check if the turtle doesn't move to far of its origin
    [
      move-to last_patch
    ]
  ]
end

;; At each tick, update the sick situation
to update-turtle-state ;;turtle procedure
  if (sick = True and not immune) [
      set sick_duration (sick_duration + 1)
    if (sick_duration >= virus_duration)
    [
      set sick_duration 0
      set sick False
      ifelse random-float 100 < percentage_recovery [ ;; At the end of the virus duration, either the agent survives and is immune or the agent dies.
        set immune True
        set color blue
      ]
      [
        turtle-die
      ]
    ]
  ]

  if shape != turtles_shape [
    ifelse (turtles_shape = "circle")
    [
      set size 1
    ]
    [
      set size 2
    ]
    set shape turtles_shape
  ]
end

;; [INSPIRED FROM VIRUS MODEL IN NETLOGO]
;; If a turtle is sick, it infects other turtles on the same patch.
;; Immune turtles don't get sick.
to infect ;; turtle procedure
  ifelse infectiousness_360_degrees
      [
        ask other turtles in-radius radius_to_infect with [ not sick and not immune ]
    [
      let final_infectiousness infectiousness

      if (barrier_gesture) [
        set final_infectiousness (0.5 * infectiousness) ;; Barrier gestures decrease of ~50% the infectiousness of the virus
      ]
      if (mask) [
        set final_infectiousness (0.3 * infectiousness) ;; Masks blocked ~70% of the air particule ( https://www.santemagazine.fr/sante/maladies/maladies-infectieuses/maladies-virales/tout-savoir-sur-les-masques-de-protection-contre-le-coronavirus-433485 )
      ]

      if random-float 100 < final_infectiousness
      [
        set sick True
        set sick_duration (sick_duration + 1)
        set color red
          ]
        ]
  ]
      [
        ask other turtles in-cone radius_to_infect 90 with [ not sick and not immune ]
    [
      let final_infectiousness infectiousness

      if (barrier_gesture) [
        set final_infectiousness (0.5 * infectiousness) ;; Barrier gestures decrease of ~50% the infectiousness of the virus
      ]
      if (mask) [
        set final_infectiousness (0.3 * infectiousness) ;; Masks blocked ~70% of the air particule ( https://www.santemagazine.fr/sante/maladies/maladies-infectieuses/maladies-virales/tout-savoir-sur-les-masques-de-protection-contre-le-coronavirus-433485 )
      ]

      if random-float 100 < final_infectiousness
      [
        set sick True
        set sick_duration (sick_duration + 1)
        set color red
      ]
    ]
  ]

end

;; Procedure when show-turtles-infos is pressed, if we click on a turtle, you will get information (deplacement area and infection area)
to check-mouse
  if mouse-down? and not mouse_was_down[
    set mouse_was_down True
    ask turtles with [round xcor = round mouse-xcor and round ycor = round mouse-ycor] [
      ask initial_patch [
        ask patches in-radius radius_deplacement
      [ set pcolor yellow ]
      ]

      ifelse infectiousness_360_degrees
      [
        ask patches in-radius radius_to_infect
        [ set pcolor black ]
      ]
      [
        ask patches in-cone radius_to_infect 90
        [ set pcolor black ]
      ]
      print "Sick duration :"
      show sick_duration
    ]
  ]

  if not mouse-down?
  [
    set mouse_was_down False
    ask patches [
      set pcolor white
    ]
  ]
end

;; [INSPIRED FROM VIRUS MODEL IN NETLOGO]
to update-global-variables
     set %sick (count turtles with [ sick and not immune ] / count turtles) * 100
     set %immune (count turtles with [ immune ] / count turtles) * 100
     set %safe (count turtles with [ not sick and not immune ] / count turtles) * 100
end

to turtle-die;;turtle procedure
  set #die (#die + 1)
  die
end
@#$#@#$#@
GRAPHICS-WINDOW
502
15
1318
512
-1
-1
8.0
1
10
1
1
1
0
0
0
1
0
100
-60
0
0
0
1
Days
30.0

BUTTON
10
32
145
65
setup
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

BUTTON
11
71
66
104
go
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

INPUTBOX
7
109
146
169
population_size
100.0
1
0
Number

SLIDER
159
10
307
43
percentage_sick
percentage_sick
0
100
10.0
1
1
%
HORIZONTAL

SLIDER
158
83
389
116
percentage_respect_barrier_gesture
percentage_respect_barrier_gesture
0
100
20.0
1
1
%
HORIZONTAL

SLIDER
160
121
279
154
infectiousness
infectiousness
0
100
80.0
1
1
%
HORIZONTAL

SLIDER
160
197
482
230
percentage_recovery
percentage_recovery
0
100
80.0
1
1
%
HORIZONTAL

CHOOSER
7
174
146
219
turtles_shape
turtles_shape
"circle" "person" "default"
1

SLIDER
160
160
481
193
radius_to_infect
radius_to_infect
0
50
4.0
0.2
1
NIL
HORIZONTAL

BUTTON
1356
228
1488
261
NIL
show-turtles-info
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
284
122
482
155
infectiousness_360_degrees
infectiousness_360_degrees
0
1
-1000

SLIDER
159
47
481
80
virus_duration
virus_duration
1
48
28.0
1
1
Days
HORIZONTAL

TEXTBOX
1338
13
1488
44
• Infected
20
15.0
1

TEXTBOX
1339
42
1489
73
• Safe
20
55.0
1

TEXTBOX
1340
106
1490
137
• Immune
20
105.0
1

SLIDER
313
10
481
43
percentage_immune
percentage_immune
0
100
0.0
1
1
%
HORIZONTAL

MONITOR
125
327
182
372
%safe
%safe
1
1
11

MONITOR
187
327
244
372
NIL
%sick
1
1
11

MONITOR
248
328
315
373
NIL
%immune
1
1
11

PLOT
29
381
392
578
Populations
Days
Count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Infected" 1.0 0 -2674135 true "" "plot count turtles with [ sick ]"
"Safe" 1.0 0 -10899396 true "" "plot count turtles with [ not sick and not immune ]"
"Immune" 1.0 0 -13345367 true "" "plot count turtles with [ immune = True ]"
"Total" 1.0 0 -16777216 true "" "plot count turtles"

TEXTBOX
1339
73
1489
104
• Barrier gesture
20
75.0
1

SWITCH
392
84
482
117
Mask
Mask
1
1
-1000

SLIDER
161
237
364
270
radius_deplacement
radius_deplacement
0
100
3.2
0.2
1
NIL
HORIZONTAL

SWITCH
373
237
483
270
lockdown
lockdown
0
1
-1000

MONITOR
404
476
474
521
NIL
#die
17
1
11

MONITOR
403
425
474
470
Population
count turtles
17
1
11

TEXTBOX
1362
199
1512
217
NIL
11
0.0
1

TEXTBOX
1346
271
1496
305
On click on a turtle \n(with show-turtles-info)
14
0.0
1

TEXTBOX
1349
320
1499
339
• Deplacement area
15
45.0
0

TEXTBOX
1350
345
1500
364
• Infection area
15
0.0
1

SWITCH
373
274
483
307
isolation
isolation
1
1
-1000

BUTTON
69
71
146
104
NIL
go-once
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model represents an (approximate) simulation of the spread of an airborne virus (similar to the covid19 ) and the influence of the different control measures against this virus.

This model is inspired by the netlogo virus model developed in 1998 by Uri Wilensky.

* Wilensky, U. (1998). NetLogo Virus model. http://ccl.northwestern.edu/netlogo/models/Virus. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## HOW IT WORKS

The model is initialized with a certain number of people (configurable via population input) among which some are positive for the virus, some are immune. At each tick, the agents move randomly through their (user-defined) area of movement. These agents can be in one of these 3 states: infected by the virus (red), immune (blue) and healthy (green). It is also important to note that there are two shades of green, one representing the agents respecting the barrier gestures (configurable in the model). Through the evolution of this population, this model offers the possibility to follow the spread of a virus, the number of victims in particular.

At the level of interactions between agents, when an infected agent crosses another one, there is a certain probability that it will contaminate it. The virus also has a lifespan, at the end of this period of contamination, an individual can either recover and obtain immunity to the virus or die. 
It is important that here, the death of a turtle is not necessarily to be compared to the death of an individual in real life. Simply, it illustrates the power of a virus through a population, the more numerous the turtle deaths are, the harder the virus is to control.

The probability of contamination from one individual to another depends on several factors: the infectiousness of the disease, the respect of barrier gestures and the wearing of masks. The probability of infectiousness decreases by 50% if individuals respect the barrier gestures and by 70% if they wear a mask.
The zone of contamination is also configurable by the user, whether it is its directivity or its distance of action.

In order to best fit the health situation related to covid19 , it is also possible to configure lockdown measures, either by limiting movement or by limiting the number of turtles that can move (equivalent to true lockdown). In case of lockdown, at each tick, only 10% of the agents are brought to move.

Note that it is also possible to customize the shape of the turtles.

## HOW TO USE IT

Below, you will find the description and the impact of the different values that can be set by the user.

### Setup [button]
Allows to initialize the simulation

### Go [button]
Launches the simulation (infinite button to make the simulation continuous), one tick = one day.

### show-turtles-infos [button]
This button allows, when active, to have information about the turtles when you click on them: the time from which he is sick (in the console), the zone in which he can infect someone and the zone in which he can move.

### turtles-shape [chooser]
Allows you to decide the shape of the agents.

### percentage_sick [slider]
Defined the percentage of the population being ill at the start of the simulation.

### percentage_immune [slider]
Defines the percentage of the population that is immune to the virus at the beginning.

### virus_duration [slider]
Defined the lifetime of the virus after which an agent is either immune or dead.

### percentage_respect_barrier_gesture [slider]
Defined the percentage of the population respecting the barrier gestures.

### Mask [switch]
Defined whether or not individuals wear masks.

### infectiousness [slider]
Defines the probability of transmission of the virus when two individuals cross each other (100% corresponding to systematic transmission, 0% to impossible transmission). For covid19 for example, this rate is ~70%.

### infectiousness_360_degrees [switch]
Defined if an individual can infect another one all around him or only in the direction of travel (equivalent to someone in front of him, simulation of a discussion).

### radius_to_infect [slider]
Defines the distance around which one agent can contaminate another (for example within a closed space this value can be considered high, and outside low).

### percentage_recovery [slider]
Defines the percentage of chance that an individual has to recover from the virus and become immune.

### radius_deplacement [slider]
Defines the distance (circular) within which the user can move (similar to the 1km limit in France for example).

### lockdown [switch]
Activate or not a "lockdown" mode, in the latter, only 10% of the agents move at each tick.

### isolation [switch]
An alternative to lockdown is just isolate (no movement) for sick agent (self-lockdown).

### Monitor and plot
You can track the state of the population (percentage of sick, healthy and immunized people) as well as the number of deaths.

## THINGS TO NOTICE
Don't hesitate to activate the show-turtles-infos button then click on the turtles to see the influence of the different parameters: 

* range_deplacement
* infectiousness_360_degrees
* range_to_infect

If we take a set of values corresponding to the beginning of the covid epidemic19 : a population of 1000 individuals, a very slight rate of infected people 1%, 0% immunized, no barrier/masked gestures, no containment, 35 days of infections and a great chance of recovery from the virus. With this set of parameters we realize that even if the virus seems harmless, it spreads very rapidly and infects the entire population. This seems to be consistent with the year 2020. 
We notice a huge peak of infections, however, it is also interesting to note that if we add to the same simulation a percentage of 25% of compliance with barrier gestures and the wearing of the mask, we manage to smooth this curve of contaminations (which corresponds to a slackening on the hospital system) and to decrease its maximum.
Of course, as one can imagine if one adds containment measures, this also helps to better control the epidemic. Decrease the height of the maximum of the "wave" and smooth the peak. 
In any case, we notice that a virus with a high rate of spread (such as covid19 ) is very difficult to contain within a population without applying strict containment, even if it is not enormously fatal, it causes deaths, and very quickly infects a large number of people.


A second thing that may be interesting to notice is to simulate a fenced area using our parameters (for example a family gathering, night club...): no masks, little respect for barrier gestures but a very wide range of contamination. Let's consider this situation with 50 individuals, and 1 originally contaminated individual. Although caricatured, this situation shows us that all the individuals are contaminated almost instantaneously... This may explain some restrictive measures at the level of gatherings.

Finally, a positive perspective is that viruses that have a high rate of infection and a high rate of cure do not necessarily last in the long term (people die or become immune), which may give hope for good prospects in the case of covid19.


## THINGS TO TRY

What happens in the case of a highly infectious virus with a very short lifespan and little chance of recovery? (Like the ebola virus)

What happens in the case of a virus that is not very infectious with a very long lifespan and little chance of survival? (Like HIV)

Do the use of masks and the respect of barrier gestures have a real impact on the spread of a virus? 

What is the most effective containment measure? Total lockdown or a large movement limitation? (low radius_deplacement)

## EXTENDING THE MODEL

In order to improve the model it would be interesting to try to integrate the management of the time of exposure to the virus. That is to say, to reduce the random and systematic nature of the movements of agents in order to simulate public places where people meet in the long term (restaurants, stores, etc.) and this would of course have consequences on the transmission of the virus from individual to individual.

A second possibility of improvement can also manage the age within the simulation and give different influence to the virus according to the age.

## RELATED MODELS

* Wilensky, U. (1998). NetLogo Virus model. http://ccl.northwestern.edu/netlogo/models/Virus. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## CREDITS AND REFERENCES

* Wilensky, U. (1998). NetLogo Virus model. http://ccl.northwestern.edu/netlogo/models/Virus. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* Course AI-961, System multi-agents by Ada Diaconescu
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
NetLogo 6.1.1
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
