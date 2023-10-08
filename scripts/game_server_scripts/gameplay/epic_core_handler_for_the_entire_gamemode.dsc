#/ex narrate <location[75.5,0,55.5].points_around_y[radius=50;points=16].to_polygon.with_y_min[0].with_y_max[300].outline>
#/globaldisplay transform 2 ~ 0 ~ 1600 300 1600 80
stand_to_display_ent_testing:
  type: task
  debug: false
  script:
  - if <player.has_flag[stand]>:
    - remove <player.flag[stand]>

  - if <player.has_flag[ent]>:
    - remove <player.flag[ent]>

  - if <player.has_flag[ent1]>:
    - remove <player.flag[ent1]>

  - define loc <player.location.forward_flat[2].above[2].with_pose[0,0]>

  - spawn <entity[ARMOR_STAND].with[gravity=false;collidable=false;invulnerable=true;visible=true]> <[loc].below[1.48]> save:stand
  - define stand <entry[stand].spawned_entity>

  - spawn <entity[item_display].with[item=iron_block;scale=0.1,0.1,0.1;glowing=true]> <[loc]> save:ent
  - define ent <entry[ent].spawned_entity>

  - spawn <entity[item_display].with[item=iron_block;scale=0.1,0.1,0.1;glowing=true;glow_color=yellow]> <[loc]> save:ent1
  - define ent1 <entry[ent1].spawned_entity>

  - mount <[ent]>|<[stand]>

  - flag player stand:<[stand]>
  - flag player ent:<[ent]>
  - flag player ent1:<[ent1]>


