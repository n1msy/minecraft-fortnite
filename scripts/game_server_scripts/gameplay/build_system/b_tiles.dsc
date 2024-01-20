## [ Part of: Build System ] ##
#separated between files to make it easier to read

# - [ Description: Calculate tile locations & view tile blocks ] - #

build_tiles:
  type: task
  debug: false
  script:
  #general stuff required for all builds
  #- calculates where to place the tile

        #basically same as as_root
        - define is_grounded False
        - define can_build   False
        - define yaw <map[North=180;South=0;West=90;East=-90].get[<[eye_loc].yaw.simple>]>
        #.backwards so you can't place tiles if there's a block in front of you (it'll only return the closest tile before that)
        - define target_loc <[eye_loc].ray_trace[default=air;range=<[range]>].with_yaw[<[yaw]>].backward[0.1]>
        - define x <proc[round4].context[<[target_loc].x>]>
        - define z <proc[round4].context[<[target_loc].z>]>

        - define eye_y <[eye_loc].below[0.85].forward[2].y>

        ## [ ! ] the centers will ALWAYS be the center of a 2x2x2 cuboid and then be changed in their individual structures! ##

        - define closest_center <[target_loc].with_x[<[x]>].with_z[<[z]>].with_y[<[target_loc].y>]>

        - define closest_tile_center <proc[find_closest_center].context[<[closest_center]>|<[target_loc]>]>

          # - [ Nearest Tile Center ] - #
        - if <[closest_tile_center]> != null:
          #setting the y to the BOTTOM CENTER
          #(for floors it wouldn't make a difference)
          - if <[eye_y]> > <[closest_tile_center].y>:
            - define y <[closest_tile_center].flag[build.structure].max.y>
          - else:
            - define y <[closest_tile_center].flag[build.structure].min.y>

          #target bottom center = what would be the bottom center of any build that you'd place (not already placed)
          - define target_bottom_center <[closest_center].with_y[<[y]>].round>

          # - [ Grounded Center ] - #
          #this only happens when there are no nearby tiles
        - else:
          #doing .backward so the tiles cant be placed *inside* the ground
          - define grounded_center <[closest_center].with_pitch[90].ray_trace.backward.above>

          #if it ever happens that grounded_center is on a build & the player has a high enough range for it
          - define found_tile_center <[grounded_center].below.flag[build.center]||null>
          - if <[found_tile_center]> != null:
            - if <[eye_y]> > <[found_tile_center].y>:
              - define y <[found_tile_center].flag[build.structure].max.y>
            - else:
              - define y <[found_tile_center].flag[build.structure].min.y>
            - define grounded_center <[grounded_center].with_y[<[y]>]>

          #-bypass street slabs
          - if <list[polished_blackstone_slab|blackstone_slab|bamboo_slab].contains[<[grounded_center].material.name>]>:
            - define grounded_center <[grounded_center].below[0.5]>

          - define target_bottom_center <[grounded_center]>



  wall:

        # - these ranges are how FAR to look when placing a tile, it's not being used for the purpose of detecting if the tile is too far or not - #
        - define range 0.8
        - inject build_tiles

        - define pitch <[eye_loc].forward[3].y.is[OR_MORE].than[<[target_bottom_center].y>].if_true[-90].if_false[90]>
        - define final_center <[target_bottom_center].with_yaw[<[yaw]>].forward_flat[2].with_pitch[<[pitch]>].forward[2]>

        - choose <[eye_loc].yaw.simple>:
          - case east west:
            - define expand 0,2,2
          - case north south:
            - define expand -2,2,0

        - define tile <[final_center].to_cuboid[<[final_center]>].expand[<[expand]>]>

        - define display_blocks <[tile].blocks>

  floor:
        - define range 3
        - inject build_tiles

        - define final_center <[target_bottom_center].round>

        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2,0,2]>

        - define display_blocks <[tile].blocks>

  stair:

        - define range 4
        - inject build_tiles

        - define pitch <[eye_loc].forward[2.5].y.is[OR_MORE].than[<[target_bottom_center].y>].if_true[-90].if_false[90]>
        - define final_center <[target_bottom_center].with_pitch[<[pitch]>].forward[2].with_yaw[<[yaw]>]>

        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2]>

        - define display_blocks <proc[stair_blocks_gen].context[<[final_center]>]>

  pyramid:

        - define range 3
        - inject build_tiles

        - define pitch <[eye_loc].forward.y.is[OR_MORE].than[<[target_bottom_center].y>].if_true[-90].if_false[90]>
        - define final_center <[target_bottom_center].with_pitch[<[pitch]>].forward[2]>

        - define tile <[final_center].to_cuboid[<[final_center]>].expand[2]>

        - define display_blocks <proc[pyramid_blocks_gen].context[<[final_center]>]>


