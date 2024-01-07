fort_bus_handler:
  type: world
  debug: false
  events:

    on player damaged flagged:fort.on_bus:
    - determine cancelled

    on player exits vehicle flagged:fort.on_bus:
    #players can't drop off before FALL phase
    - if <server.flag[fort.temp.phase]> == BUS:
      - determine passively cancelled
      - stop

    #BLOCK_SHULKER_BOX_OPEN pitch:0 could work too
    #ENTITY_EVOKER_CAST_SPELL pitch:1.3
    - playsound <player> sound:BLOCK_CONDUIT_DEACTIVATE pitch:1.2 volume:0.25
    #- playsound <player> sound:BLOCK_NOTE_BLOCK_BASS pitch:0.75 volume:0.7
    #- playsound <player> sound:ITEM_TRIDENT_RETURN pitch:1.2 volume:0.8
    #- playsound <player> sound:ENTITY_VEX_AMBIENT pitch:1.5

    - flag player fort.on_bus:!
    - flag server fort.temp.bus.passengers:<-:<player>

    #this way, the sneak event doesn't fire twice and the glider doesn't immediately deply
    - flag player fort.bus_jumped duration:1s

    - teleport <player> <player.location.below[1.5]>
    - invisible reset

    - run fort_glider_handler.fall

  start_bus:


    - define center     <world[nimnite_map].spawn_location.with_y[220].with_pitch[0]>
    - define yaw        <util.random.int[0].to[360]>

    #default: 1152
    - define distance_from_center 1100
    #1152 is the real size, im gonna decrease it be a little
    - define bus_start  <[center].with_yaw[<[yaw]>].forward[<[distance_from_center]>].face[<[center]>]>
    - define yaw        <[bus_start].yaw>

    #-doing this in case the seats aren't spawned in correctly (if it has missing entities, so it doesn't break)

    #randomize this, or make it so players are in the same bus if they queued at the same time?
    - define players <server.online_players_flagged[fort]>

    - define busy_ready False
    - while <[busy_ready].not>:
      - inject fort_bus_handler.setup_bus

      - define seats_to_check <server.flag[fort.temp.bus.seats]>
      #if a SINGLE seat isn't spawned, then re-do the entire thing
      #(if i really wanted to, we could just check for which seat and just spawn that one, but this is way easier)
      - if <[seats_to_check].filter[is_spawned.not].is_empty> && <[bus].is_spawned>:
        - define busy_ready True
        #no need for while stop, but whatevs
        - while stop
      - else:
        - remove <[seats_to_check].filter[is_spawned]>
        - run dmodels_delete def.root_entity:<[bus]> if:<[bus].is_spawned>
        - define total_seats:!
        - flag server fort.temp.bus:!

      - wait 1t

    - define bus_parts <[bus].flag[dmodel_parts]>
    - foreach <[bus_parts]> as:part:
      #for some reason gotta offset the armor stand a little bit
      - define part_loc <[part].location.below[0.5].backward[2]>
      - spawn <entity[ARMOR_STAND].with[gravity=false;collidable=false;invulnerable=true;visible=false]> <[part_loc].below[1.48]> save:c_<[part]>
      - define controller <entry[c_<[part]>].spawned_entity>
      - mount <[part]>|<[controller]>

      - flag server fort.temp.bus.controllers:->:<[controller]>
      - define total_controllers:->:<[controller]>
      - flag <[controller]> vector_loc:<[part_loc].sub[<[bus_start]>]>
      #- wait 1t

    #-mount every player with 10 random players in the bus
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

    - flag <[players]> fort.on_bus
    - flag server fort.temp.bus.passengers:<[players]>

    #-bus driver
    ##not working for some reason
    - create PLAYER <&sp> <[drivers_seat_loc]> save:bus_driver
    - define bus_driver <entry[bus_driver].created_npc>

    - mount <[bus_driver]>|<[drivers_seat]>
    - flag server fort.temp.bus.driver:<[bus_driver]>

    - adjust <[bus_driver]> skin_blob:<script[nimnite_config].data_key[Spitfire_Skin]>
    - adjust <[bus_driver]> name_visible:false

    #logic for finding bus starting position
    #map is 2304x2304
    #2304/2 = 1152


    - define lb <element[<&l><&lb>].color[<color[72,0,0]>]>
    - define rb <element[<&l><&rb>].color[<color[72,0,0]>]>

    - define sneak_button <[lb]><element[<&l>SNEAK].color[<color[75,0,0]>]><[rb]>

    - define jump_text   "<element[<&l>PRESS].color[<color[71,0,0]>]> <[sneak_button]> <element[<&l>TO JUMP].color[<color[71,0,0]>]>"

    - define distance <[distance_from_center].mul[2]>

    ###the seats are sometimes "not spawned" ?
    #- define seats       <server.flag[fort.temp.bus.seats]>
    #trying this instead...
    - define seats       <[total_seats]>
    #- define controllers <server.flag[fort.temp.bus.controllers]>
    #trying this too
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
        #- push <[c]> origin:<[]> destination:<[new_loc].add[<[c].flag[vector_loc]>]> duration:1t

      - foreach <[seats]> as:seat:
        - teleport <[seat]> <[new_loc].add[<[seat].flag[vector_loc]>]>

      - if <server.flag[fort.temp.phase]> == FALL && <[value].mod[30]> == 0:
        - actionbar <[jump_text]> targets:<[passengers]>

      - wait 1t

    #- remove <[bus]> if:<[bus].is_spawned>
    - run dmodels_delete def.root_entity:<[bus]> if:<[bus].is_spawned>

    - foreach <server.flag[fort.temp.bus.seats]> as:seat:
      - remove <[seat]> if:<[seat].is_spawned>

    - foreach <server.flag[fort.temp.bus.controllers]> as:c:
      - remove <[c]> if:<[c].is_spawned>

    - remove <server.flag[fort.temp.bus.driver]>

    - flag server fort.temp.bus:!

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
      - chunkload <[bus_start].chunk> duration:30s
      - waituntil <[bus_start].chunk.is_loaded> rate:1s max:15s

    - run dmodels_spawn_model def.model_name:battle_bus def.location:<[bus_start]> save:bus
    - define bus <entry[bus].created_queue.determination.first||null>
    - run dmodels_set_scale def.root_entity:<[bus]> def.scale:1.3,1.3,1.3

    - flag server fort.temp.bus.model:<[bus]>

    - define seat_origin <[bus_start].below[1]>
    #<[bus_start].below[1]> (pre armor stand mounts)

    - define drivers_seat_loc <[seat_origin].above[1.65].left[0.71].below[1.2].backward[0.1]>
    - spawn <entity[item_display].with[scale=0.1,0.1,0.1]> <[drivers_seat_loc]> save:drivers_seat
    - define drivers_seat <entry[drivers_seat].spawned_entity>
    - flag server fort.temp.bus.drivers_seat:<[drivers_seat]>
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