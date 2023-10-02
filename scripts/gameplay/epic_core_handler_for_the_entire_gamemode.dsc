#/ex narrate <location[75.5,0,55.5].points_around_y[radius=50;points=16].to_polygon.with_y_min[0].with_y_max[300].outline>
#/globaldisplay transform 2 ~ 0 ~ 1600 300 1600 80
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

    - define icon <&chr[<map[bus=0025;fall=0003;grace_period=B005;storm_shrink=0005].get[<[phase]>]>].get[icons]>

    - if <[diameter].exists>:
      - define storm_center <server.flag[fort.temp.storm_center]>
      - execute as_server "globaldisplay transform storm <[storm_center].simple.before_last[,].replace_text[,].with[ ]> <[diameter]> 600 <[diameter]><[seconds].mul[20]>"

    - choose <[phase]>:
      - case bus:
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
      ##<server.online_players_flagged[fort]>
      - define players      <world[ft24].players>
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

    on player steers entity flagged:fort.on_bus:
    - if <context.dismount>:
      - determine passively cancelled
      - stop

    - if <context.jump>:
      - mount cancel <player>
      - flag player fort.on_bus:!
      - flag server fort.temp.bus.passengers:<-:<player>

  spawn:


    - if <server.has_flag[fort.temp.bus.model]>:
      - run dmodels_delete def.root_entity:<server.flag[fort.temp.bus.model]>
      - flag server fort.temp.bus.model:!

    #we can also make the seats the keys, and the vectors the values
    - if <server.has_flag[fort.temp.bus.seats]>:
      - foreach <server.flag[fort.temp.bus.seats]> as:s:
        - remove <[s]>
      - flag server fort.temp.bus.seats:!

    - if <server.has_flag[fort.temp.bus.driver]>:
      - remove <server.flag[fort.temp.bus.driver]>
      - flag server fort.temp.bus.driver:!

    - define center     <world[ft24].spawn_location.with_y[220].with_pitch[0]>
    - define yaw <util.random.int[0].to[360]>

    - define bus_start  <[center].with_yaw[<[yaw]>].forward[1152].face[<[center]>]>
    - define yaw        <[bus_start].yaw>

    - if !<[bus_start].chunk.is_loaded>:
      - chunkload <[bus_start].chunk> duration:30s

    #- define bus_start <player.location.above[2].with_pitch[0]>
    #- define yaw <[bus_start].yaw>

    - run dmodels_spawn_model def.model_name:battle_bus def.location:<[bus_start]> def.yaw:<[yaw]> save:bus
    - define bus <entry[bus].created_queue.determination.first||null>
    - run dmodels_set_scale def.root_entity:<[bus]> def.scale:1.3,1.3,1.3

    - flag server fort.temp.bus.model:<[bus]>

    - define drivers_seat_loc <[bus_start].above.left[0.71].below[1.2].backward[0.1]>
    - spawn <entity[item_display].with[item=iron_block;scale=0.1,0.1,0.1]> <[drivers_seat_loc]> save:drivers_seat
    - define drivers_seat <entry[drivers_seat].spawned_entity>
    - flag server fort.temp.bus.seats:->:<[drivers_seat]>
    - flag <[drivers_seat]> vector_loc:<[drivers_seat_loc].sub[<[bus_start]>]>

    #dead center (of seat) = 1.256
    - define left_seat_1_loc <[drivers_seat_loc].left[0.075].backward[1.2].below[0.05]>
    - spawn <entity[item_display].with[item=iron_block;scale=0.1,0.1,0.1]> <[left_seat_1_loc]> save:left_seat_1
    - define left_seat_1 <entry[left_seat_1].spawned_entity>
    - flag server fort.temp.bus.seats:->:<[left_seat_1]>
    - flag <[left_seat_1]> vector_loc:<[left_seat_1_loc].sub[<[bus_start]>]>

    - define left_seat_2_loc <[left_seat_1_loc].backward[1.0716]>
    - spawn <entity[item_display].with[item=iron_block;scale=0.1,0.1,0.1]> <[left_seat_2_loc]> save:left_seat_2
    - define left_seat_2 <entry[left_seat_2].spawned_entity>
    - flag server fort.temp.bus.seats:->:<[left_seat_2]>
    - flag <[left_seat_2]> vector_loc:<[left_seat_2_loc].sub[<[bus_start]>]>

    - repeat 3:
      - define side_seat_<[value]>_loc <[drivers_seat_loc].left[0.075].backward[<[value].sub[1].add[4]>].with_yaw[<[yaw].add[90]>].below[0.05]>
      - spawn <entity[item_display].with[item=iron_block;scale=0.1,0.1,0.1]> <[side_seat_<[value]>_loc]> save:side_seat_<[value]>
      - define side_seat_<[value]> <entry[side_seat_<[value]>].spawned_entity>
      - flag server fort.temp.bus.seats:->:<[side_seat_<[value]>]>
      - flag <[side_seat_<[value]>]> vector_loc:<[side_seat_<[value]>_loc].sub[<[bus_start]>]>

    - repeat 5:
      - define right_seat_<[value]>_loc <[drivers_seat_loc].right[1.53].backward[1.2].backward[<[value].sub[1].mul[1.0716]>].below[0.05]>
      - spawn <entity[item_display].with[item=iron_block;scale=0.1,0.1,0.1]> <[right_seat_<[value]>_loc]> save:right_seat_<[value]>
      - define right_seat_<[value]> <entry[right_seat_<[value]>].spawned_entity>
      - flag server fort.temp.bus.seats:->:<[right_seat_<[value]>]>
      - flag <[right_seat_<[value]>]> vector_loc:<[right_seat_<[value]>_loc].sub[<[bus_start]>]>

    - create PLAYER <&sp> <[drivers_seat_loc]> save:bus_driver
    - define bus_driver <entry[bus_driver].created_npc>
    - adjust <[bus_driver]> skin_blob:<script[nimnite_config].data_key[Spitfire_Skin]>
    - adjust <[bus_driver]> name_visible:false

    - flag server fort.temp.bus.driver:<[bus_driver]>

    - wait 3t
    - mount <[bus_driver]>|<[drivers_seat]>
    - mount <player>|<[side_seat_2]>

    - define bus_parts <[bus].flag[dmodel_parts]>
    - foreach <[bus_parts]> as:part:
      - define part_loc <[part].location.below[1.5]>
      - spawn <entity[ARMOR_STAND].with[gravity=false;collidable=false;invulnerable=true;visible=true]> <[part_loc]> save:c_<[part]>
      - define controller <entry[c_<[part]>].spawned_entity>
      - mount <[part]>|<[controller]>

      - flag server fort.temp.bus.controllers:->:<[controller]>
      - flag <[controller]> vector_loc:<[part_loc].sub[<[bus_start]>]>
      #- wait 1t


    - flag server fort.temp.bus.passengers:->:<player>

    - flag player fort.on_bus

    ##logic for finding bus starting position
    #map is 2304x2304
    #2304/2 = 1152

    #230 seconds
    - define distance 2304
    - define seats       <server.flag[fort.temp.bus.seats]>
    - define controllers <server.flag[fort.temp.bus.controllers]>

    - repeat <[distance]>:

      - if <server.has_flag[fort.temp.cancel_bus]> || !<[bus].is_spawned>:
        - flag server fort.temp.cancel_bus:!
        - repeat stop

      - define new_loc <[bus_start].forward[<[value]>]>

      - foreach <[controllers]> as:c:
        - teleport <[c]> <[new_loc].add[<[c].flag[vector_loc]>]>

      - foreach <[seats]> as:seat:
        - teleport <[seat]> <[new_loc].add[<[seat].flag[vector_loc]>]>

      - wait 1t

    - if <[bus].is_spawned>:
      - remove <[bus]>

    - foreach <server.flag[fort.temp.bus.seats]> as:seat:
      - remove <[seat]> if:<[seat].is_spawned>

    - foreach <server.flag[fort.temp.bus.controllers]> as:c:
      - remove <[c]> if:<[c].is_spawned>
    - flag server fort.temp.bus.controllers:!