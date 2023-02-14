
##when you break down a whole structure, sometimes it doesn't completely break down, but it should be fine for now
##minor problem: can't build walls on the sides of actual minecraft structures (ie mountain)

build_tiles:
  type: task
  debug: false
  scripts:
  - narrate "set the build tiles for each structure"

  floor:

        - define range 1.5

        - define can_build False

        - define target_loc <[eye_loc].ray_trace[default=air;range=<[range]>]>

        - define x <proc[round4].context[<[target_loc].x>]>
        - define z <proc[round4].context[<[target_loc].z>]>

        #find the bottom center of the ENTIRE tower
        - define closest_center <[target_loc].with_x[<[x]>].with_z[<[z]>].with_y[<[eye_loc].y>].with_pitch[90].ray_trace>
        #meaning the floor AND stair doesn't count as an actual block during ray_trace
        - if <[closest_center].below.has_flag[build]>:
          #doing .min.y and not just sub[1] to account for stairs too
          - define y <[closest_center].below.flag[build.structure].min.y>
          - define closest_center <[closest_center].with_y[<[y]>]>

        #how much to add the y by (rounded)
        - define add_y <proc[round4].context[<[target_loc].forward[2].distance[<[closest_center]>].vertical.sub[1]>]>
        - define add_y <[add_y].is[LESS].than[0].if_true[0].if_false[<[add_y]>]>

        #this center is the center that would be anywhere you point (isn't grounded)
        - define free_center <[closest_center].above[<[add_y]>]>
        - define grounded_center <[closest_center]>

        #if it's connected to anything else
        #checks: left, right, forward, backward
        - if <[free_center].left[2].has_flag[build]> || <[free_center].right[2].has_flag[build]> || <[free_center].forward_flat[2].has_flag[build]> || <[free_center].backward_flat[2].has_flag[build]>:
          - define tile <[free_center].to_cuboid[<[free_center]>].expand[2,0,2]>
        - else:
          - define tile <[grounded_center].to_cuboid[<[grounded_center]>].expand[2,0,2]>

        - define blocks <[tile].blocks>

        - flag player build.struct:<[tile]>

        #can place:
        - debugblock <[blocks]> d:2t color:0,255,0,128
        #cannot place:
        #- debugblock <[blocks]> d:2t color:0,0,0,128

  wall:

      - define range 1

      - define can_build False

      - define target_loc <[eye_loc].ray_trace[default=air;range=<[range]>]>

      - define x <proc[round4].context[<[target_loc].x>]>
      - define z <proc[round4].context[<[target_loc].z>]>

      #find the bottom center of the ENTIRE tower
      - define closest_center <[target_loc].with_x[<[x]>].with_z[<[z]>].with_y[<[eye_loc].y>].with_pitch[90].ray_trace>
      #meaning the floor AND stair doesn't count as an actual block during ray_trace
      - if <[closest_center].below.has_flag[build]>:
        #doing .min.y and not just sub[1] to account for stairs too
        - define y <[closest_center].below.flag[build.structure].min.y>
        - define closest_center <[closest_center].with_y[<[y]>]>

      - define add_y <proc[round4].context[<[target_loc].forward[4].distance[<[closest_center]>].vertical.sub[2.5]>]>
      - define add_y <[add_y].is[LESS].than[0].if_true[0].if_false[<[add_y]>]>

      - define yaw <map[North=180;South=0;West=90;East=-90].get[<[eye_loc].yaw.simple>]>

      - define free_center <[closest_center].above[<[add_y]>].with_yaw[<[yaw]>].forward_flat[2].above[2]>
      - define grounded_center <[closest_center].with_yaw[<[yaw]>].forward_flat[2].above[2]>

      #- playeffect effect:FLAME at:<[free_center]> offset:0

      #checks: left, right, above, below
      - if <[free_center].left[2].has_flag[build]> || <[free_center].right[2].has_flag[build]> || <[free_center].above[2].has_flag[build]> || <[free_center].below[2].has_flag[build]>:
        - define tile <[free_center].below[2].left[2].to_cuboid[<[free_center].above[2].right[2]>]>
      - else:
        - define tile <[grounded_center].below[2].left[2].to_cuboid[<[grounded_center].above[2].right[2]>]>

      - define blocks <[tile].blocks>

      - flag player build.struct:<[tile]>

      #can place:
      - debugblock <[blocks]> d:2t color:0,255,0,128

      # - "can place" check

    #  - define blocks <[tile].blocks>
      #making sure there's either all air in that area or any thing being placed there is breakable
    #  - if <[blocks].filter[material.name.equals[AIR].not].is_empty> || <[blocks].filter[material.name.equals[AIR].not].filter[has_flag[breakable].not].is_empty>:
    #    - define can_build True
    #    - define blocks_in_way False
    #  - else:
    #    - define blocks_in_way True

     # - define center <[tile].center.with_yaw[<[yaw]>]>
      #it there's already a build there
    #  - if <[center].has_flag[build]>:
    #    - define can_build False

      #if too far
    #  - define no_preview:!
     # - if <[center].distance[<[target_loc]>].vertical> > 10:
       # - define can_build False
     #   - define no_preview True

     # - define blocks <[tile].blocks>
     # - if <[can_build]>:
      #  - debugblock <[blocks]> d:2t color:0,255,0,128
     #   - flag player build.struct:<[tile]>
     # - else:
     #   - flag player build.struct:!
        #- if <[blocks_in_way]>:
      #  - if !<[no_preview].exists>:
     #     - debugblock <[blocks]> d:2t color:0,0,0,128

  stair:

        - define range 2

        - define can_build False

        - define target_loc <[eye_loc].ray_trace[default=air;range=<[range]>]>

        - define x <proc[round4].context[<[target_loc].x>]>
        - define z <proc[round4].context[<[target_loc].z>]>

        #find the bottom center of the ENTIRE tower
        - define closest_center <[target_loc].with_x[<[x]>].with_z[<[z]>].with_y[<[eye_loc].y>].with_pitch[90].ray_trace>

        #meaning the floor AND stair doesn't count as an actual block during ray_trace
        - if <[closest_center].below.has_flag[build]>:
          #doing .min.y and not just sub[1] to account for stairs too
          - define y <[closest_center].below.flag[build.structure].min.y.add[2]>
          - define closest_center <[closest_center].with_y[<[y]>]>
        - else:
          #above 2 because it's a 2x2x2 cuboid
          - define closest_center <[closest_center].above[2]>

        #how much to add the y by (rounded)
        - define add_y <proc[round4].context[<[target_loc].forward[2].distance[<[closest_center]>].vertical.sub[1]>]>
        - define add_y <[add_y].is[LESS].than[0].if_true[0].if_false[<[add_y]>]>

        - define yaw <map[North=180;South=0;West=90;East=-90].get[<[eye_loc].yaw.simple>]>

        #this center is the center that would be anywhere you point (isn't grounded)
        - define free_center <[closest_center].above[<[add_y]>].with_yaw[<[yaw]>]>
        - define grounded_center <[closest_center].with_yaw[<[yaw]>]>

        - define connected False
        #checks: left, right, forward, backward, above, below, below 2 AND backward 2
        - foreach <[free_center].left[2]>|<[free_center].right[2]>|<[free_center].forward_flat[2]>|<[free_center].backward_flat[2]>|<[free_center].above[2]>|<[free_center].below[2]>|<[free_center].below[2].backward_flat[2]> as:check_loc:
          #second check is for conditions such as: stair in front of a stair
          - if <[check_loc].has_flag[build]> && <[check_loc].material.name> != air:
            - define connected True
            - foreach stop

        - if <[connected]>:
          - define tile <[free_center].to_cuboid[<[free_center]>].expand[2]>
        - else:
          - define tile <[grounded_center].to_cuboid[<[grounded_center]>].expand[2]>

        - define yaw <map[North=180;South=0;West=90;East=-90].get[<[eye_loc].yaw.simple>]>
        - define center <[tile].center.with_yaw[<[yaw]>]>

        - flag player build.struct:<[tile]>

        - define display_blocks <proc[stair_blocks_gen].context[<[center]>]>
        - debugblock <[display_blocks]> d:2t color:0,255,0,128


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
        - flag player build.type:wall
        - inject build_tiles.wall

      - case 2:
        - actionbar floor
        - flag player build.type:floor
        - inject build_tiles.floor

      - case 3:
        - actionbar stair
        - flag player build.type:stair
        - inject build_tiles.stair
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

    - define type wood

    - define yaw <map[North=180;South=0;West=90;East=-90].get[<player.eye_location.yaw.simple>]>
    - define tile <player.flag[build.struct]>
    - define center <[tile].center.with_yaw[<[yaw]>]>

    - if <player.flag[build.type]> == stair:
      - define set_blocks <proc[stair_blocks_gen].context[<[center]>]>
      - define material oak_stairs[direction=<player.eye_location.yaw.simple>]

      #has_flag[build].not so it doesn't override walls or floors
      - define set_blocks <[set_blocks].filter[has_flag[build].not]>
      - define blocks <[tile].blocks.filter[has_flag[build].not]>
    - else:
      - define material oak_planks
      - define blocks <[tile].blocks>
      - define set_blocks <[blocks]>

    - modifyblock <[set_blocks]> <[material]>

    - flag <[blocks]> build.center:<[center]>
    - flag <[blocks]> build.health:<script[nimnite_config].data_key[materials.<[type]>.hp]>
    - flag <[blocks]> build.type:<player.flag[build.type]>
    #the cuboid
    - flag <[blocks]> build.structure:<[tile]>
    - flag <[blocks]> breakable

    #the connected tiles are the new placed wall's ROOT
    - define connected_roots <proc[find_connected_tiles].context[<[center]>]>

    - if <[connected_roots].any>:
      - flag <[blocks]> build.roots:<[connected_roots]>

    - foreach <[connected_roots]> as:root:
      - flag <[root].blocks> build.shoots:->:<[tile]>

    on player right clicks block location_flagged:build.structure flagged:build:
    - determine passively cancelled
    - define loc <context.location>
    #cuboid
    - define tile <[loc].flag[build.structure]>
    - define tile_center <[loc].flag[build.center]>
    #floor/wall/stair/pyramid
    - define type <[loc].flag[build.type]>
    - define total_blocks <[tile].blocks>


    - define connected_total <[tile_center].find_blocks_flagged[build.center].within[4].parse[flag[build.center]].deduplicate.parse[flag[build.structure]].filter[intersects[<[tile]>]].exclude[<[tile]>]>

    - define connected_tiles <[connected_total].filter[center.flag[build.type].equals[stair].not]>
    - define connected_stairs_and_pyramids <[connected_total].filter[center.flag[build.type].equals[floor].not].filter[center.flag[build.type].equals[wall].not]>

    #-walls/floors
    - foreach <[connected_tiles]> as:other_tile:
      - define connectors <[tile].intersection[<[other_tile]>].blocks>
      #swap the connectors to whatever is already placed
      - flag <[connectors]> build:<[other_tile].center.flag[build]>

    #-stairs/
    - foreach <[connected_stairs_and_pyramids]> as:other_tile:
        - define connectors <[tile].intersection[<[other_tile]>].blocks>

        #-needs updating in the future
        - define material <[other_tile].center.material>
        - define stair_blocks <proc[stair_blocks_gen].context[<[other_tile].center.flag[build.center]>].parse[center]>
        - define connectors <[connectors].filter_tag[<[stair_blocks].contains[<[filter_value].center>]>].filter[flag[build.structure].equals[<[tile]>]]>
        #- playeffect effect:FLAME offset:0 at:<[connectors]>
        #replace the block with the stair
        - modifyblock <[connectors]> <[material]>
        - flag <[connectors]> build:<[other_tile].center.flag[build]>

    - define shoots <[tile_center].flag[build.shoots]||<list[]>>


    #checking the build centers instead of type, so the connectors between walls can work with this too
    - define actual_blocks <[tile].blocks.filter[has_flag[build]].filter[flag[build.center].equals[<[tile_center]>]]>

    - modifyblock <[actual_blocks]> air
    - flag <[actual_blocks]> build:!

    - define data <map[shoots=<[shoots]>;root=<[tile]>]>
    - run tile_break_chain def:<[data]>


