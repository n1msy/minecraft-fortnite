#TODO: DOMINO BREAK SYSTEM (via flags)

build_tiles:
  type: task
  debug: false
  script:
  #general stuff required for all builds

        - define can_build False
        - define yaw <map[North=180;South=0;West=90;East=-90].get[<[eye_loc].yaw.simple>]>
        - define target_loc <[eye_loc].ray_trace[default=air;range=<[range]>]>
        - define x <proc[round4].context[<[target_loc].x>]>
        - define z <proc[round4].context[<[target_loc].z>]>

        # [ ! ] the centers will ALWAYS be the center of a 2x2x2 cuboid and then be changed in their individual structures!

        - define closest_center <[target_loc].with_x[<[x]>].with_z[<[z]>].with_y[<[eye_loc].y.sub[0.5]>]>

        - define grounded_center <[closest_center].with_pitch[90].ray_trace>
        #in case it lands on something like a stair
        - if <[grounded_center].below.has_flag[build.structure]>:
          - define grounded_center <[grounded_center].with_y[<[grounded_center].below.flag[build.structure].min.y>]>

        #halfway of y would be 4, not 5, since there's overlapping "connectors"
        - define grounded_center <[grounded_center].above[2]>

        #-calculates Y from the ground up
        #- define add_y <proc[round4].context[<[target_loc].forward[<[type].equals[stair].if_true[4].if_false[2]>].distance[<[grounded_center]>].vertical.sub[<[type].equals[stair].if_true[2.5].if_false[1]>]>]>
        - define add_y <proc[round4].context[<[target_loc].forward[2].distance[<[grounded_center]>].vertical.sub[1]>]>
        - define add_y <[add_y].is[LESS].than[0].if_true[0].if_false[<[add_y]>]>

        - define free_center <[grounded_center].above[<[add_y]>]>

        #if there's a nearby tile, automatically "snap" to it's y level instead of ground up
        - if <[target_loc].find_blocks_flagged[build.structure].within[5].any>:
          - define nearest_tile <[target_loc].find_blocks_flagged[build.structure].within[5].parse[flag[build.structure]].deduplicate.first>

          - define new_y <[nearest_tile].min.y>

          - define y_levels <list[<[free_center].with_y[<[new_y].add[2]>]>|<[free_center].with_y[<[new_y].add[6]>]>|<[free_center].with_y[<[new_y].sub[2]>]>|<[free_center].with_y[<[new_y].sub[6]>]>]>

          #since all the centers are BOTTOM centers (the original)
          - define free_center <[y_levels].sort_by_number[distance[<[target_loc]>]].first.round>


  floor:

        - define range 2
        - inject build_tiles

        - define free_center <[free_center].below[2]>
        - define grounded_center <[grounded_center].below[2]>

        #-check to use free_center or ground_center
        - define connected_tiles <proc[find_connected_tiles].context[<[free_center]>|<[type]>]>
        - define final_center <[connected_tiles].any.if_true[<[free_center]>].if_false[<[grounded_center]>].round>

        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2,0,2]>

        - define display_blocks <[tile].blocks>

  wall:

        - define range 1
        - inject build_tiles

        - define free_center <[free_center].with_yaw[<[yaw]>].forward_flat[2]>
        - define grounded_center <[grounded_center].with_yaw[<[yaw]>].forward_flat[2]>

        #-check to use free_center or ground_center
        - define connected_tiles <proc[find_connected_tiles].context[<[free_center]>|<[type]>]>
        - define final_center <[connected_tiles].any.if_true[<[free_center]>].if_false[<[grounded_center]>].round>

        #- narrate <[connected_tiles].any.if_true[free].if_false[ground]>

        - choose <[eye_loc].yaw.simple>:
          - case east west:
            - define expand 0,2,2
          - case north south:
            - define expand -2,2,0

        #- define tile <[final_center].below[2].left[2].to_cuboid[<[final_center].above[2].right[2]>]>
        - define tile <[final_center].to_cuboid[<[final_center]>].expand[<[expand]>]>

        - define display_blocks <[tile].blocks>

  stair:

        - define range 3
        - inject build_tiles

        #this center is the center that would be anywhere you point (isn't grounded)
        - define free_center <[free_center].with_yaw[<[yaw]>]>
        - define grounded_center <[grounded_center].with_yaw[<[yaw]>]>

        #-check to use free_center or ground_center
        - define connected_tiles <proc[find_connected_tiles].context[<[free_center]>|<[type]>]>
        - define final_center <[connected_tiles].any.if_true[<[free_center]>].if_false[<[grounded_center]>].round>

        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2]>

        - define display_blocks <proc[stair_blocks_gen].context[<[final_center]>]>

  pyramid:

        - define range 3
        - inject build_tiles

        #no need to define free/ground center since no modification is required

        #-check to use free_center or ground_center
        - define connected_tiles <proc[find_connected_tiles].context[<[free_center]>|<[type]>]>
        - define final_center <[connected_tiles].any.if_true[<[free_center]>].if_false[<[grounded_center]>].round>

        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2]>

        - define display_blocks <proc[pyramid_blocks_gen].context[<[final_center]>]>