#-injected by: b_actions.dsc
build_place_tile:
  type: task
  debug: false
  definitions: center|tile|base_material|is_editing|connected_nodes|build_type|exclude_blocks
  script:
    - narrate "all the placing calculations for each tile type goes here"
  wall:
    #mostly for the stair overriding stuff with walls and floors
    - define total_blocks     <[tile].blocks>

    #not checking for connected tiles, because bottom layer of wall has to overide stairs
    - define top_center <[center].above[2]>
    #just exclude that part, no matter if it's a stair or not, because if it's a wall, it'd be the same thing
    #also, make sure there isn't a floor above the wall, otherwise the stair will go through
    - define stair_center <[center].backward_flat[2]>
    #second check is to see if the stair is facing the wall, otherwise, dont do the stair thing
    - if <[stair_center].flag[build.type]||null> == STAIR && <[stair_center].direction[<[center]>].yaw.mul[-1]> == <[stair_center].yaw>:
      - define top_center <[center].above[2]>
      - define top_layer <list[<[top_center].left[1]>|<[top_center]>|<[top_center].right[1]>]>
      - foreach <[top_layer]> as:l:
        - define exclude_blocks:->:<[l]> if:<[l].material.name.equals[air].not>

    - define set_blocks <[total_blocks].exclude[<[exclude_blocks].parse[with_pose[0,0]]>]>
    - modifyblock <[set_blocks]> <map[oak=oak_planks;brick=bricks;weathered_copper=weathered_copper].get[<[base_material]>]>

  floor:
    #should we calculate the overlapping/overriding blocks every time, or store them?
    #eh, worst case scenario ill do it if it does lag

    - define total_blocks     <[tile].blocks>
    #im scared of doing "parse" a lot here, maybe if the build system is laggy, we can optimize this part
    #but for now, it's short and sweet
    - if <[connected_nodes].any>:
      - define connected_tiles <[connected_nodes].parse[flag[build.structure]]>
      - foreach <[connected_tiles]> as:c_tile:
        - define c_tile_center <[connected_nodes].get[<[loop_index]>]>
        #this way, stairs dont override floors when they are ON TOP of them
        - if <[c_tile_center].y> > <[center].y>:
          - foreach next
        - define exclude_blocks:|:<[c_tile].blocks.filter[material.name.equals[air].not]>

    - define set_blocks <[total_blocks].exclude[<[exclude_blocks].parse[with_pose[0,0]]>]>
    - modifyblock <[set_blocks]> <map[oak=oak_planks;brick=bricks;weathered_copper=weathered_copper].get[<[base_material]>]>

  stair:
    - define total_blocks     <proc[stair_blocks_gen].context[<[center]>]>
    - define pose             <[center].pitch>,<[center].yaw>

    #exclude any walls that are to the sides (left or right) of the stair
    #checking .placed_by, meaning if it has that flag, it's the center
    #and only 1 build type can have a center there; you guessed it, walls.
    - define left_center  <[center].left[2]>
    - define right_center <[center].right[2]>

    #like walls and floors, the second check is to make sure it's not preventing itself from restoring itself (during the tile replace)
    - if <[left_center].has_flag[build.placed_by]>:
      - define exclude_blocks:|:<[left_center].flag[build.structure].blocks>
    - if <[right_center].has_flag[build.placed_by]>:
      - define exclude_blocks:|:<[right_center].flag[build.structure].blocks>

    - define connector_blocks <list[]>
    - define bottom_center <[center].below[2].backward_flat[2]>
    - if <[bottom_center].has_flag[build.center]> && <[bottom_center].flag[build.center]> != <[center]>:
      - define b_center_type <[bottom_center].flag[build.center].flag[build.type]>
      - choose <[b_center_type]>:
        - case WALL:
          - define exclude_blocks:|:<list[<[bottom_center].left[2]>|<[bottom_center].right[2]>]>
        - case FLOOR:
          - define exclude_blocks:|:<list[<[bottom_center].left[2].round>|<[bottom_center].left[1].round>|<[bottom_center].round>|<[bottom_center].right[1].round>|<[bottom_center].right[2].round>]>
        - case STAIR PYRAMID:
          - if <[bottom_center].flag[build.center].y> == <[center].y>:
            - define connector_blocks:|:<list[<[bottom_center].left[2]>|<[bottom_center].left[1]>|<[bottom_center]>|<[bottom_center].right[1]>|<[bottom_center].right[2]>]>

    - define set_blocks      <[total_blocks].exclude[<[exclude_blocks].parse[with_pose[<[pose]>]]>]>

    - define direction <[center].yaw.simple>
    - define material <[base_material]>_stairs
    - define material weathered_cut_copper_stairs if:<[base_material].equals[weathered_copper]>
    - define material <[material]>[direction=<[direction]>]
    - modifyblock <[set_blocks]> <[material]>

    #connects blocks smoothly between stairs and pyramids
    - if <[connector_blocks].any>:
      - define mat <map[oak=oak_planks;brick=bricks;weathered_copper=weathered_copper].get[<[base_material]>]>
      - modifyblock <[connector_blocks]> <[mat]>


  pyramid:
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
        - define side <[corner].round.points_between[<[next_corner].round>]>

        - define direction <map[1=west;2=north;3=east;4=south].get[<[loop_index]>]>

        - define corner_mat <material[<[stairs]>].with[direction=<[direction]>;shape=outer_left]>
        - define side_mat <material[<[stairs]>].with[direction=<[direction]>;shape=straight]>

        #if it's the last layer, and there are any other builds connected to each other, turn the material into non-stairs
        - if <[value]> == 2:
          - define connected_center <[side].get[3].face[<[layer_center]>].backward_flat.flag[build.center]||null>
          - if <[connected_center]> != null && <[connected_center].y> == <[center].y>:
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

    - define total_blocks    <[block_data].parse[get[loc]]>

    - define set_blocks      <[total_blocks].exclude[<[exclude_blocks]>]>

    - modifyblock <[set_blocks]> <[block_data].parse[get[mat]]>

    - if !<[center].has_flag[build.edited]>:
      - define slab_mat <[base_material]>_slab
      - define slab_mat weathered_cut_copper_slab if:<[base_material].equals[weathered_copper]>
      - modifyblock <[center]> <[slab_mat]>