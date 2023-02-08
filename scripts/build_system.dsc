
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
        - define closest_tiles <[target_loc].find_blocks_flagged[build.center].within[6].filter[flag[build.type].equals[floor]]>
        - define closest_tile_center null
        - if !<[closest_tiles].is_empty>:
          - define closest_tile_center <[closest_tiles].parse[flag[build.center]].sort_by_number[distance[<[target_loc]>]].first>

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

        - define tile <[tile_center].to_cuboid[<[tile_center]>].expand[2,0,2]>
        - define blocks <[tile].blocks>

        #check 1: if there are ANY non-air blocks in the tile
        #check 2: if there's ANY non-air block that does NOT have the breakable flag

        - define blocks_in_way False
        - if <[blocks].filter[material.name.equals[AIR].not].any> && <[blocks].filter[material.name.equals[AIR].not].filter[has_flag[breakable].not].any>:
          - define can_build False
          - define blocks_in_way True

        #so in case it's doing the ray_trace thing when there's no other nearby tiles, check if the distance is valid
        - if <[tile_center].distance[<[loc]>].vertical> > 6:
          - define can_build False
          #setting it to false so they dont show up
          - define blocks_in_way False

        #if there's already a structure there, don't show up
        - if <[tile_center].has_flag[build]>:
          - define can_build False
          - define blocks_in_way False

        - if <[can_build]>:
          - debugblock <[blocks]> d:2t color:0,255,0,128
          - flag player build.struct:<[tile]>
        - else:
          - flag player build.struct:!
          - if <[blocks_in_way]>:
            - debugblock <[blocks]> d:2t color:0,0,0,128

  wall:

      - define target_loc <[eye_loc].forward>

      #find closest floor center to base walls off
      - define x <proc[round4].context[<[target_loc].x>]>
      - define z <proc[round4].context[<[target_loc].z>]>
      - define closest_center <[target_loc].with_x[<[x]>].with_z[<[z]>].with_pitch[90].ray_trace>

      #round the wall heights by 5 based on the floor below the target_loc
      - define add_y <proc[round4].context[<[target_loc].forward[4].distance[<[closest_center]>].vertical.sub[2.5]>]>
      - define closest_center <[closest_center].above[<[add_y].is[LESS].than[0].if_true[0].if_false[<[add_y]>]>]>

      #make the bottom center of the wall go forward so it's on the edge of the floor, then get the block that itd be on top of,
      #then reorient it to face where the player is facing
      - define yaw <map[North=180;South=0;West=90;East=-90].get[<[eye_loc].yaw.simple>]>
      - define bottom_center <[closest_center].with_yaw[<[yaw]>].forward_flat[2]>

      #- playeffect effect:FLAME at:<[closest_center].above[2].center> offset:0
      #- playeffect effect:FLAME at:<[bottom_center].above[2].center> offset:0

      - define can_build False

      #base tile
      - define tile <[bottom_center].left[2].to_cuboid[<[bottom_center].right[2].above[4]>]>
      - define center <[tile].center.with_yaw[<[yaw]>]>

      #this new_y should only exist if there's a wall verticall or horizontally
      - define new_y:!

      #if ANY block below the wall is a build, move it one down
      - define vertical:!

      #if the player is still looking at the tile below, dont move the tile upwards
      - define block_looking_at <[eye_loc].ray_trace[return=block;range=5;default=air]>
      - if !<[block_looking_at].has_flag[build]>:
        #-if there's any build BELOW
        - if <[center].below[3].has_flag[build]>:
          - define vertical True
          - define vert_tile_center <[center].below[3].flag[build.center]>
          - if <[vert_tile_center].flag[build.type]> == FLOOR:
            - define new_y <[bottom_center].y.sub[1]>
          - else:
            - define new_y <[vert_tile_center].flag[build.structure].max.y>
          - define can_build True

        #-if there's a any build ABOVE
        - else if <[center].above[3].has_flag[build]>:
          - define vertical True
          - define vert_tile_center <[center].above[3].flag[build.center]>
          - if <[vert_tile_center].flag[build.type]> == FLOOR:
            - define new_y <[bottom_center].y>
          - else:
            - define new_y <[vert_tile_center].flag[build.structure].min.y.sub[4]>
          - define can_build True

      - define horizontal:!
      #-if there's a wall on the LEFT side
      #checking 3 blocks above the center, so the corners of the a wall below don't count
      - if <[center].left[3].has_flag[build]>:
        - define horizontal True
        - define can_build True
        - define new_y <[center].left[3].flag[build.structure].min.y>
      #-if there's a wall on the RIGHT side
      - else if <[center].right[3].has_flag[build]>:
        - define horizontal True
        - define can_build True
        - define new_y <[center].right[3].flag[build.structure].min.y>

      - if <[new_y].exists>:
        - define bottom_center <[bottom_center].with_y[<[new_y]>]>
        - define tile <[bottom_center].left[2].to_cuboid[<[bottom_center].right[2].above[4]>]>

      #if there's nothing attached vertically and horizontally, default to the ground (if there's space between the wall and the ground)
      - if !<[vertical].exists> && !<[horizontal].exists>:
        - if <[bottom_center].below.material.name> == AIR:
          - define bottom_center <[bottom_center].with_pitch[90].ray_trace.with_yaw[<[yaw]>]>
          - define tile <[bottom_center].left[2].to_cuboid[<[bottom_center].right[2].above[4]>]>
          - define can_build True

      # - "can place" check

      #making sure there's either all air in that area or any thing being placed there is breakable
      - if <[blocks].filter[material.name.equals[AIR].not].is_empty> || <[blocks].filter[material.name.equals[AIR].not].filter[has_flag[breakable].not].is_empty>:
        - define blocks_in_way False
      - else:
        - define blocks_in_way True

      - define can_build True
      - if <[blocks_in_way]>:
        - define can_build False

      #it there's already a build there
      - if <[tile].center.has_flag[build]>:
        - define can_build False

      - define blocks <[tile].blocks>
      - if <[can_build]>:
        - debugblock <[blocks]> d:2t color:0,255,0,128
        - flag player build.struct:<[tile]>
      - else:
        - flag player build.struct:!
        #- if <[blocks_in_way]>:
        - debugblock <[blocks]> d:2t color:0,0,0,128

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