tile_break_chain:
  type: task
  debug: false
  definitions: data
  script:
  - define shoots <[data].get[shoots]>
  - define root <[data].get[root]>

  - wait 3t

  - foreach <[shoots]> as:tile:
    - define center <[tile].center.with_yaw[0]>
    - define blocks <[tile].blocks>
    - define actual_blocks <[blocks].filter[flag[build.center].with_yaw[0].equals[<[center]>]]>

    - define is_root <proc[is_root].context[<[center]>]>
    - if <[is_root]>:
      - foreach next

    - flag <[actual_blocks]> build.roots:<-:<[root]>

    #stop the entire chain reaction if the tile has a root still
    #floors are NOT root blocks(?) this might run into some issues later on, but idc
    - if <[center].has_flag[build.roots]> && <[center].flag[build.roots].filter[center.flag[build.type].equals[FLOOR].not].any>:
      #- playeffect effect:soul_fire_flame offset:0 at:<[center].flag[build.roots].parse[center]>
      - stop

    - define new_shoots <[center].flag[build.shoots]||<list[]>>

    - modifyblock <[actual_blocks]> air
    - flag <[actual_blocks]> build:!

    - define data <map[shoots=<[new_shoots]>;root=<[tile]>]>
    - run tile_break_chain def:<[data]>