build_system_handler:
  type: world
  debug: false
  definitions: data
  events:
    on player left clicks block flagged:build.struct:
      - determine passively cancelled

      - define tile <player.flag[build.struct]>
      - define center <player.flag[build.center]>
      - define build_type <player.flag[build.type]>
      - define material wood

      #because walls and floors override stairs
      - define total_blocks <[tile].blocks>
      - define override_blocks <[total_blocks].filter[has_flag[build.type]].filter_tag[<list[pyramid|stair].contains[<[filter_value].flag[build.type]>]>]>

      - define blocks <[total_blocks].filter[has_flag[build].not].include[<[override_blocks]>]>

      - definemap data:
          tile: <[tile]>
          center: <[center]>
          build_type: <[build_type]>
          material: <[material]>

      - run build_system_handler.place def:<[data]>

      - flag <[blocks]> build.structure:<[tile]>
      - flag <[blocks]> build.center:<[center]>
      - flag <[blocks]> build.type:<[build_type]>
      - flag <[blocks]> build.material:<[material]>

      - flag <[blocks]> breakable

    #-break
    on player right clicks block location_flagged:build.structure flagged:build:
      - determine passively cancelled
      - define loc <context.location>
      - define tile <[loc].flag[build.structure]>
      - define center <[loc].flag[build.center]>
      - define type <[loc].flag[build.type]>

      - define replace_tiles_data <list[]>
      #-connecting blocks system
      - define nearby_tiles <[center].find_blocks_flagged[build.structure].within[5].parse[flag[build.structure]].deduplicate.exclude[<[tile]>]>
      - define connected_tiles <[nearby_tiles].filter[intersects[<[tile]>]]>
      - foreach <[connected_tiles]> as:c_tile:

        #flag the "connected blocks" to the other tile data values that were connected to the tile being removed
        - define connecting_blocks <[c_tile].intersection[<[tile]>].blocks>
        - define c_tile_center <[c_tile].center.flag[build.center]>
        - define c_tile_type <[c_tile_center].flag[build.type]>

        #walls and floors dont *need* it if, but it's much easier/simpler this way
        - definemap tile_data:
            tile: <[c_tile]>
            center: <[c_tile_center]>
            build_type: <[c_tile_type]>
            #doing this instead of center, since pyramid center is a slab
            material: <[c_tile_center].flag[build.material]>

        #doing this so AFTER the original tile is completely removed
        - define replace_tiles_data:<[replace_tiles_data].include[<[tile_data]>]>

        #make the connectors a part of the other tile
        - flag <[connecting_blocks]> build.structure:<[c_tile]>
        - flag <[connecting_blocks]> build.center:<[c_tile_center]>
        - flag <[connecting_blocks]> build.type:<[c_tile_type]>


      #-actually removing the original tile
      #so it only includes the parts of the tile that are its own (since each cuboid intersects by one)
      - define blocks <[tile].blocks.filter[flag[build.center].equals[<[center]>]]>

      #everything is being re-applied anyways, so it's ok
      - modifyblock <[tile].blocks> air

      - flag <[blocks]> build:!
      - flag <[blocks]> breakable:!

      #order: first placed -> last placed
      - define priority_order <list[wall|floor|stair|pyramid]>
      - foreach <[replace_tiles_data].parse_tag[<[parse_value]>/<[priority_order].find[<[parse_value].get[build_type]>]>].sort_by_number[after[/]].parse[before[/]]> as:tile_data:
        - run build_system_handler.place def:<[tile_data]>


  place:
    - define tile <[data].get[tile]>
    - define center <[data].get[center]>
    - define build_type <[data].get[build_type]>

    - define base_material <map[wood=oak].get[<[data].get[material]>]>

    - choose <[build_type]>:

      - case stair:
        - define total_set_blocks <proc[stair_blocks_gen].context[<[center]>]>

        #in case this stair is just being "re-applied" (so the has_flag[build.not] doesn't exclude its own stairs)
        - define own_stair_blocks <[total_set_blocks].filter[has_flag[build.center]].filter[flag[build.center].equals[<[center]>]]>

        #"extra" stair blocks from other stairs/pyramids (turn them into planks like pyramids do)
        - define set_connector_blocks <[total_set_blocks].filter[has_flag[build.type]].filter[material.name.after_last[_].equals[stairs]].exclude[<[own_stair_blocks]>]>

        #this way, the top of walls and bottom of walls turn into stairs (but not the sides)
        - define top_middle <[center].forward_flat[2].above[2]>
        - define top_points <list[<[top_middle].left>|<[top_middle]>|<[top_middle].right>]>
        - define bot_middle <[center].backward_flat[2].below[2]>
        - define bot_points <list[<[bot_middle].left>|<[bot_middle]>|<[bot_middle].right>]>
        #this way, pyramid stairs still can't be overriden
        - define override_blocks <[top_points].include[<[bot_points]>].filter[flag[build.type].equals[pyramid].not]>

        #so it doesn't completely override any previously placed tiles
        - define set_blocks <[total_set_blocks].filter[has_flag[build].not].include[<[own_stair_blocks]>].include[<[override_blocks]>]>

        - define direction <[center].yaw.simple>
        - define material <[base_material]>_stairs[direction=<[direction]>]
        - modifyblock <[set_blocks]> <[material]>

        #if they're stairs and they are going in the same direction, to keep the stairs "smooth", forget about adding connectors to them
        - define consecutive_stair_blocks <[set_connector_blocks].filter[flag[build.type].equals[stair]].filter[material.direction.equals[<[direction]>]]>

        - modifyblock <[set_connector_blocks].exclude[<[consecutive_stair_blocks]>].exclude[<[override_blocks]>]> <[base_material]>_planks

      - case pyramid:
        - run place_pyramid def:<[center]>|<[base_material]>

      #floors/walls
      - default:
        #mostly for the stair overriding stuff with walls and floors
        - define total_blocks <[tile].blocks>

        - define exclude_blocks <list[]>

        - define nearby_tiles <[center].find_blocks_flagged[build.structure].within[5].parse[flag[build.structure]].deduplicate.exclude[<[tile]>]>
        - define connected_tiles <[nearby_tiles].filter[intersects[<[tile]>]]>
        - define stair_tiles <[connected_tiles].filter[center.flag[build.type].equals[stair]]>

        #- define stair_tiles <proc[find_connected_tiles].context[<[center]>|<[build_type]>].filter[center.flag[build.type].equals[stair]]>

        - if <[stair_tiles].any>:
          - define stair_tile_center <[stair_tiles].first.center.flag[build.center]>

          - define top_middle <[stair_tile_center].forward_flat[2].above[2]>
          - define top_points <list[<[top_middle].left>|<[top_middle]>|<[top_middle].right>]>
          - define bot_middle <[stair_tile_center].backward_flat[2].below[2]>
          - define bot_points <list[<[bot_middle].left>|<[bot_middle]>|<[bot_middle].right>]>

          #with_pose part removes yaw/pitch data so we can exclude it from total blocks
          - define exclude_blocks <[top_points].include[<[bot_points]>].parse[with_pose[0,0]]>

        - define set_blocks <[total_blocks].exclude[<[exclude_blocks]>]>
        - modifyblock <[set_blocks]> <[base_material]>_<map[oak=planks].get[<[base_material]>]>

