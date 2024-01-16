#
fix_world_flags:
  type: task
  debug: false
  script:

    #bottom left
    - define corner1 <location[-1024,-64,1024,nimnite_map]>
    #top right
    - define corner2 <location[1024,-120,-1024,nimnite_map]>

    - define map_cuboid <[corner1].to_cuboid[<[corner2]>]>

    - define queue <queue>
    - announce "<&b>[Nimnite] <&f>Restoring world flags in queue: <&a><[queue]>" to_console
    - announce "<&b>[Nimnite] <&f>Map chunk size: <&a><[map_cuboid].chunks.size.format_number>" to_console

    - announce "<&b>[Nimnite] <&f>Starting in 3 seconds..." to_console
    - wait 5s
    - flag <world[nimnite_map]> fort.floor_loot_locations:!
    - foreach ammo_box|chest as:c_type:
      - flag server fort.<[c_type]>.locations:!
      - flag <world[nimnite_map]> fort.<[c_type]>.locations:!
    #prev flag name
    - flag <world[nimnite_map]> fort.chests:!
    - flag <world[nimnite_map]> fort.ammo_boxes:!

    - define chunk_size <[map_cuboid].chunks.size>
    - foreach <[map_cuboid].chunks> as:chunk:
      - announce "<&b>[Nimnite] <&f>Restoring... <&e><[loop_index].div[<[chunk_size]>].mul[100].round><&f>%" to_console if:<[loop_index].mod[50].equals[0]>
      - chunkload <[chunk]> duration:5m

      #-restore floor loot
      - define floor_loot_locations <[chunk].blocks_flagged[fort.floor_loot_loc]>
      - foreach <[floor_loot_locations]> as:loc:
        #- announce "<&b>[Nimnite] <&f>Restoring floor loot at <[loc].simple>" to_console
        ##flag
        #- flag server fort.floor_loot_locations:->:<[loc]>
        - flag <world[nimnite_map]> fort.floor_loot_locations:->:<[loc]>
        #- announce "<&b>[Nimnite] <&f>Fixed floor loot at <[loc].simple>" to_console

      #-restore containers
      - foreach chest|ammo_box as:container_type:

        - define container_locs <[chunk].blocks_flagged[fort.<[container_type]>]>

        #- announce "<&b>[Nimnite] <&f>Restoring <&e><[container_type]><&r> data..." to_console

        - foreach <[container_locs]> as:loc:

          - define yaw <[loc].flag[fort.<[container_type]>.yaw].add[1]>

          - if <[loc].has_flag[fort.<[container_type]>.hitbox]> && <[loc].flag[fort.<[container_type]>.hitbox].is_spawned>:
            - remove <[loc].flag[fort.<[container_type]>.hitbox]>

          - spawn INTERACTION <[loc].center.below[0.5]> save:int
          - define int <entry[int].spawned_entity>
          - teleport <[int]> <[int].location.with_yaw[<[yaw]>]>
          - flag <[int]> fort.<[container_type]>.loc:<[loc]>
          - flag <[loc]> fort.<[container_type]>.hitbox:<[int]>

          - define width 1
          - define height 1

          - define model           <[loc].flag[fort.<[container_type]>.model]>
          - define text            <[loc].flag[fort.<[container_type]>.text]>

          #recalculating, since not all chests have this flag
          - if <[container_type]> == chest:
            - define p_loc      <[loc].with_yaw[<[yaw]>].forward[0.4]>
            - define gold_shine <[p_loc].left[0.5].points_between[<[p_loc].right[0.55]>].distance[0.1]>
            - flag <[int]> fort.chest.gold_shine:<[gold_shine]>

          #fix the hitbox rotation while we're at it
          - adjust <[model]> left_rotation:<quaternion[identity]>
          - teleport <[model]> <[model].location.with_yaw[<[yaw]>]>

          #text isn't spawned sometimes? restore it if isn't? nahhh im too lazy. when the problem appears ill do it
          - adjust <[text]> left_rotation:<quaternion[identity]>
          - teleport <[text]> <[text].location.below[<map[chest=0.21;ammo_box=0.18].get[<[container_type]>]>].with_yaw[<[yaw]>]>
          - adjust <[text]> scale:0.75,0.75,0.75

          ##flag
          - flag <world[nimnite_map]> fort.<[container_type]>.locations:->:<[loc]>
          #- announce "<&b>[Nimnite] <&f>Fixed <[container_type]> at <[loc].simple>" to_console
    ##very important save mech
    #this is what caused the shit to be bugged
    - adjust server save
    - announce "<&b>[Nimnite] <&f>World flag restoration <&a>complete<&f>!" to_console