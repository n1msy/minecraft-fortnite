
##turn this into a proc that checks if you can place or not


build_tiles:
  type: task
  debug: false
  scripts:
  - narrate "set the build tiles for each structure"

  floor:
        #-checks if there's any near floors that the tile can snap on to (mostly for walls?)
        #closest center can be anywhere that's rounded to the grid
        - define closest_center <[target_loc].find_blocks.within[3].parse_tag[<[parse_value].with_x[<proc[round5].context[<[parse_value].x>]>].with_z[<proc[round5].context[<[parse_value].z>]>]>].sort_by_number[distance[<[target_loc]>]].first||null>

        #closest tile finds the nearest tile if any (their centers only)
        - define closest_tile_center <[target_loc].find_blocks_flagged[build].within[6].parse[flag[build.center]].sort_by_number[distance[<[target_loc]>]].first||null>


        #- playeffect effect:FLAME offset:0 at:<[closest_center]>

        #- [ if there are any nearby tiles, automatically "snap" the player's selected center to the nearby tile's y ] - #

        - if <[closest_tile_center]> != null:
          - define closest_center <[closest_center].with_y[<[closest_tile_center].y.add[1]>]>
        #if they're pointing in the air
        - else if <[target_loc].material.name> == air:
          - define closest_center <[closest_center].with_pitch[90].ray_trace>
        #otherwise, they're most likely pointing to the ground, so calculate it 1 up
        - else:
          - define closest_center <[closest_center].with_y[<[target_loc].y.add[1]>]>

        - if <[closest_center].material.name> != air:
          - define closest_center <[closest_center].above>

        - define build_loc <[target_loc].with_y[<[closest_center].y.sub[1]>]>
        - define rounded_x <proc[round5].context[<[build_loc].x>]>
        - define rounded_z <proc[round5].context[<[build_loc].z>]>
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

        #if the tile has an unbreakable block anywhere in it, you won't be able to place
        #check: 1) if there's even 1 non air block in the tile 2) if there are "unbreakable" blocks in the tile (they don't have the "breakable" flag)

        #note: second check also applies to strubuildstures (just as a byproduct)
        - define blocks_in_way False
        - if <[tile].blocks.filter[material.name.equals[AIR].not].any> && <[tile].blocks.filter[has_flag[breakable].not].any>:
          - define can_build False
          - define blocks_in_way True

        - if <[can_build]>:
          - debugblock <[tile].blocks> d:2t color:0,255,0,128
          - flag player build.struct:<[tile]>
        - else:
          - flag player build.struct:!
          - if <[blocks_in_way]>:
            - debugblock <[tile].blocks> d:2t color:0,0,0,128

round5:
  type: procedure
  definitions: i
  debug: false
  script:
  - determine <element[<element[<[i]>].div[5]>].round.mul[5]>

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
    - define target_loc <[eye_loc].ray_trace[default=air;range=4;return=block]>

    - choose <player.held_item_slot>:
      - case 1:
        - actionbar wall

        - define closest_center <[target_loc].find_blocks.within[3].parse_tag[<[parse_value].with_x[<proc[round5].context[<[parse_value].x>]>].with_z[<proc[round5].context[<[parse_value].z>]>]>].sort_by_number[distance[<[target_loc]>]].first||null>

        #closest tile finds the nearest tile if any (their centers only)
        - define closest_tile_center <[target_loc].find_blocks_flagged[build].within[6].parse[flag[build.center]].sort_by_number[distance[<[target_loc]>]].first||null>

        #- [ if there are any nearby tiles, automatically "snap" the player's selected center to the nearby tile's y ] - #

        - if <[closest_tile_center]> != null:
          - define closest_center <[closest_center].with_y[<[closest_tile_center].y.add[1]>]>
        #if they're pointing in the air
        - else if <[target_loc].material.name> == air:
          - define closest_center <[closest_center].with_pitch[90].ray_trace>
        #otherwise, they're most likely pointing to the ground, so calculate it 1 up
        - else:
          - define closest_center <[closest_center].with_y[<[target_loc].y.add[1]>]>

        - if <[closest_center].material.name> != air:
          - define closest_center <[closest_center].above>

        - define build_loc <[target_loc].with_y[<[closest_center].y.sub[1]>]>
        - define rounded_x <proc[round5].context[<[build_loc].x>]>
        - define rounded_z <proc[round5].context[<[build_loc].z>]>
        - define tile_center <[origin].add[<[rounded_x]>,<[build_loc].y>,<[rounded_z]>]>

        - define can_build False
        - if <[tile_center].material.name> != AIR && !<[tile_center].has_flag[build]> || <[tile_center].flag[build.type]> != FLOOR:
          - define can_build True
          #move the build 1 down, since they're building on top of the ground
          - define tile_center <[tile_center].above>

        - playeffect effect:FLAME offset:0 at:<[tile_center]>

      - case 2:
        - actionbar floor
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
    - modifyblock <[build].blocks> oak_planks
    - flag <[build].blocks> build.<player.uuid>.health:<script[nimnite_config].data_key[materials.<[material]>.hp]>
    - flag <[build].blocks> build.center:<[build].center>
    - flag <[build].blocks> build.type:floor

    on player right clicks block location_flagged:build.center:
    - determine passively cancelled
    - define center <context.location.flag[build.center]>
    - define tile <[center].to_cuboid[<[center]>].expand[2,0,2]>
    - modifyblock <[tile]> air
    - flag <[tile].blocks> build:!
