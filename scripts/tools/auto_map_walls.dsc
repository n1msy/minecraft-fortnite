#get a bunch of maps that when lined up form a bigger map
map_wall:
  type: task
  #size is the dimensions of the entire plane
  #zoom is the scale of the maps
  definitions: size
  debug: false
  script:

  #must be at least 1028, so there are at least 4 tiles

  - if <[size]> < 1024 || <[size].mod[1024]> != 0:
    - narrate "<&c>Must specify a number in multiples of 1024! (ie. 1024, 2048, etc.)"
    - stop

  - define center <player.location>
  - define world <[center].world>

  - define sub_center_size <[size].div[128]>

  - definemap corner_data:
      #top left
      0: <location[-1,0,1]>
      #top right
      1: <location[1,0,1]>
      #bottom left
      2: <location[-1,0,-1]>
      #bottom right
      3: <location[1,0,-1]>

  - repeat <[sub_center_size]>:

    - define corner <[corner_data].get[<[value].mod[4]>]>
    - define add_loc <[corner].mul[<[value].mul[128]>]>

    - define sub_center <[center].add[<[add_loc]>]>

    - map new:<[world]> reset:<[sub_center]> scale:NORMAL save:map
    - define item <item[filled_map[map=<entry[map].created_map>]]>
    - repeat 16 as:x:
        - adjust <[item]> full_render:<[x].sub[1].mul[8]>,0,<[x].mul[8]>,128
        - wait 2t

    - give <[item]>






