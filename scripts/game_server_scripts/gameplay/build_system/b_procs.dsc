## [ Part of: Build System ] ##
#separated between files to make it easier to read

# - [ Description: Procedures/utiliy scripts used for checks, etc. ] - #

#to round all build locations by fours for the "grid effect"
round4:
  type: procedure
  definitions: i
  debug: false
  script:
    - determine <element[<element[<[i]>].div[4]>].round.mul[4]>

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

#proc to prevent destruction of any terrain/world structures
get_existing_blocks:
  type: procedure
  definitions: blocks
  debug: false
  script:
    - define non_air_blocks     <[blocks].filter[material.name.equals[air].not].filter[has_flag[build.center].not]>
    - define world_build_blocks <[blocks].filter[has_flag[build.center]].filter[flag[build.center].flag[build.placed_by].equals[WORLD]]>

    #deduplicate in case the blocks met both criteria of definitions
    - determine <[non_air_blocks].include[<[world_build_blocks]>].deduplicate>

find_nodes:
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


    - define nodes <list[]>
    - foreach <[check_locs]> as:loc:
        #second check is so you can't stack stairs and pyramids on top of each other, since there's nothing connecting them
        #(even though they meet the tile intersection requirement)
      - if <[loc].has_flag[build.center]> && <[loc].material.name> != air && !<[loc].flag[build.center].has_flag[build.natural]>:
        - define nodes:->:<[loc].flag[build.center]>

    #deduplcating, because for example a floor next to a stair will pass all 4 checks for a node
    - determine <[nodes].deduplicate>

#-if it's connected to a piece of TERRAIN (non build structure), it's a root
#-and DOESN'T rely on another tile to stay "intact"
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