find_connected_tiles:
  type: procedure
  definitions: center|type
  debug: false
  script:
    #- playeffect effect:soul_fire_flame offset:0 at:<[center]>
    - choose <[type]>:
      #center of a 2,0,2
      - case floor:
        - define check_locs <list[<[center].left[2]>|<[center].right[2]>|<[center].forward_flat[2]>|<[center].backward_flat[2]>]>
      #center of a 2,2,0 or 2,2,0
      - case wall:
        - define check_locs <list[<[center].left[2]>|<[center].right[2]>|<[center].above[2]>|<[center].below[2]>]>
      #center of a 2,2,2
      - case stair:
        - define check_locs <list[<[center].backward_flat[2].below[2]>|<[center].left[2]>|<[center].right[2]>|<[center].forward_flat[2].above[2]>]>
      #center of a 2,2,2
      - case pyramid:
        - define bottom_center <[center].below[2]>
        - define check_locs <list[<[bottom_center].left[2]>|<[bottom_center].right[2]>|<[bottom_center].forward_flat[2]>|<[bottom_center].backward_flat[2]>]>

    - define connected_tiles <list[]>
    - foreach <[check_locs]> as:loc:
      #- playeffect effect:FLAME offset:0 at:<[loc]>
      - if <[loc].has_flag[build.structure]> && <[loc].material.name> != AIR:
        - define connected_tiles:->:<[loc].flag[build.structure]>

    - determine <[connected_tiles]>