fort_core_handler:
  type: task
  debug: false
  definitions: seconds|phase|text|diameter|forming
  #phases:
  #1) bus (doors will open in x)
  #2) fall (jump off bus)
  #3) grace_period
  #4) storm_shrink

  script:

  #-Doors open
  #doors open in 20 seconds
  - ~run fort_core_handler.timer def.seconds:20  def.phase:BUS

  #-Bus drop
  #everybody off, last stop in 55 seconds
  - ~run fort_core_handler.timer def.seconds:55  def.phase:FALL

  #-Storm forms
  #storm forming in 1 Minute
  - ~run fort_core_handler.timer def.seconds:60  def.phase:GRACE_PERIOD def.forming:FORMING

  #-stage 1
  #storm eye shrinks in 3 minutes 20 seconds
  - ~run fort_core_handler.timer def.seconds:200 def.phase:GRACE_PERIOD
  #storm eye shrinking 3 minutes
  - ~run fort_core_handler.timer def.seconds:180 def.phase:STORM_SHRINK def.diameter:1600

  #-stage 2
  #storm eye shrinks in 2 minutes
  - ~run fort_core_handler.timer def.seconds:120 def.phase:GRACE_PERIOD
  #storm eye shrinking 2 minutes
  - ~run fort_core_handler.timer def.seconds:120 def.phase:STORM_SHRINK def.diameter:800

  #-stage 3
  #storm eye shrinks in 1 Minute 30 seconds
  - ~run fort_core_handler.timer def.seconds:90  def.phase:GRACE_PERIOD
  #storm eye shrinking 1 Minute 30 seconds
  - ~run fort_core_handler.timer def.seconds:90  def.phase:STORM_SHRINK def.diameter:400

  #-stage 4
  #storm eye shrinks in 1 Minute 20 Seconds
  - ~run fort_core_handler.timer def.seconds:80  def.phase:GRACE_PERIOD
  #storm eye shrinking 1 Minute 10 seconds
  - ~run fort_core_handler.timer def.seconds:70  def.phase:STORM_SHRINK def.diameter:200

  #-stage 5
  #storm eye shrinks in 50 Seconds
  - ~run fort_core_handler.timer def.seconds:50  def.phase:GRACE_PERIOD
  #storm eye shrinking 1 Minute
  - ~run fort_core_handler.timer def.seconds:60  def.phase:STORM_SHRINK def.diameter:100

  #-stage 6
  #storm eye shrinks in 30 Seconds
  - ~run fort_core_handler.timer def.seconds:30  def.phase:GRACE_PERIOD
  #storm eye shrinking 1 Minute
  - ~run fort_core_handler.timer def.seconds:60  def.phase:STORM_SHRINK def.diameter:50

  #-stage 7
  #storm eye shrinking 55 seconds
  - ~run fort_core_handler.timer def.seconds:55  def.phase:STORM_SHRINK def.diameter:35

  #-stage 8
  #storm eye shrinking 45 seconds
  - ~run fort_core_handler.timer def.seconds:45  def.phase:STORM_SHRINK def.diameter:20

  #-stage 9
  #storm eye shrinking 1 Minute 15 seconds
  - ~run fort_core_handler.timer def.seconds:75  def.phase:STORM_SHRINK def.diameter:0

  timer:
    - flag server fort.temp.phase:<[phase]>

    - define icon <&chr[<map[bus=0025;fall=0003;grace_period=B005;storm_shrink=0005].get[<[phase]>]>].font[icons]>

    - if <[diameter].exists>:
      - define storm_center <server.flag[fort.temp.storm_center]>
      - execute as_server "globaldisplay transform storm <[storm_center].simple.before_last[,].replace_text[,].with[ ]> <[diameter]> 600 <[diameter]><[seconds].mul[20]>"

    - choose <[phase]>:
      - case bus:
        - run fort_bus_handler.start_bus

        - define announce_icon <&chr[A025].get[icons]>
        - define text "DOORS WILL OPEN IN"
        - define +spacing <proc[spacing].context[89]>
        - define -spacing <proc[spacing].context[-97]>
      - case fall:
        - define announce_icon <&chr[B003].get[icons]>
        - define text "EVERYBODY OFF, LAST STOP IN"
        - define +spacing <proc[spacing].context[114]>
        - define -spacing <proc[spacing].context[-130]>
      - case grace_period:
        - define announce_icon <&chr[B006].get[icons]>
        - define text "STORM EYE <[FORMING]||SHRINKS> IN"

        - if <[seconds]> <= 60:
          - define +spacing <proc[spacing].context[86]>
          - define -spacing <proc[spacing].context[-113]>
        - else:
          #1 min and x seconds
          - define +spacing <proc[spacing].context[113]>
          - define -spacing <proc[spacing].context[-141]>

      - case storm_shrink:
        - define announce_icon <&chr[A005].get[icons]>
        - define text "STORM EYE SHRINKING"

        - if <[seconds]> <= 60:
          - define +spacing <proc[spacing].context[82]>
          - define -spacing <proc[spacing].context[-112]>
        - else:
          #1 min and x seconds
          - define +spacing <proc[spacing].context[109]>
          - define -spacing <proc[spacing].context[-138]>

    - repeat <[seconds]>:
      - define players      <server.online_players_flagged[fort]>
      - define seconds_left <[seconds].sub[<[value]>]>
      - define timer        <time[2069/01/01].add[<[seconds_left]>].format[m:ss]>

      #flag is for hud
      - flag server fort.temp.timer:<[timer]>
      - sidebar set_line scores:5 values:<element[<[icon]> <[timer]>].font[hud_text].color[<color[50,0,0]>]> players:<[players]>

      #do this in a separate task?
      #-turn this info into titles instead of bossbars?
      - if <[value]> <= 5:
        - bossbar update fort_info title:<[+spacing]><[announce_icon]><[-spacing]><&l><[text].font[lobby_text]><&sp><&d><&l><[seconds_left].as[duration].formatted_words.to_titlecase.font[lobby_text]> color:YELLOW players:<[players]>
      - else if <[value]> == 6:
        - bossbar update fort_info title:<empty> players:<[players]>

      - wait 1s

