      # - "can place" check
      #checks:
        # if there's nothing besides "breakable" blocks
        # if there's already a build there
        #if it's too far, disable preview (might not need)
        #green: 0,255,0,128 black:0,0,0,128

build_tiles:
  type: task
  debug: false
  script:
  #general stuff required for all builds

        - define can_build False
        - define target_loc <[eye_loc].ray_trace[default=air;range=<[range]>]>
        - define x <proc[round4].context[<[target_loc].x>]>
        - define z <proc[round4].context[<[target_loc].z>]>
        #find the bottom center of the ENTIRE tower (the nearest floor based on where you are, so only the bottom based on where you are)
        - define closest_center <[target_loc].with_x[<[x]>].with_z[<[z]>].with_y[<[eye_loc].y>].with_pitch[90].ray_trace>

  floor:

        - define range 1.5
        - inject build_tiles

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
          - define final_center <[free_center]>
        - else:
          - define final_center <[grounded_center]>
        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2,0,2]>

        - flag player build.struct:<[tile]>
        - flag player build.center:<[final_center]>

        - define display_blocks <[tile].blocks>
        - debugblock <[display_blocks]> d:2t color:0,255,0,128


  wall:

      - define range 1
      - inject build_tiles

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

      #checks: left, right, above, below
      - if <[free_center].left[2].has_flag[build]> || <[free_center].right[2].has_flag[build]> || <[free_center].above[2].has_flag[build]> || <[free_center].below[2].has_flag[build]>:
        - define final_center <[free_center]>
      - else:
        - define final_center <[grounded_center]>
      - define tile <[final_center].below[2].left[2].to_cuboid[<[final_center].above[2].right[2]>]>

      - flag player build.struct:<[tile]>
      - flag player build.center:<[final_center]>

      - define display_blocks <[tile].blocks>
      - debugblock <[display_blocks]> d:2t color:0,255,0,128

  stair:

        - define range 2.5
        - inject build_tiles

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
        #checks: left, right, forward, backward, above, below, below 2 AND backward 2 (the one side of the stair that's placeables)
        - foreach <[free_center].left[2]>|<[free_center].right[2]>|<[free_center].forward_flat[2]>|<[free_center].backward_flat[2]>|<[free_center].above[2]>|<[free_center].below[2]>|<[free_center].below[2].backward_flat[2]> as:check_loc:
          #second check is for conditions such as: stair in front of a stair
          - if <[check_loc].has_flag[build]> && <[check_loc].material.name> != air:
            - define connected True
            - foreach stop

        - if <[connected]>:
          - define final_center <[free_center].with_yaw[<[yaw]>]>
        - else:
          - define final_center <[grounded_center].with_yaw[<[yaw]>]>
        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2]>

        - flag player build.struct:<[tile]>
        - flag player build.center:<[final_center]>

        - define display_blocks <proc[stair_blocks_gen].context[<[final_center]>]>
        - debugblock <[display_blocks]> d:2t color:0,255,0,128

  pyramid:

        - define range 3
        - inject build_tiles

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

        #checks: left, right, forward, backward
        - if <[free_center].below[2].left[2].has_flag[build]> || <[free_center].below[2].right[2].has_flag[build]> || <[free_center].below[2].forward_flat[2].has_flag[build]> || <[free_center].below[2].backward_flat[2].has_flag[build]>:
          - define final_center <[free_center]>
        - else:
          - define final_center <[grounded_center]>
        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2]>

        - flag player build.struct:<[tile]>
        - flag player build.center:<[final_center]>

        - define display_blocks <proc[pyramid_blocks_gen].context[<[final_center]>]>
        - debugblock <[display_blocks]> d:2t color:0,255,0,128


