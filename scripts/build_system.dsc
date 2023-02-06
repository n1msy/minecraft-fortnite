
##turn this into a proc that checks if you can place or not


build_tiles:
  type: task
  debug: false
  scripts:
  - narrate "set the build tiles for each structure"

  floor:

        - define target_loc <[eye_loc].ray_trace[default=air;range=4;return=block]>

        # - / Find the nearest "center" to place the 5x5 floor / - #
        - define closest_center <[target_loc].find_blocks.within[3].parse_tag[<[parse_value].with_x[<proc[round4].context[<[parse_value].x>]>].with_z[<proc[round4].context[<[parse_value].z>]>]>].sort_by_number[distance[<[target_loc]>]].first||null>

        # - / Find nearest floor center to calculate where to position the next tile / - #
        - define closest_tile_center <[target_loc].find_blocks_flagged[build].within[6].filter[flag[build.type].equals[floor]].parse[flag[build.center]].sort_by_number[distance[<[target_loc]>]].first||null>


        # - / if there are any nearby tiles, automatically "snap" the player's selected center to the nearby tile's y / - #

        # -> If there IS a nearby tile, position the Y axis of the nearest center with the Y axis of the nearest tile ->
        - if <[closest_tile_center]> != null:
          - define closest_center <[closest_center].with_y[<[closest_tile_center].y.add[1]>]>
        # -> Otherwise if they're pointing in the air, get the block closest to the ground from where you're looking ->
        - else if <[target_loc].material.name> == air:
          - define closest_center <[closest_center].with_pitch[90].ray_trace>
        # -> Otherwise, they're most likely pointing to the ground, so move the Y up 1 #
        - else:
          - define closest_center <[closest_center].with_y[<[target_loc].y.add[1]>]>

        # -> If the closest center is still pointing at the ground, move one up #
        - if <[closest_center].material.name> != air:
          - define closest_center <[closest_center].above>

        - define build_loc <[target_loc].with_y[<[closest_center].y.sub[1]>]>

        - define rounded_x <proc[round4].context[<[build_loc].x>]>
        - define rounded_z <proc[round4].context[<[build_loc].z>]>

        - define tile_center <[origin].add[<[rounded_x]>,<[build_loc].y>,<[rounded_z]>]>

        #if there's a build on left/right/forward/backward, then it's connected to another tile, and it's buildable
        #mostly used to prevent diagonal building, but is also useful for checking if they can place on walls
        - define can_build False
        - foreach <location[3,0,0]>|<location[-3,0,0]>|<location[0,0,3]>|<location[0,0,-3]> as:dir:
          - if <[tile_center].add[<[dir]>].material.name> != air:
            - define can_build True
            - foreach stop

        #if the tile has a block there and it's NOT a floor
        - if <[tile_center].material.name> != AIR && !<[tile_center].has_flag[build]> || <[tile_center].flag[build.type]> != FLOOR:
          - define can_build True
          #move the build 1 down, since they're building on top of the ground
          - define tile_center <[tile_center].above>

        #so in case it's doing the ray_trace thing when there's no other nearby tiles, check if the distance is valid
        - if <[tile_center].distance[<[loc]>].vertical> > 6:
          - define can_build False

        #if there's already a structure there, don't show up
        - if <[tile_center].has_flag[build]>:
          - define can_build False

        - define tile <[tile_center].to_cuboid[<[tile_center]>].expand[2,0,2]>
        - define blocks <[tile].blocks>

        #check 1: if there are ANY non-air blocks in the tile
        #check 2: if there's ANY non-air block that does NOT have the breakable flag

        - define blocks_in_way False
        - if <[blocks].filter[material.name.equals[AIR].not].any> && <[blocks].filter[material.name.equals[AIR].not].filter[has_flag[breakable].not].any>:
          - define can_build False
          - define blocks_in_way True

        - if <[can_build]>:
          - debugblock <[blocks]> d:2t color:0,255,0,128
          - flag player build.struct:<[tile]>
        - else:
          - flag player build.struct:!
          - if <[blocks_in_way]>:
            - debugblock <[blocks]> d:2t color:0,0,0,128

  wall:

      - define can_build True

      - define target_loc <[eye_loc].forward[0.5]>

      - define x <proc[round4].context[<[target_loc].x>]>
      - define z <proc[round4].context[<[target_loc].z>]>
      - define closest_center <[target_loc].with_x[<[x]>].with_z[<[z]>].with_pitch[90].ray_trace[return=block]>

      - define yaw <map[North=180;South=0;West=90;East=-90].get[<[eye_loc].yaw.simple>]>
      - define bottom_center <[closest_center].with_yaw[<[yaw]>].forward_flat[2]>

      #- playeffect effect:FLAME at:<[closest_floor_center].above> offset:0

      - define tile <[bottom_center].left[2].to_cuboid[<[bottom_center].right[2].above[4]>]>

      #if there's a singular build that the tile is overlapping, go to the highest point of the build
      - if <[tile].blocks.filter[has_flag[build]].any>:
        - define current_tile <[tile].blocks.filter[has_flag[build]].first.flag[build.structure]>
        - define bottom_center <[bottom_center].with_y[<[current_tile].max.y>]>
        - define tile <[bottom_center].left[2].to_cuboid[<[bottom_center].right[2].above[4]>]>
      - else:
        #move everything 1 up if it's not on top of a build
        - define tile <[tile].shift[0,1,0]>

      - define blocks <[tile].blocks>

      #if a wall is already placed there (just by checking the center), it's not possible to place a wall there anymore
      - if <[tile].center.has_flag[build]>:
        - define can_build False

      #check 1: if there are ANY non-air blocks in the tile
      #check 2: if there's ANY non-air block that does NOT have the breakable flag

      - define blocks_in_way False
      - if <[blocks].filter[material.name.equals[AIR].not].any> && <[blocks].filter[material.name.equals[AIR].not].filter[has_flag[breakable].not].any>:
        - define can_build False
        - define blocks_in_way True

      - if <[can_build]>:
        - debugblock <[blocks]> d:2t color:0,255,0,128
        - flag player build.struct:<[tile]>
      - else:
        - flag player build.struct:!
        - if <[blocks_in_way]>:
          - debugblock <[blocks]> d:2t color:0,0,0,128

        # - / Find the nearest "center" to place the 5x5 WALL / - #
       # - define closest_center <[target_loc].find_blocks.within[3].parse_tag[<[parse_value].with_x[<proc[round4].context[<[parse_value].x>]>].with_z[<proc[round4].context[<[parse_value].z>]>]>].sort_by_number[distance[<[target_loc]>]].first||null>

        # - / Find nearest WALL center to calculate where to position the next tile / - #
       # - define nearest_wall_center <[target_loc].find_blocks_flagged[build].within[6].filter[flag[build.type].equals[wall]].parse[flag[build.center]].sort_by_number[distance[<[target_loc]>]].first||null>

        # - / if there are any nearby tiles, automatically "snap" the player's selected center to the nearby tile's y / - #

        # -> If there IS a nearby tile, position the Y axis of the nearest center with the Y axis of the nearest tile ->
       # - if <[nearest_wall_center]> != null:
       #   - define closest_center <[closest_center].with_y[<[nearest_wall_center].y.add[1]>]>
        # -> Otherwise if they're pointing in the air, get the block closest to the ground from where you're looking ->
       # - else if <[target_loc].material.name> == air:
      #    - define closest_center <[closest_center].with_pitch[90].ray_trace>
        # -> Otherwise, they're most likely pointing to the ground, so move the Y up 1 #
       # - else:
       #   - define closest_center <[closest_center].with_y[<[target_loc].y.add[1]>]>

        # -> If the closest center is still pointing at the ground, move one up #
       # - if <[closest_center].material.name> != air:
       #   - define closest_center <[closest_center].above>

       # - define build_loc <[target_loc].with_y[<[closest_center].y.sub[1]>]>

       # - define rounded_x <proc[round4].context[<[build_loc].x>]>
       # - define rounded_z <proc[round4].context[<[build_loc].z>]>

       # - define yaw <map[North=180;South=0;West=90;East=-90].get[<[eye_loc].yaw.simple>]>

       # - define tile_center <[origin].add[<[rounded_x]>,<[build_loc].y>,<[rounded_z]>].with_yaw[<[yaw]>].forward_flat[2].above[2]>

        #if there's a build on left/right/forward/backward, then it's connected to another tile, and it's buildable
        #mostly used to prevent diagonal building, but is also useful for checking if they can place on walls
        #- define can_build False
       # - foreach <[tile_center].left[3]>|<[tile_center].right[3]>|<[tile_center].above[3]>|<[tile_center].below[3]> as:check_loc:
        #  - if <[check_loc].material.name> != air:
        #    - define can_build True
           # - foreach stop

        #if the tile has a block there and it's NOT a build
      #  - if <[tile_center].material.name> != AIR && !<[tile_center].has_flag[build]>:
          #- define can_build True
          #move the build 1 down, since they're building on top of the ground
         # - define tile_center <[tile_center].above>

        #so in case it's doing the ray_trace thing when there's no other nearby tiles, check if the distance is valid
     #   - if <[tile_center].distance[<[loc]>].vertical> > 6:
     #     - define can_build False

        #if there's already a structure there, don't show up
    #    - if <[tile_center].has_flag[build]>:
    #      - define can_build False

      #  - define tile <[tile_center].below[2].left[2].to_cuboid[<[tile_center].above[2].right[2]>]>
      #  - define blocks <[tile].blocks>

        #check 1: if there are ANY non-air blocks in the tile
        #check 2: if there's ANY non-air block that does NOT have the breakable flag

      #  - define blocks_in_way False
      #  - if <[blocks].filter[material.name.equals[AIR].not].any> && <[blocks].filter[material.name.equals[AIR].not].filter[has_flag[breakable].not].any>:
      #    - define can_build False
      #    - define blocks_in_way True

      #  - if <[can_build]>:
      #    - debugblock <[blocks]> d:2t color:0,255,0,128
     #     - flag player build.struct:<[tile]>
     #   - else:
     #     - flag player build.struct:!
    #      - if <[blocks_in_way]>:
      #      - debugblock <[blocks]> d:2t color:0,0,0,128

      #- define target_loc <[eye_loc].ray_trace[default=air;range=1.75;return=block]>

      #make target_loc the player's location
   #   - define target_loc <[eye_loc].forward[0.6]>

      #- define closest_center <[target_loc].find_blocks.within[3].parse_tag[<[parse_value].with_x[<proc[round4].context[<[parse_value].x>]>].with_z[<proc[round4].context[<[parse_value].z>]>]>].sort_by_number[distance[<[target_loc]>]].first||null>

      #this prevents irregular-angled walls
   #   - define yaw <map[North=180;South=0;West=90;East=-90].get[<[eye_loc].yaw.simple>]>

    #  - define x <proc[round4].context[<[target_loc].x>]>
     # - define z <proc[round4].context[<[target_loc].z>]>

      #doing forward_flat[2] at the end because they're walls and aren't actually in the center like floors
      #the range of ray_trace is [4] so it doesn't go all the way down
   #   - define bottom_center <[target_loc].with_x[<[x]>].with_z[<[z]>].with_pitch[90].ray_trace[return=block;range=4;default=air].with_yaw[<[yaw]>].forward_flat[2]>

      #if the material is air, then the player is aiming at the edge that exceeds the ray_trace range
   #   - if <[bottom_center].material.name> != air:
     #   - define can_build True

        #get the highest block
     #   - if !<[bottom_center].has_flag[build]>:
     #     - repeat 3:
     #       - if <[bottom_center].above[<[value]>].material.name> == air:
     #         - define bottom_center <[bottom_center].above[<[value]>]>
    #          - repeat stop
        #if there's already a build there
        #(checking above the bottom center in case its a floor block)
     #   - else if <[bottom_center].above.has_flag[build]>:
     #     - define current_center <[bottom_center].above.flag[build.center]>
          #- define above_center <[current_center].above[5]>

      #    - if !<[above_center].has_flag[build]> && !<[eye_loc].ray_trace[return=block;default=air;range=4].flag[build.type].equals[wall]||false>:
     #       - define bottom_center <[bottom_center].with_y[<[current_center].flag[build.structure].max.y>]>
      #    - else:
       #     - define can_build False

     #   - playeffect effect:FLAME at:<[bottom_center]> offset:0

     #   - define tile <[bottom_center].left[2].to_cuboid[<[bottom_center].right[2].above[4]>]>

     #  - define blocks <[tile].blocks>

     #   - define blocks_in_way False
     #   - if <[blocks].filter[material.name.equals[AIR].not].any> && <[blocks].filter[material.name.equals[AIR].not].filter[has_flag[breakable].not].any>:
     #     - define can_build False
    #      - define blocks_in_way True

     #   - if <[can_build]>:
    #      - debugblock <[blocks]> d:2t color:0,255,0,128
    #      - flag player build.struct:<[tile]>
    #    - else:
   #       - flag player build.struct:!
     #     - if <[blocks_in_way]>:
      #      - debugblock <[blocks]> d:2t color:0,0,0,128

     # - else:
       # - flag player build.struct:!

       # - define can_build True

        #get the highest point out of all 5 y levels based on the bottom
       # - if !<[bottom_center].has_flag[build]>:
       #   - define bottom_center <[bottom_center].above[2].with_pitch[90].ray_trace[return=block].above.with_yaw[<[yaw]>]>

        #if a player is trying to put a wall on top of a wall, get the wall *after* that one
       # - else:
         # - define current_center <[bottom_center].flag[build.center]>
         # - define above_center <[current_center].above[5]>

         # - if !<[above_center].has_flag[build]> && <[eye_loc].forward[4].distance[<[current_center]>].vertical> > <[eye_loc].forward[4].distance[<[above_center]>].vertical>:
         #   - define bottom_center <[bottom_center].with_y[<[current_center].flag[build.structure].max.y>]>
         # - else:
           # - define can_build False
        #move everything 1 up if the wall isn't being placed on a floor
      #  - if !<[bottom_center].has_flag[build]> && <[bottom_center].material.name> != air:
      #   - define bottom_center <[bottom_center].above>

      #  - define tile <[bottom_center].left[2].to_cuboid[<[bottom_center].right[2].above[4]>]>

      #  - define blocks <[tile].blocks>

      # - define can_build True

        #so they can't place walls in the air
      # - if <[bottom_center].below.material.name> == air:
      #   - define can_build False

      # - define blocks_in_way False
      # - if <[blocks].filter[material.name.equals[AIR].not].any> && <[blocks].filter[material.name.equals[AIR].not].filter[has_flag[breakable].not].any>:
      #   - define can_build False
      #   - define blocks_in_way True


      # - if <[closest_tile_center]> != null:
      #    - define closest_center <[closest_tile_center].above>
        #if they're pointing in the air
      #  - else if <[target_loc].material.name> == air:
      #    - define closest_center <[closest_center].with_pitch[90].ray_trace>
        #otherwise, they're most likely pointing to the ground, so calculate it 1 up
      #  - else:
      #    - define closest_center <[closest_center].with_y[<[target_loc].y.add[1]>]>

      # - if <[closest_center].material.name> != air:
      #   - define closest_center <[closest_center].above>

        #default is true for walls
      #  - define can_build True

      # - define build_loc <[target_loc].with_y[<[closest_center].y.sub[1]>]>
      # - define rounded_x <proc[round4].context[<[build_loc].x>]>
      # - define rounded_z <proc[round4].context[<[build_loc].z>]>
      #  - define tile_center <[origin].add[<[rounded_x]>,<[build_loc].y>,<[rounded_z]>]>

        #if the tile has a block there and it's NOT a floor
      #  - if <[tile_center].material.name> != AIR && !<[tile_center].has_flag[build]> || <[tile_center].flag[build.type]> != FLOOR:
      #    - define can_build True
          #move the build 1 down, since they're building on top of the ground
      #    - define tile_center <[tile_center].above>

      #  - define yaw <map[North=180;South=0;West=90;East=-90].get[<[eye_loc].yaw.simple>]>
      #  - define tile_center <[tile_center].with_yaw[<[yaw]>].forward[2].above[2]>

      #  - define tile <[tile_center].left[2].below[2].to_cuboid[<[tile_center].right[2].above[2]>]>

      #  - define blocks <[tile].blocks>

        #third thing checks if only the blocks "in the way" are structures
      # - define blocks_in_way False
      # - if <[blocks].filter[material.name.equals[AIR].not].any> && <[blocks].filter[material.name.equals[AIR].not].filter[has_flag[breakable].not].any>:
      #   - define can_build False
      #   - define blocks_in_way True


