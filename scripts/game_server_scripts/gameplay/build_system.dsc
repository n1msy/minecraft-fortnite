#TODO: clean up this entire thing; it's pretty unorganized and ugly
#things to clean:
#make a proc for determining the "stairs" variant of the block
#editing/resetting the edit for pyramids is buggy


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
        - if <[grounded_center].below.has_flag[build.center]>:
          - define grounded_center <[grounded_center].with_y[<[grounded_center].below.flag[build.center].flag[build.structure].min.y>]>

        #halfway of y would be 4, not 5, since there's overlapping "connectors"
        - define grounded_center <[grounded_center].above[2]>

        #-calculates Y from the ground up
        - define add_y <proc[round4].context[<[target_loc].forward[2].distance[<[grounded_center]>].vertical.sub[1]>]>
        - define add_y <[add_y].is[LESS].than[0].if_true[0].if_false[<[add_y]>]>

        - define free_center <[grounded_center].above[<[add_y]>]>

        #if there's a nearby tile, automatically "snap" to it's y level instead of ground up
        - if <[target_loc].find_blocks_flagged[build.center].within[5].any>:
          - define nearest_tile <[target_loc].find_blocks_flagged[build.center].within[5].parse[flag[build.center].flag[build.structure]].deduplicate.first>

          - define new_y <[nearest_tile].min.y>

          - define y_levels <list[<[free_center].with_y[<[new_y].add[2]>]>|<[free_center].with_y[<[new_y].add[6]>]>|<[free_center].with_y[<[new_y].sub[2]>]>|<[free_center].with_y[<[new_y].sub[6]>]>]>

          #since all the centers are BOTTOM centers (the original)
          - define free_center <[y_levels].sort_by_number[distance[<[target_loc]>]].first.round>


  floor:

        - define range 2
        - inject build_tiles

        - define free_center <[free_center].below[2]>
        - define grounded_center <[grounded_center].below[2]>

        - define connected_tiles <proc[find_connected_tiles].context[<[free_center]>|<[type]>]>
        - define final_center <[connected_tiles].any.if_true[<[free_center]>].if_false[<[grounded_center]>].round>

        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2,0,2]>

        - define display_blocks <[tile].blocks>

  wall:

        - define range 1
        - inject build_tiles

        - define free_center <[free_center].with_yaw[<[yaw]>].forward_flat[2]>
        - define grounded_center <[grounded_center].with_yaw[<[yaw]>].forward_flat[2]>

        - define connected_tiles <proc[find_connected_tiles].context[<[free_center]>|<[type]>]>
        - define final_center <[connected_tiles].any.if_true[<[free_center]>].if_false[<[grounded_center]>].round>

        - choose <[eye_loc].yaw.simple>:
          - case east west:
            - define expand 0,2,2
          - case north south:
            - define expand -2,2,0

        - define tile <[final_center].to_cuboid[<[final_center]>].expand[<[expand]>]>

        - define display_blocks <[tile].blocks>

  stair:

        - define range 3
        - inject build_tiles

        #this center is the center that would be anywhere you point (isn't grounded)
        - define free_center <[free_center].with_yaw[<[yaw]>]>
        - define grounded_center <[grounded_center].with_yaw[<[yaw]>]>

        - define connected_tiles <proc[find_connected_tiles].context[<[free_center]>|<[type]>]>
        - define final_center <[connected_tiles].any.if_true[<[free_center]>].if_false[<[grounded_center]>].round>

        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2]>

        - define display_blocks <proc[stair_blocks_gen].context[<[final_center]>]>

  pyramid:

        - define range 3
        - inject build_tiles

        #no need to define free/ground center since no modification is required

        - define connected_tiles <proc[find_connected_tiles].context[<[free_center]>|<[type]>]>
        - define final_center <[connected_tiles].any.if_true[<[free_center]>].if_false[<[grounded_center]>].round>

        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2]>

        - define display_blocks <proc[pyramid_blocks_gen].context[<[final_center]>]>


get_existing_blocks:
  type: procedure
  definitions: blocks
  debug: false
  script:
    - define non_air_blocks     <[blocks].filter[material.name.equals[air].not].filter[has_flag[build.center].not]>
    - define world_build_blocks <[blocks].filter[has_flag[build.center]].filter[flag[build.center].flag[build.placed_by].equals[WORLD]]>

    #- define natural_blocks     <[blocks].filter[has_flag[build.natural]]>

    #deduplicate in case the blocks met both criteria of definitions
    #- determine <[non_air_blocks].include[<[world_build_blocks]>].include[<[natural_blocks]>].deduplicate>
    - determine <[non_air_blocks].include[<[world_build_blocks]>].deduplicate>

find_connected_tiles:
  type: procedure
  definitions: center|type
  debug: false
  script:
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

    - define current_struct <[center].flag[build.structure]||null>

    - define connected_tiles <list[]>
    - foreach <[check_locs]> as:loc:
      - if <[loc].has_flag[build.center]> && <[loc].flag[build.center].flag[build.structure]> != <[current_struct]> && <[loc].material.name> != AIR:
        - define connected_tiles:->:<[loc].flag[build.center].flag[build.structure]>

    - determine <[connected_tiles]>

get_surrounding_tiles:
  type: procedure
  definitions: tile|center
  debug: false
  script:
    - define nearby_tiles <[center].find_blocks_flagged[build.center].within[5].filter[flag[build.center].has_flag[build.natural].not].filter[flag[build.center].has_flag[build.structure]].parse[flag[build.center].flag[build.structure]].deduplicate.exclude[<[tile]>]>
    - define connected_tiles <[nearby_tiles].filter[intersects[<[tile]>]]>
    - determine <[connected_tiles].sort_by_value[y]>