place_pyramid:
  type: task
  debug: false
  definitions: center|base_material
  script:
  #required definitions:
  # - <[center]>
  #

    - define block_data <list[]>
    - define center <[center].with_yaw[0].with_pitch[0]>

    - repeat 2:
      - define layer_center <[center].below[<[value]>]>
      - define length <[value].mul[2]>
      - define start_corner <[layer_center].left[<[value]>].backward_flat[<[value]>]>
      - define corners <list[<[start_corner]>|<[start_corner].forward[<[length]>]>|<[start_corner].forward[<[length]>].right[<[length]>]>|<[start_corner].right[<[length]>]>]>

      - foreach <[corners]> as:corner:

        - define next_corner <[corners].get[<[loop_index].add[1]>].if_null[<[corners].first>]>
        - define side <[corner].points_between[<[next_corner]>]>

        - define direction <map[1=west;2=north;3=east;4=south].get[<[loop_index]>]>

        - define corner_mat <material[<[base_material]>_stairs].with[direction=<[direction]>;shape=outer_left]>
        - define side_mat <material[<[base_material]>_stairs].with[direction=<[direction]>;shape=straight]>

        #if it's the last layer, and there are any other builds connected to each other, turn the material into non-stairs
        - if <[value]> == 2 && <[side].get[3].face[<[layer_center]>].backward_flat.has_flag[build.structure]>:
          - define corner_mat <material[<[base_material]>_<map[oak=planks].get[<[base_material]>]>]>
          - define side_mat <[corner_mat]>

        #-adding corners first
        #this checks for:
        # 1) no build is there yet
        #OR 2) the build there is a stair or pyramid
        - if !<[corner].has_flag[build.type]> || <list[stair|pyramid].contains[<[corner].flag[build.type]>]>:
          - define block_data <[block_data].include[<map[loc=<[corner]>;mat=<[corner_mat]>]>]>

        #-then sides
        - foreach <[side].exclude[<[corner]>|<[next_corner]>]> as:s:
          #so it doesn't override any pre-existing builds
          - if !<[s].has_flag[build.type]> || <list[stair|pyramid].contains[<[s].flag[build.type]>]>:
            - define block_data <[block_data].include[<map[loc=<[s]>;mat=<[side_mat]>]>]>

    - modifyblock <[block_data].parse[get[loc]]> <[block_data].parse[get[mat]]>
    - modifyblock <[center]> <[base_material]>_slab


stair_blocks_gen:
  type: procedure
  definitions: center
  debug: false
  script:
    - define stair_blocks <list[]>
    - define start_corner <[center].below[3].left[2].backward_flat[3].round>
    - repeat 5:
      - define corner <[start_corner].above[<[value]>].forward_flat[<[value]>].round>
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
      - define type <map[1=wall;2=floor;3=stair;4=pyramid].get[<player.held_item_slot>]||null>

      - if <[type]> != null:
        - actionbar <[type]>
        - flag player build.type:<[type]>
        - inject build_tiles.<[type]>

        # keeping this here, just in case, but we might not need it and can let players break the terrain with the builds, since it gives more freedom
        # AND the world regenerates each match anyways

        #checks if:
        # 1) there's something unbreakable there
        # 2) if there's already a build there (and if that build is NOT a pyramid or a stair (since those can be "overwritten"))
        #if none pass, it's buildable
        - define can_build True
        - define unbreakable_blocks <[display_blocks].filter[material.name.equals[air].not].filter[has_flag[breakable].not]>
        #this way, grass and shit is overwritten because screw that
        - if <[unbreakable_blocks].filter[material.vanilla_tags.contains[replaceable_plants].not].any> || <[final_center].has_flag[build.type]> && <list[stair|pyramid].contains[<[final_center].flag[build.type]>].not>:
          - define can_build False

        - if <[can_build]>:
          #-set flags
          - flag player build.struct:<[tile]>
          - flag player build.center:<[final_center]>
          - debugblock <[display_blocks]> d:2t color:0,255,0,128
        - else:
          - flag player build.struct:!
          - debugblock <[display_blocks]> d:2t color:0,0,0,128


      - wait 1t

    - flag player build:!