round4:
  type: procedure
  definitions: i
  debug: false
  script:
  - determine <element[<element[<[i]>].div[4]>].round.mul[4]>

build:
  type: task
  debug: false
  script:
  - if <player.has_flag[build]>:
    - flag player build:!
    - narrate "<&c>build removed"
    - stop

  - define world <player.world.name>
  - define origin <location[0,0,0,<[world]>]>

  - flag player build


  - while <player.is_online> && <player.has_flag[build]>:
    - define eye_loc <player.eye_location>

    - define loc <player.location>
    #doing ray_trace in case they jump, so they can still build and jump
    #- define loc <player.location.with_pitch[90].ray_trace[range=3;return=block;default=air].with_yaw[<[eye_loc].yaw>]>

    #- define yaw <map[North=90;South=-90;West=0;East=-180].get[<[eye_loc].yaw.simple>]>
    - choose <player.held_item_slot>:
      - case 1:
        - actionbar wall
        - flag player build.type:wall
        - inject build_tiles.wall

      - case 2:
        - actionbar floor
        - flag player build.type:floor
        - inject build_tiles.floor

      - case 3:
        - actionbar stair
      - case 4:
        - actionbar pyramid

    - wait 1t

  - flag player build:!

build_system_handler:
  type: world
  debug: false
  events:
    on player left clicks block flagged:build.struct:
    - determine passively cancelled
    #wood health - 150
    #stone health - 400
    #metal health - 600
    - define material wood

    - define build <player.flag[build.struct]>
    - define blocks <[build].blocks>

    - modifyblock <[blocks]> oak_planks

    #this way, already placed structures such as intersecting walls and floors wont be overrided when the blocks are removed

    - flag <[blocks]> build.center:<[build].center>
    - flag <[blocks]> build.health:<script[nimnite_config].data_key[materials.<[material]>.hp]>
    - flag <[blocks]> build.type:<player.flag[build.type]>
    #the cuboid
    - flag <[blocks]> build.structure:<[build]>
    - flag <[blocks]> breakable

    on player right clicks block location_flagged:build.structure flagged:build:
    - determine passively cancelled
    - define loc <context.location>
    #cuboid
    - define tile <[loc].flag[build.structure]>
    - define tile_center <[loc].flag[build.center]>
    #floor/wall/stair/pyramid
    - define type <[loc].flag[build.type]>
    - define total_blocks <[tile].blocks>

    #deduplicating this
    - define closest_tiles <[tile_center].find_blocks_flagged[build].within[3].parse[flag[build.center]].sort_by_number[distance[<[tile_center]>]].parse[flag[build.structure]].deduplicate>

    - foreach <[closest_tiles]> as:other_tile:
      - if !<[tile].intersects[<[other_tile]>]>:
        - foreach next
      - define connectors <[tile].intersection[<[other_tile]>].blocks>
      #swap the connectors to whatever is already placed
      - flag <[connectors]> build:<[other_tile].center.flag[build]>

    #checking the build centers instead of type, so the connectors between walls can work with this too
    - define actual_blocks <[tile].blocks.filter[flag[build.center].equals[<[tile_center]>]]>

    - modifyblock <[actual_blocks]> air
    - flag <[actual_blocks]> build:!