build_system_handler:
  type: world
  debug: false
  events:
    on player left clicks block flagged:build.struct:
      - determine passively cancelled

      - define tile <player.flag[build.struct]>
      - define center <player.flag[build.center]>
      - define build_type <player.flag[build.type]>

      - define material oak_planks
      - define blocks <[tile].blocks>

      - choose <[build_type]>:

        - case stair:
          - define set_blocks <proc[stair_blocks_gen].context[<[center]>]>
          - define material oak_stairs[direction=<[center].yaw.simple>]
          - modifyblock <[set_blocks]> <[material]>

        - case pyramid:
          - run place_pyramid def:<[center]>

        #floors/walls
        - default:
          - define blocks <[tile].blocks>
          - modifyblock <[blocks]> <[material]>

      - flag <[blocks]> build.structure:<[tile]>
      - flag <[blocks]> build.center:<[center]>
      - flag <[blocks]> build.type:<[build_type]>
      - flag <[blocks]> breakable

    #-break
    on player right clicks block location_flagged:build.structure flagged:build:
      - determine passively cancelled
      - define loc <context.location>
      - define tile <[loc].flag[build.structure]>
      - define center <[loc].flag[build.center]>
      - define type <[loc].flag[build.type]>
      - define blocks <[tile].blocks>

      - modifyblock <[blocks]> air
      - flag <[blocks]> build:!

place_pyramid:
  type: task
  debug: false
  definitions: center
  script:
  #required definitions:
  # - <[center]>
  #

    - define mat <material[oak_stairs]>
    - define block_data <list[]>
    - define center <[center].with_yaw[0]>

    - repeat 2:
      - define layer_center <[center].below[<[value]>]>
      - define length <[value].mul[2]>
      - define start_corner <[layer_center].left[<[value]>].backward_flat[<[value]>]>
      - define corners <list[<[start_corner]>|<[start_corner].forward[<[length]>]>|<[start_corner].forward[<[length]>].right[<[length]>]>|<[start_corner].right[<[length]>]>]>

      - foreach <[corners]> as:corner:

        - define direction <map[1=west;2=north;3=east;4=south].get[<[loop_index]>]>
        - define mat_data <[mat].with[direction=<[direction]>;shape=outer_left]>

        - define block_data <[block_data].include[<map[loc=<[corner]>;mat=<[mat_data]>]>]>

        - define next_corner <[corners].get[<[loop_index].add[1]>].if_null[<[corners].first>]>
        - define side <[corner].points_between[<[next_corner]>]>
        - define mat_data <[mat].with[direction=<[direction]>;shape=straight]>

        - foreach <[side].exclude[<[corner]>|<[next_corner]>]> as:s:
          - define block_data <[block_data].include[<map[loc=<[s]>;mat=<[mat_data]>]>]>

    - modifyblock <[block_data].parse[get[loc]]> <[block_data].parse[get[mat]]>
    - modifyblock <[center]> oak_slab



stair_blocks_gen:
  type: procedure
  definitions: center
  debug: false
  script:
    - define stair_blocks <list[]>
    - define start_corner <[center].below[3].left[2].backward_flat[3]>
    - repeat 5:
      - define corner <[start_corner].above[<[value]>].forward_flat[<[value]>]>
      - define stair_blocks <[stair_blocks].include[<[corner].points_between[<[corner].right[4]>]>]>
    - determine <[stair_blocks]>

pyramid_blocks_gen:
  type: procedure
  definitions: center
  debug: false
  script:
    - define blocks <list[]>
    - define start_corner <[center].below[2].left[2].backward_flat[2]>

    - define first_layer <[start_corner].to_cuboid[<[start_corner].forward_flat[4].right[4]>].outline>
    - define second_layer <[start_corner].above.forward_flat.right.to_cuboid[<[start_corner].above.forward_flat[3].right[3]>].outline>

    - define blocks <[first_layer].include[<[second_layer]>].include[<[center]>]>
    - determine <[blocks]>

round4:
  type: procedure
  definitions: i
  debug: false
  script:
    - determine <element[<element[<[i]>].div[4]>].round.mul[4]>


#
#
#
#
#
#
#
#
#
#
#
#
##temp
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
          - flag player build.type:pyramid
          - inject build_tiles.pyramid

      - wait 1t

    - flag player build:!