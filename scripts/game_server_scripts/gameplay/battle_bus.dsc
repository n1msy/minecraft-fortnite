fort_bus_handler:
  type: world
  debug: false
  definitions: player
  events:

    #so they can't use the teleport feature vanilla mc has
    on player teleports cause:SPECTATE flagged:fort.on_bus:
    - determine passively cancelled

    on player stops spectating flagged:fort.on_bus:
    - determine passively cancelled
    - if <server.flag[fort.temp.phase]> == BUS:
      - stop

    on player drops item flagged:fort.on_bus priority:-1000:
    - determine cancelled

    on player damaged flagged:fort.on_bus:
    - determine cancelled

    on player exits vehicle flagged:fort.on_bus:
    #players can't drop off before FALL phase
    - if <server.flag[fort.temp.phase]> == BUS:
      - determine passively cancelled
      - stop

    - run fort_bus_handler.drop_player def.player:<player>

    #-mode 1:
    - stop
    - playsound <player> sound:BLOCK_CONDUIT_DEACTIVATE pitch:1.2 volume:0.25

    - flag player fort.on_bus:!
    - flag server fort.temp.bus.passengers:<-:<player>

    #this way, the sneak event doesn't fire twice and the glider doesn't immediately deply
    - flag player fort.bus_jumped duration:1s

    - teleport <player> <player.location.below[1.5]>
    - invisible reset

    - run fort_glider_handler.fall

  drop_player:
  ###check if the p npcs are actually being removed when jumping off
    - adjust <[player]> spectate:<[player]>
    #safety
    - wait 3t
    - teleport <[player]> <server.flag[fort.temp.bus.bus_center_entity].location.below[2]>
    # - [ Pick another ~ Chosen One ~ ] - #
    - define passenger_npcs <server.flag[fort.temp.bus.passenger_npcs]||<list[]>>
    #if this passes, it means, they're one of the "chosen" ones
    - if <[passenger_npcs].filter[flag[fort.passenger_uuid].equals[<[player].uuid>]].any>:
      - define current_p_npc  <[passenger_npcs].filter[flag[fort.passenger_uuid].equals[<[player].uuid>]].first>
      - define players_on_bus <server.online_players_flagged[fort.on_bus].exclude[<[player]>]>
      - define not_chosen_players_on_bus <[players_on_bus].filter_tag[<[passenger_npcs].filter[flag[fort.passenger_uuid].equals[<[filter_value].uuid>]].any>]>
      #if it's empty, it means either everyone has left or there are less than 10 players on the bus
      - if <[not_chosen_players_on_bus].is_empty>:
        - flag server fort.temp.bus.passenger_npcs:<-:<[current_p_npc]>
        #remove the flag so they can be despawned properly
        - flag <[current_p_npc]> fort:!
        - remove <[current_p_npc]>
      - else:
        - define lucky_one <[not_chosen_players_on_bus].random>
        - adjust <[current_p_npc]> skin_blob:<[lucky_one].skin_blob>
        - flag <[current_p_npc]> fort.passenger_uuid:<[lucky_one].uuid>
    # -
    - take slot:9 from:<[player].inventory>
    #so <[previous_item_slot]> after glidering would be 1 (no need to update hud either, since already did that)
    - adjust <[player]> item_slot:1
    - run fort_glider_handler.fall player:<[player]>
    - flag <[player]> fort.on_bus:!

  start_bus:


    - define center     <world[nimnite_map].spawn_location.with_y[220].with_pitch[0]>
    - define yaw        <util.random.int[0].to[360]>

    #default: 1152
    - define distance_from_center 1100
    #1152 is the real size, im gonna decrease it be a little
    - define bus_start  <[center].with_yaw[<[yaw]>].forward[<[distance_from_center]>].face[<[center]>]>
    - define yaw        <[bus_start].yaw>

    #randomize this, or make it so players are in the same bus if they queued at the same time?
    - define players <server.online_players_flagged[fort]>

    - inject fort_bus_handler.setup_bus

    #-spawn armor stands to make bus move smoother
    - define bus_parts <[bus].flag[dmodel_parts]>
    - foreach <[bus_parts]> as:part:
      #for some reason gotta offset the armor stand a little bit
      - define part_loc <[part].location.below[0.5].backward[2]>
      - if !<[part_loc].chunk.is_loaded>:
        - chunkload <[part_loc]> duration:5m
      - spawn <entity[ARMOR_STAND].with[gravity=false;collidable=false;invulnerable=true;visible=false;force_no_persist=true]> <[part_loc].below[1.48]> save:c_<[part]>
      - define controller <entry[c_<[part]>].spawned_entity>
      - mount <[part]>|<[controller]>

      - flag server fort.temp.bus.controllers:->:<[controller]>
      - define total_controllers:->:<[controller]>
      - flag <[controller]> vector_loc:<[part_loc].sub[<[bus_start]>]>

    #logic for finding bus starting position
    #map is 2304x2304
    #2304/2 = 1152

    - define lb <element[<&l><&lb>].color[<color[72,0,0]>]>
    - define rb <element[<&l><&rb>].color[<color[72,0,0]>]>

    - define sneak_button <[lb]><element[<&l>SNEAK].color[<color[75,0,0]>]><[rb]>

    - define jump_text   "<element[<&l>PRESS].color[<color[71,0,0]>]> <[sneak_button]> <element[<&l>TO JUMP].color[<color[71,0,0]>]>"

    - define distance <[distance_from_center].mul[2]>

    #different modes to test
    - inject fort_bus_handler.drive_bus.mode_<script[nimnite_config].data_key[bus_view_mode]>

  add_driver:
    #- define drivers_seat <server.flag[fort.temp.bus.seats].first>
    - define drivers_seat <server.flag[fort.temp.bus.drivers_seat]>
    - define driver_loc   <[drivers_seat].location>
    - create PLAYER <&sp> <[driver_loc]> save:bus_driver
    - define bus_driver <entry[bus_driver].created_npc>

    - mount <[bus_driver]>|<[drivers_seat]>
    - flag server fort.temp.bus.driver:<[bus_driver]>

    - adjust <[bus_driver]> skin_blob:<script[nimnite_config].data_key[Spitfire_Skin]>
    - adjust <[bus_driver]> name_visible:false

  setup_bus:

    - if !<[bus_start].chunk.is_loaded>:
      - chunkload <[bus_start].chunk> duration:5m

    - run dmodels_spawn_model def.model_name:battle_bus def.location:<[bus_start]> save:bus
    - define bus <entry[bus].created_queue.determination.first||null>
    - run dmodels_set_scale def.root_entity:<[bus]> def.scale:1.3,1.3,1.3

    - flag server fort.temp.bus.model:<[bus]>

    - define seat_origin <[bus_start].below[1]>
    #<[bus_start].below[1]> (pre armor stand mounts)

    #-instead of checking chunks, just load 1 random player in to load them, or no?
    #checking chunks just in case
    - define drivers_seat_loc <[seat_origin].above[1.65].left[0.71].below[1.2].backward[0.1]>
    - if !<[drivers_seat_loc].chunk.is_loaded>:
      - chunkload <[drivers_seat_loc].chunk> duration:5m
    - spawn <entity[item_display].with[scale=0.1,0.1,0.1;force_no_persist=true]> <[drivers_seat_loc]> save:drivers_seat
    - define drivers_seat <entry[drivers_seat].spawned_entity>
    - flag server fort.temp.bus.drivers_seat:<[drivers_seat]>
    - flag server fort.temp.bus.seats:->:<[drivers_seat]>
    - flag <[drivers_seat]> vector_loc:<[drivers_seat_loc].sub[<[seat_origin]>]>
    - define total_seats:->:<[drivers_seat]>

    #dead center (of seat) = 1.256
    - define left_seat_1_loc <[drivers_seat_loc].left[0.075].backward[1.2].below[0.05]>
    - if !<[left_seat_1_loc].chunk.is_loaded>:
      - chunkload <[left_seat_1_loc].chunk> duration:5m
    - spawn <entity[item_display].with[scale=0.1,0.1,0.1;force_no_persist=true]> <[left_seat_1_loc]> save:left_seat_1
    - define left_seat_1 <entry[left_seat_1].spawned_entity>
    - flag server fort.temp.bus.seats:->:<[left_seat_1]>
    - flag <[left_seat_1]> vector_loc:<[left_seat_1_loc].sub[<[seat_origin]>]>
    - define total_seats:->:<[left_seat_1]>

    - define left_seat_2_loc <[left_seat_1_loc].backward[1.0716]>
    - if !<[left_seat_2_loc].chunk.is_loaded>:
      - chunkload <[left_seat_2_loc].chunk> duration:5m
    - spawn <entity[item_display].with[scale=0.1,0.1,0.1;force_no_persist=true]> <[left_seat_2_loc]> save:left_seat_2
    - define left_seat_2 <entry[left_seat_2].spawned_entity>
    - flag server fort.temp.bus.seats:->:<[left_seat_2]>
    - flag <[left_seat_2]> vector_loc:<[left_seat_2_loc].sub[<[seat_origin]>]>
    - define total_seats:->:<[left_seat_2]>

    - repeat 3:
      - define side_seat_<[value]>_loc <[drivers_seat_loc].left[0.075].backward[<[value].sub[1].add[4]>].with_yaw[<[yaw].add[90]>].below[0.05]>
      - if !<[side_seat_<[value]>_loc].chunk.is_loaded>:
        - chunkload <[left_seat_2_loc].chunk> duration:5m
      - spawn <entity[item_display].with[scale=0.1,0.1,0.1;force_no_persist=true]> <[side_seat_<[value]>_loc]> save:side_seat_<[value]>
      - define side_seat_<[value]> <entry[side_seat_<[value]>].spawned_entity>
      - flag server fort.temp.bus.seats:->:<[side_seat_<[value]>]>
      - flag <[side_seat_<[value]>]> vector_loc:<[side_seat_<[value]>_loc].sub[<[seat_origin]>]>
      - define total_seats:->:<[side_seat_<[value]>]>

    - repeat 5:
      - define right_seat_<[value]>_loc <[drivers_seat_loc].right[1.53].backward[1.2].backward[<[value].sub[1].mul[1.0716]>].below[0.05]>
      - if !<[right_seat_<[value]>_loc].chunk.is_loaded>:
        - chunkload <[left_seat_2_loc].chunk> duration:5m
      - spawn <entity[item_display].with[scale=0.1,0.1,0.1;force_no_persist=true]> <[right_seat_<[value]>_loc]> save:right_seat_<[value]>
      - define right_seat_<[value]> <entry[right_seat_<[value]>].spawned_entity>
      - flag server fort.temp.bus.seats:->:<[right_seat_<[value]>]>
      - flag <[right_seat_<[value]>]> vector_loc:<[right_seat_<[value]>_loc].sub[<[seat_origin]>]>
      - define total_seats:->:<[right_seat_<[value]>]>

  #for testing/debug purposes
  view_bus_concept:
    - flag player test
    - run dmodels_spawn_model def.model_name:battle_bus def.location:<player.location> save:bus
    - define bus <entry[bus].created_queue.determination.first||null>
    - run dmodels_set_scale def.root_entity:<[bus]> def.scale:1.3,1.3,1.3
    - spawn <entity[armor_stand].with[invulnerable=true;force_no_persist=true]> <player.location> save:camera
    - define cam <entry[camera].spawned_entity>
    - adjust <player> spectate:<[cam]>
    - invisible <[cam]> true
    - cast SLOW_DIGGING amplifier:255 duration:infinite no_icon no_ambient hide_particles
    #blank item
    - define thank "<&chr[1].font[item_name]><&7><element[Press].font[item_name]>
                    <&c><&l><&keybind[key.swapOffhand].font[item_name]> 
                    <&7><element[to thank the bus driver.].font[item_name]>"
    - give <item[paper].with[display=<[thank]>;custom_model_data=17]> slot:9
    - adjust <player> item_slot:9
    - while <player.has_flag[test]>:
      #with item displays
      # define bus_center <[bus].location.above[3.75].forward_flat[3]>
      # define bus_look   <[bus_center].below[3.5]>
      #with armor stands
      - define bus_center <[bus].location.above[1.5].forward_flat[2.85]>
      #previously: 2.9
      - define bus_look   <[bus_center].below[2.5]>
      - define circle_points <[bus_center].points_around_y[points=360;radius=8.25]>
      - teleport <[cam]> <[circle_points].get[<[loop_index].mod[360].add[1]>].face[<[bus_look]>]> offthread_repeat:3
      - wait 1t

    - take slot:9
    - adjust <player> item_slot:1
    - cast SLOW_DIGGING remove
    - adjust <player> spectate:<player>
    - run dmodels_delete def.root_entity:<[bus]> if:<[bus].is_spawned>
    - remove <[cam]>

  drive_bus:
    # - [ Mode 1: First Person ] - #
    mode_1:

      #mount every player with 10 random players in the bus
      - foreach <[players].sub_lists[10]> as:group:
        - define available_seats <[total_seats]>
        #in case they were somehow invisible for everyone (most likely due to emotes)
        - invisible <[group]> false for:<[group]>
        #make those players only visible to that group
        - invisible <[group]> true for:<[players].exclude[<[group]>]>

        #mount the grouped players to random seats
        - foreach <[group]> as:passenger:
          - define r_seat <[available_seats].random>
          - mount <[passenger]>|<[r_seat]>
          - define available_seats:<-:<[r_seat]>

      - flag <[players]> fort.on_bus.loading:!
      - flag server fort.temp.bus.passengers:<[players]>

      #-bus driver
      ##not working for some reason
      - create PLAYER <&sp> <[drivers_seat_loc]> save:bus_driver
      - define bus_driver <entry[bus_driver].created_npc>

      - mount <[bus_driver]>|<[drivers_seat]>
      - flag server fort.temp.bus.driver:<[bus_driver]>

      - adjust <[bus_driver]> skin_blob:<script[nimnite_config].data_key[Spitfire_Skin]>
      - adjust <[bus_driver]> name_visible:false

      #trying this instead...
      - define seats       <[total_seats]>

      - define controllers <[total_controllers]>

      - repeat <[distance]>:

        - if <server.has_flag[fort.temp.cancel_bus]> || !<[bus].is_spawned>:
          - flag server fort.temp.cancel_bus:!
          - repeat stop

        - define passengers <server.flag[fort.temp.bus.passengers]>

        #if the next phase has started and the rest of the passengers need to get off
        #not in the first if check, so the bus still moves forwards a little after dropping players
        - if <server.flag[fort.temp.phase]> == grace_period && <[passengers].any>:
          - foreach <[passengers]> as:passenger:
            #- flag <[passenger]> fort.on_bus:!
            - teleport <[passenger]> <[passenger].location.below[1.5]>
            - run fort_glider_handler.fall player:<[passenger]>
          #not only removing it from passengers, in case players somehow fell off and they still have the flag
          - flag <server.online_players> fort.on_bus:!
          #- flag <[passengers]> fort.on_bus:!

          #remove invisibility
          - invisible <[passengers]> reset
          - flag server fort.temp.bus.passengers:<list[]>
          - define passengers <list[]>

        #-play battle bus wind sound
        #- playsound <[passengers]> sound:ITEM_ELYTRA_FLYING pitch:0.5 volume:0.15 if:<[value].mod[400].equals[1]>
        #i would make the "bass" beat too, but it'll be bad if tps drops
        - playsound <[passengers]> sound:ENTITY_MINECART_INSIDE volume:0.04 if:<[value].mod[110].equals[1]>

        - define new_loc <[bus_start].forward[<[value]>]>

        #teleport the display entity itself too (so it doesn't despawn, just every second)
        - teleport <[bus]> <[new_loc]> if:<[value].mod[20].equals[0]>

        - foreach <[controllers]> as:c:
          - teleport <[c]> <[new_loc].add[<[c].flag[vector_loc]>]>

        - foreach <[seats]> as:seat:
          - teleport <[seat]> <[new_loc].add[<[seat].flag[vector_loc]>]>

        - if <server.flag[fort.temp.phase]> == FALL && <[value].mod[30]> == 0:
          - actionbar <[jump_text]> targets:<[passengers]>

        - wait 1t

      #-remove everything
      - run dmodels_delete def.root_entity:<[bus]> if:<[bus].is_spawned>

      - foreach <server.flag[fort.temp.bus.seats]> as:seat:
        - remove <[seat]> if:<[seat].is_spawned>

      - foreach <server.flag[fort.temp.bus.controllers]> as:c:
        - remove <[c]> if:<[c].is_spawned>

      - remove <server.flag[fort.temp.bus.driver]>

      - flag server fort.temp.bus:!

    # - [ Mode 2: Rotating Camera ] - #
    #available definitions:
    # <[players]>
    # <[jump_text]>
    # <[distance]>
    # <[bus]>
    # <[bus_start]>
    # <[drivers_seat]>
    mode_2:

      # - [ Spawn Camera ] - #

      - define cam_start_loc <[bus_start].backward_flat[8]>
      - if !<[cam_start_loc].chunk.is_loaded>:
        - chunkload <[cam_start_loc].chunk> duration:5m
      - spawn <entity[armor_stand].with[invulnerable=true;force_no_persist=true]> <[cam_start_loc]> save:camera
      - define cam <entry[camera].spawned_entity>
      - flag server fort.temp.bus.camera:<[cam]>
      - invisible <[cam]> true

      # - [ Spawn bus center entity ] - #
      #default forward = 2.85
      - define bus_start_center <[bus].location.above[1.5].forward_flat[1.35]>
      - if !<[bus_start_center].chunk.is_loaded>:
        - chunkload <[bus_start_center].chunk> duration:5m
      - spawn <entity[item_display].with[scale=0.1,0.1,0.1;force_no_persist=true]> <[bus_start_center]> save:bus_center_entity
      - define bc_entity <entry[bus_center_entity].spawned_entity>
      - flag server fort.temp.bus.bus_center_entity:<[bc_entity]>
      - flag server fort.temp.bus.seats:->:<[drivers_seat]>
      - flag <[bc_entity]> vector_loc:<[bus_start_center].sub[<[bus].location>]>


      # - [ Spawn the NPCs ] = #

      # - ( Bus Driver ) - #
      - create PLAYER <&sp> <[drivers_seat_loc]> save:bus_driver
      - define bus_driver <entry[bus_driver].created_npc>

      - mount <[bus_driver]>|<[drivers_seat]>
      - flag server fort.temp.bus.driver:<[bus_driver]>
      #just adding this flag, for the despawns check
      - flag <[bus_driver]> fort.bus_driver

      - adjust <[bus_driver]> skin_blob:<script[nimnite_config].data_key[Spitfire_Skin]>
      - adjust <[bus_driver]> name_visible:false

      # - ( ~ The Chosen Ones ~ ) - #
      - define chosen_ones <[players].random[10]>
      - foreach <[chosen_ones]> as:p:
        - define seat   <[total_seats].get[<[loop_index]>]>
        - create PLAYER <[p].name> <[seat].location> save:p_npc_<[loop_index]>
        - define p_npc <entry[p_npc_<[loop_index]>].created_npc>
        - mount  <[p_npc]>|<[seat]>
        - adjust <[p_npc]> name_visible:false
        #name doesn't change the npc skins for some reason, so just to be safe
        - adjust <[p_npc]> skin_blob:<[p].skin_blob>
        - flag   <[p_npc]> fort.passenger_uuid:<[p].uuid>
        - define passenger_npcs:->:<[p_npc]>
        #i could just do it in the repeat, but i want it to be instant
        - flag server fort.temp.bus.passenger_npcs:->:<[p_npc]>

      ##problem: you can see the armor stands?
      #i can make it funny/cool and put a camera on its head?

      # - [ Player Spectating Setup ] - #

      - define thank "<&chr[1].font[item_name]><&7><element[Press].font[item_name]>
                      <&c><&l><&keybind[key.swapOffhand].font[item_name]> 
                      <&7><element[to thank the bus driver.].font[item_name]>"
      - define blank_item <item[paper].with[display=<[thank]>;custom_model_data=17]>

      - foreach <[players]> as:p:
        - mount <[p]>|<[bc_entity]>

      #safety
      - wait 8t
      - foreach <[players]> as:p:
        - adjust <[p]> spectate:<[cam]>
        - give <[blank_item]> slot:9 to:<[p].inventory>
        - adjust <[p]> item_slot:9

      #they have now loaded in (they STILL have the fort.on_bus flag)
      - flag <[players]> fort.on_bus.loading:!

      - define seats       <[total_seats]>
      - define controllers <[total_controllers]>

      - define bus_path_points <[bus_start].points_between[<[bus_start].forward[<[distance]>]>].distance[1.15]>
      - foreach <[bus_path_points]> as:point:

        - if <server.has_flag[fort.temp.cancel_bus]> || !<[bus].is_spawned>:
          - flag server fort.temp.cancel_bus:!
          - foreach stop

        - define players <server.online_players_flagged[fort.on_bus]>

        # - ( Automatic player drop off ) - #
        - if <server.flag[fort.temp.phase]> == grace_period:
          - foreach <[players]> as:p:
            - run fort_bus_handler.drop_player def.player:<[p]>

          - flag server fort.temp.bus.passenger_npcs:<list[]>
          - define passenger_npcs <list[]>

        - playsound <[players]> sound:ENTITY_MINECART_INSIDE volume:0.04 if:<[loop_index].mod[110].equals[1]>

        #teleport the display entity itself too (so it doesn't despawn, just every second)
        - teleport <[bus]> <[point]> if:<[loop_index].mod[20].equals[0]>
        - teleport <[bc_entity]> <[point].add[<[bc_entity].flag[vector_loc]>]>

        - foreach <[controllers]> as:c:
          - teleport <[c]> <[point].add[<[c].flag[vector_loc]>]>

        - foreach <[seats]> as:seat:
          - teleport <[seat]> <[point].add[<[seat].flag[vector_loc]>]>

        - if <server.flag[fort.temp.phase]> == FALL && <[loop_index].mod[30]> == 0:
          - actionbar <[jump_text]> targets:<[players]>

        # - ( Rotating camera ) - #
        #i think this means that all the players got off the bus, so might as well just remove the bus
        - if !<[bc_entity].is_spawned>:
          - foreach stop

        - define bus_center <[bc_entity].location>
        - define bus_look   <[bus_center].below[2.5]>
        #default radius = 8.25
        - define circle_points <[bus_center].points_around_y[points=360;radius=8.25]>
        - teleport <[cam]> <[circle_points].get[<[loop_index].mod[360].add[1]>].face[<[bus_look]>]> offthread_repeat:3

        - wait 1t

      #-remove everything
      - run dmodels_delete def.root_entity:<[bus]> if:<[bus].is_spawned>

      - foreach <server.flag[fort.temp.bus.seats]> as:seat:
        - remove <[seat]> if:<[seat].is_spawned>

      - foreach <server.flag[fort.temp.bus.controllers]> as:c:
        - remove <[c]> if:<[c].is_spawned>

      #for the npc to remove on despawns event
      - flag <[bus_driver]> fort:!
      - remove <server.flag[fort.temp.bus.driver]>

      #in case this is even possible (maybe if bus was cancelled before forcing everyone out)
      - remove <[passenger_npcs].filter[is_spawned]>

      - remove <[bus_driver]> if:<[bus_driver].is_spawned>

      - remove <[cam]> if:<[cam].is_spawned>

      - wait 1s
      - flag server fort.temp.bus:!