is_root:
  type: procedure
  definitions: center|type
  debug: false
  script:
    - choose <[type]>:
      #center of a 2,0,2
      - case floor:
        - define check_loc <[center].below>
      #center of a 2,2,0 or 2,2,0
      - case wall:
        - define check_loc <[center].below[3]>
      #center of a 2,2,2
      - case stair:
        - define check_loc <[center].below[3]>
      #center of a 2,2,2
      - case pyramid:
        - define check_loc <[center].below[3]>

    - define is_root False

    - if !<[check_loc].has_flag[build.center]> && <[check_loc].material.name> != AIR:
      - define is_root True

    - determine <[is_root]>

place_pyramid:
  type: task
  debug: false
  definitions: center|base_material|is_editing
  script:
  #required definitions:
  # - <[center]>
  #

    - define block_data <list[]>
    - define center <[center].with_yaw[0].with_pitch[0]>

    - define stairs <[base_material]>_stairs
    - define stairs weathered_cut_copper_stairs if:<[base_material].equals[weathered_copper]>
    - define block <map[oak=oak_planks;brick=bricks;weathered_copper=weathered_copper].get[<[base_material]>]>

    - repeat 2:
      - define layer_center <[center].below[<[value]>]>
      - define length <[value].mul[2]>
      - define start_corner <[layer_center].left[<[value]>].backward_flat[<[value]>]>
      - define corners <list[<[start_corner]>|<[start_corner].forward[<[length]>]>|<[start_corner].forward[<[length]>].right[<[length]>]>|<[start_corner].right[<[length]>]>]>

      - foreach <[corners]> as:corner:

        - define next_corner <[corners].get[<[loop_index].add[1]>].if_null[<[corners].first>]>
        - define side <[corner].points_between[<[next_corner]>]>

        - define direction <map[1=west;2=north;3=east;4=south].get[<[loop_index]>]>

        - define corner_mat <material[<[stairs]>].with[direction=<[direction]>;shape=outer_left]>
        - define side_mat <material[<[stairs]>].with[direction=<[direction]>;shape=straight]>

        #if it's the last layer, and there are any other builds connected to each other, turn the material into non-stairs
        - if <[value]> == 2 && <[side].get[3].face[<[layer_center]>].backward_flat.has_flag[build.center]>:
          - define corner_mat <[block]>
          - define side_mat <[corner_mat]>

        #-adding corners first
        #this checks for:
        # 1) no build is there yet
        #OR 2) the build there is a stair or pyramid
        - if !<[corner].has_flag[build.center]> || <list[stair|pyramid].contains[<[corner].flag[build.center].flag[build.type]>]>:
          - define block_data <[block_data].include[<map[loc=<[corner]>;mat=<[corner_mat]>]>]>

        #-then sides
        - foreach <[side].exclude[<[corner]>|<[next_corner]>]> as:s:
          #so it doesn't override any pre-existing builds
          - if !<[s].has_flag[build.center]> || <list[stair|pyramid].contains[<[s].flag[build.center].flag[build.type]>]>:
            - define block_data <[block_data].include[<map[loc=<[s]>;mat=<[side_mat]>]>]>

    - define set_blocks      <[block_data].parse[get[loc]].filter[has_flag[build.edited].not]>
    - define set_blocks      <[set_blocks].filter[has_flag[build.edited].not]> if:<[is_editing]>
    - define existing_blocks <proc[get_existing_blocks].context[<list_single[<[set_blocks]>]>]>
    - flag <[existing_blocks]> build_existed

    - define set_blocks      <[set_blocks].exclude[<[existing_blocks]>]>

    - modifyblock <[set_blocks]> <[block_data].parse[get[mat]]>

    - if !<[center].has_flag[build.edited]>:
      - if <[center].material.name> != air && <[center].flag[build.placed_by]||null> == WORLD:
        - flag <[center]> build_existed
      - else:
        - define slab_mat <[base_material]>_slab
        - define slab_mat weathered_cut_copper_slab if:<[base_material].equals[weathered_copper]>
        - modifyblock <[center]> <[slab_mat]>

stair_blocks_gen:
  type: procedure
  definitions: center
  debug: false
  script:
    - define stair_blocks <list[]>
    - define start_corner <[center].below[3].left[2].backward_flat[3].round>
    - repeat 5:
      - define corner <[start_corner].above[<[value]>].forward_flat[<[value]>].round>
      - define stair_blocks <[stair_blocks].include[<[corner].points_between[<[corner].right[4].round>]>]>
    - determine <[stair_blocks]>

pyramid_blocks_gen:
  type: procedure
  definitions: center
  debug: false
  script:
    - define blocks <list[]>
    - define start_corner <[center].below[2].left[2].backward_flat[2].round>

    - define first_layer <[start_corner].to_cuboid[<[start_corner].forward_flat[4].right[4].round>].outline>
    - define second_layer <[start_corner].above.forward_flat.right.to_cuboid[<[start_corner].above.forward_flat[3].right[3].round>].outline>

    - define blocks <[first_layer].include[<[second_layer]>].include[<[center]>]>
    - determine <[blocks]>

#to round all build locations by fours for the "grid effect"
round4:
  type: procedure
  definitions: i
  debug: false
  script:
    - determine <element[<element[<[i]>].div[4]>].round.mul[4]>