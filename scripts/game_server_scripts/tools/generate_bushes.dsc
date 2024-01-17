generate_bushes:
  type: task
  debug: false
  script:

    #bottom left
    - define corner1 <location[-1024,-64,1024,nimnite_map]>
    #top right
    - define corner2 <location[1024,-120,-1024,nimnite_map]>

    - define map_cuboid <[corner1].to_cuboid[<[corner2]>]>

    - define queue <queue>
    - announce "<&b>[Nimnite] <&f>Setting bushes in queue: <&a><[queue]>" to_console
    - announce "<&b>[Nimnite] <&f>Map chunk size: <&a><[map_cuboid].chunks.size.format_number>" to_console
    - announce "<&b>[Nimnite] <&f>Starting in 3 seconds..." to_console

    - define bush_size 1.27

    - define bush_ent <entity[item_display].with[item=<item[leather_helmet].with[custom_model_data=10;color=black]>;scale=<[bush_size]>,<[bush_size]>,<[bush_size]>]>

    - define spawn_chance 25

    #prev flag name
    - flag <world[nimnite_map]> fort.bushes:!

    - define chunk_size <[map_cuboid].chunks.size>
    - foreach <[map_cuboid].chunks> as:chunk:
      - chunkload <[chunk]> duration:1m
      - define current_bushes <[chunk].entities[item_display].filter[has_flag[fort.bush]]>
      - remove <[current_bushes]>

      - define available_bush_locations <[chunk].surface_blocks.filter[material.name.equals[grass_block]].filter[above.material.name.equals[air]]>
      #if this is somehow possible
      - if <[available_bush_locations].is_empty>:
        - foreach next

      #-frequency
      #just set it to 1 per chunk for now
      - define bush_qty <util.random.int[1].to[1]>

      - define bush_locations <[chunk].surface_blocks.filter[material.name.equals[grass_block]].filter[above.material.name.equals[air]].random[<[bush_qty]>]>
      - foreach <[bush_locations]> as:bush_loc:
        - if <util.random_chance[<element[100].sub[<[spawn_chance]>]>]>:
          - foreach next

        - define angle <util.random.int[1].to[180].to_radians>
        - spawn <[bush_ent]> <[bush_loc].above[1.6]> save:bush
        - define bush <entry[bush].spawned_entity>
        #randomize rotation
        - teleport <[bush]> <[bush].location.with_yaw[<util.random.int[0].to[360]>]>

        - flag <[bush]> fort.bush
        - flag <world[nimnite_map]> fort.bushes:->:<[bush]>

      - announce "<&b>[Nimnite] <&f>Placing bushes... <&e><[loop_index].div[<[chunk_size]>].mul[100].round><&f>%" to_console if:<[loop_index].mod[100].equals[0]>
      - wait 1t if:<[loop_index].mod[100].equals[0]>

    - adjust server save
    - announce "<&b>[Nimnite] <&f>Generated <&a><world[nimnite_map].flag[fort.bushes].size> <&f>bushes." to_console