fort_bus_handler:
  type: world
  debug: false
  events:

    on player exits vehicle flagged:fort.on_bus:
    #players can't drop off before FALL phase
    - if <server.flag[fort.temp.phase]> == BUS:
      - determine passively cancelled
      - stop

    ####playsound when jumping off

    - flag player fort.on_bus:!
    - flag server fort.temp.bus.passengers:<-:<player>

    - teleport <player> <player.location.below[1.5]>
    - invisible false for:<server.online_players>

    - run fort_glider_handler.fall

  start_bus:


    - define center     <world[nimnite_map].spawn_location.with_y[220].with_pitch[0]>
    - define yaw        <util.random.int[0].to[360]>

    - define bus_start  <[center].with_yaw[<[yaw]>].forward[1152].face[<[center]>]>
    - define yaw        <[bus_start].yaw>

    - if !<[bus_start].chunk.is_loaded>:
      - chunkload <[bus_start].chunk> duration:30s
      - waituntil <[bus_start].chunk.is_loaded> rate:1s max:15s

    #- define bus_start <player.location.above[2].with_pitch[0]>
    #- define yaw <[bus_start].yaw>

    - run dmodels_spawn_model def.model_name:battle_bus def.location:<[bus_start]> save:bus
    - define bus <entry[bus].created_queue.determination.first||null>
    - run dmodels_set_scale def.root_entity:<[bus]> def.scale:1.3,1.3,1.3

    - flag server fort.temp.bus.model:<[bus]>

    - define seat_origin <[bus_start].below[1]>
    #<[bus_start].below[1]> (pre armor stand mounts)

    - define drivers_seat_loc <[seat_origin].above.left[0.71].below[1.2].backward[0.1]>
    - spawn <entity[item_display].with[scale=0.1,0.1,0.1]> <[drivers_seat_loc]> save:drivers_seat
    - define drivers_seat <entry[drivers_seat].spawned_entity>
    - flag server fort.temp.bus.seats:->:<[drivers_seat]>
    - flag <[drivers_seat]> vector_loc:<[drivers_seat_loc].sub[<[seat_origin]>]>

    #dead center (of seat) = 1.256
    - define left_seat_1_loc <[drivers_seat_loc].left[0.075].backward[1.2].below[0.05]>
    - spawn <entity[item_display].with[scale=0.1,0.1,0.1]> <[left_seat_1_loc]> save:left_seat_1
    - define left_seat_1 <entry[left_seat_1].spawned_entity>
    - flag server fort.temp.bus.seats:->:<[left_seat_1]>
    - flag <[left_seat_1]> vector_loc:<[left_seat_1_loc].sub[<[seat_origin]>]>
    - define total_seats:->:<[left_seat_1]>

    - define left_seat_2_loc <[left_seat_1_loc].backward[1.0716]>
    - spawn <entity[item_display].with[scale=0.1,0.1,0.1]> <[left_seat_2_loc]> save:left_seat_2
    - define left_seat_2 <entry[left_seat_2].spawned_entity>
    - flag server fort.temp.bus.seats:->:<[left_seat_2]>
    - flag <[left_seat_2]> vector_loc:<[left_seat_2_loc].sub[<[seat_origin]>]>
    - define total_seats:->:<[left_seat_2]>

    - repeat 3:
      - define side_seat_<[value]>_loc <[drivers_seat_loc].left[0.075].backward[<[value].sub[1].add[4]>].with_yaw[<[yaw].add[90]>].below[0.05]>
      - spawn <entity[item_display].with[scale=0.1,0.1,0.1]> <[side_seat_<[value]>_loc]> save:side_seat_<[value]>
      - define side_seat_<[value]> <entry[side_seat_<[value]>].spawned_entity>
      - flag server fort.temp.bus.seats:->:<[side_seat_<[value]>]>
      - flag <[side_seat_<[value]>]> vector_loc:<[side_seat_<[value]>_loc].sub[<[seat_origin]>]>
      - define total_seats:->:<[side_seat_<[value]>]>

    - repeat 5:
      - define right_seat_<[value]>_loc <[drivers_seat_loc].right[1.53].backward[1.2].backward[<[value].sub[1].mul[1.0716]>].below[0.05]>
      - spawn <entity[item_display].with[scale=0.1,0.1,0.1]> <[right_seat_<[value]>_loc]> save:right_seat_<[value]>
      - define right_seat_<[value]> <entry[right_seat_<[value]>].spawned_entity>
      - flag server fort.temp.bus.seats:->:<[right_seat_<[value]>]>
      - flag <[right_seat_<[value]>]> vector_loc:<[right_seat_<[value]>_loc].sub[<[seat_origin]>]>
      - define total_seats:->:<[right_seat_<[value]>]>

    - create PLAYER <&sp> <[drivers_seat_loc]> save:bus_driver
    - define bus_driver <entry[bus_driver].created_npc>
    - adjust <[bus_driver]> skin_blob:<script[nimnite_config].data_key[Spitfire_Skin]>
    - adjust <[bus_driver]> name_visible:false

    - flag server fort.temp.bus.driver:<[bus_driver]>

    - mount <[bus_driver]>|<[drivers_seat]>

    - define bus_parts <[bus].flag[dmodel_parts]>
    - foreach <[bus_parts]> as:part:
      #for some reason gotta offset the armor stand a little bit
      - define part_loc <[part].location.below[0.5].backward[2]>
      - spawn <entity[ARMOR_STAND].with[gravity=false;collidable=false;invulnerable=true;visible=false]> <[part_loc].below[1.48]> save:c_<[part]>
      - define controller <entry[c_<[part]>].spawned_entity>
      - mount <[part]>|<[controller]>

      - flag server fort.temp.bus.controllers:->:<[controller]>
      - flag <[controller]> vector_loc:<[part_loc].sub[<[bus_start]>]>
      #- wait 1t

    #randomize this, or make it so players are in the same bus if they queued at the same time?
    - define players <server.online_players_flagged[fort]>
    #-mount every player with 10 random players in the bus
    - foreach <[players].sub_lists[10]> as:group:
      - define available_seats <[total_seats]>
      #make those players only visible to that group
      - invisible <[group]> true for:<[players].exclude[<[group]>]>

      #mount the grouped players to random seats
      - foreach <[group]> as:passenger:
        - define r_seat <[available_seats].random>
        - mount <[passenger]>|<[r_seat]>
        - define available_seats:<-:<[r_seat]>

    - flag <[players]> fort.on_bus
    - flag server fort.temp.bus.passengers:<[players]>

    #logic for finding bus starting position
    #map is 2304x2304
    #2304/2 = 1152


    - define lb <element[<&l><&lb>].color[<color[72,0,0]>]>
    - define rb <element[<&l><&rb>].color[<color[72,0,0]>]>

    - define sneak_button <[lb]><element[<&l>SNEAK].color[<color[75,0,0]>]><[rb]>

    - define jump_text   "<element[<&l>PRESS].color[<color[71,0,0]>]> <[sneak_button]> <element[<&l>TO JUMP].color[<color[71,0,0]>]>"

    - define distance 2304
    - define seats       <server.flag[fort.temp.bus.seats]>
    - define controllers <server.flag[fort.temp.bus.controllers]>

    - repeat <[distance]>:

      - if <server.has_flag[fort.temp.cancel_bus]> || !<[bus].is_spawned>:
        - flag server fort.temp.cancel_bus:!
        - repeat stop

      - define passengers <server.flag[fort.temp.bus.passengers]>

      #if the next phase has started and the rest of the passengers need to get off
      #not in the first if check, so the bus still moves forwards a little after dropping players
      - if <server.flag[fort.temp.phase]> == grace_period && <[passengers].any>:
        - foreach <[passengers]> as:passenger:
          - flag <[passenger]> fort.on_bus:!
          - teleport <[passenger]> <[passenger].location.below[1.5]>
          - run fort_glider_handler.fall player:<[passenger]>

        #remove invisibility
        - invisible <[passengers]> false for:<server.online_players>
        - flag server fort.temp.bus.passengers:<list[]>
        - define passengers <list[]>

      - define new_loc <[bus_start].forward[<[value]>]>

      #teleport the display entity itself too (so it doesn't despawn, just every second)
      - teleport <[bus]> <[new_loc]> if:<[value].mod[20].equals[0]>

      - foreach <[controllers]> as:c:
        - teleport <[c]> <[new_loc].add[<[c].flag[vector_loc]>]>
        #- push <[c]> origin:<[]> destination:<[new_loc].add[<[c].flag[vector_loc]>]> duration:1t

      - foreach <[seats]> as:seat:
        - teleport <[seat]> <[new_loc].add[<[seat].flag[vector_loc]>]>

      - if <server.flag[fort.temp.phase]> == FALL && <[value].mod[30]> == 0:
        - actionbar <[jump_text]> targets:<[passengers]>

      - wait 1t

    - if <[bus].is_spawned>:
      - remove <[bus]>

    - foreach <server.flag[fort.temp.bus.seats]> as:seat:
      - remove <[seat]> if:<[seat].is_spawned>

    - foreach <server.flag[fort.temp.bus.controllers]> as:c:
      - remove <[c]> if:<[c].is_spawned>

    - remove <[bus_driver]> if:<[bus_driver].is_spawned>

    - flag server fort.temp.bus:!