stair_blocks_gen:
  type: procedure
  definitions: center
  debug: false
  script:
  - define stair_blocks <list[]>
  - define start_corner <[center].below[3].left[2].backward_flat[3]>
  - repeat 5:
    - define corner <[start_corner].above[<[value]>].forward[<[value]>]>
    - define stair_blocks <[stair_blocks].include[<[corner].points_between[<[corner].right[4]>]>]>
  - determine <[stair_blocks]>

#when a tile is placed down, any tiles that are in the "connected_tiles" list would be considered the newly placed tile's "root"
#if that root is removed, if the newly placed tile doesn't have any other root blocks that its connected to, remove it too
find_connected_tiles:
  type: procedure
  definitions: center
  debug: false
  script:
  #-wall to wall (horizontal) check/floor to floor check
  - if <[center].left[3].has_flag[build.structure]>:
    #- narrate a
    - define connected_tiles:->:<[center].left[3].flag[build.structure]>
  - if <[center].right[3].has_flag[build.structure]>:
    #- narrate b
    - define connected_tiles:->:<[center].right[3].flag[build.structure]>

  #-wall to wall (perpendicular) check
  - if <[center].flag[build.type]> == WALL:
    - if <[center].left[2].backward_flat[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].left[2].backward_flat[2].flag[build.structure]>
    - if <[center].left[2].forward_flat[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].left[2].forward_flat[2].flag[build.structure]>
    - if <[center].right[2].backward_flat[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].right[2].backward_flat[2].flag[build.structure]>
    - if <[center].right[2].forward_flat[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].right[2].forward_flat[2].flag[build.structure]>

  #-floor to wall check
  - if <[center].flag[build.type]> == FLOOR:
    - if <[center].below.backward_flat[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].below.backward_flat[2].flag[build.structure]>
    - if <[center].below.forward_flat[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].below.forward_flat[2].flag[build.structure]>

    - if <[center].below.left[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].below.left[2].flag[build.structure]>
    - if <[center].below.right[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].below.right[2].flag[build.structure]>

    - if <[center].above.backward_flat[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].above.backward_flat[2].flag[build.structure]>
    - if <[center].above.forward_flat[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].above.forward_flat[2].flag[build.structure]>

    - if <[center].above.left[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].above.left[2].flag[build.structure]>
    - if <[center].above.right[2].has_flag[build.structure]>:
      - define connected_tiles:->:<[center].above.right[2].flag[build.structure]>

  #-wall to wall (vertical) check
  - if <[center].above[3].has_flag[build.structure]>:
    #- narrate c
    - define connected_tiles:->:<[center].above[3].flag[build.structure]>
  - if <[center].below[3].has_flag[build.structure]>:
    #- narrate d
    - define connected_tiles:->:<[center].below[3].flag[build.structure]>

  #-wall to floor AND floor to wall check (floor is below)
  - if <[center].below[2].forward_flat[2].has_flag[build.structure]>:
    #- narrate e
    - define connected_tiles:->:<[center].below[2].forward_flat[2].flag[build.structure]>
  - if <[center].below[2].backward_flat[2].has_flag[build.structure]>:
    #- narrate f
    - define connected_tiles:->:<[center].below[2].backward_flat[2].flag[build.structure]>

  #-wall to floor AND floor to wall check (floor is above)
  - if <[center].above[2].forward_flat[2].has_flag[build.structure]>:
    #- narrate i
    - define connected_tiles:->:<[center].above[2].forward_flat[2].flag[build.structure]>
  - if <[center].above[2].backward_flat[2].has_flag[build.structure]>:
    #- narrate j
    - define connected_tiles:->:<[center].above[2].backward_flat[2].flag[build.structure]>

  - if <[connected_tiles].exists>:
    #second filter check is for stairs especially, since they're a whole tile
    - determine <[connected_tiles].deduplicate>
    #<[connected_tiles].deduplicate.filter[equals[<[center].flag[build.structure]>].not]>
  - else:
    - determine <list[]>

is_root:
  type: procedure
  definitions: center
  debug: false
  script:
  - define status False
  - if !<[center].left[3].has_flag[breakable]> && <[center].left[3].material.name> != AIR:
    - define status True

  - if !<[center].right[3].has_flag[breakable]> && <[center].right[3].material.name> != AIR:
    - define status True

  - if !<[center].above[3].has_flag[breakable]> && <[center].above[3].material.name> != AIR:
    - define status True

  - if !<[center].below[3].has_flag[breakable]> && <[center].below[3].material.name> != AIR:
    - define status True

  - determine <[status]>
