
##turn this into a proc that checks if you can place or not
##minor problem: can't build walls on the sides of actual minecraft structures (ie mountain)

build_tiles:
  type: task
  debug: false
  scripts:
  - narrate "set the build tiles for each structure"

  floor:

        - define can_build False

        - define target_loc <[eye_loc].ray_trace[default=air;range=3]>

        #so players can't place floors THROUGH walls
        - if <[target_loc].has_flag[build]>:
          - define target_loc <[eye_loc].ray_trace[default=air;range=2]>

        - define x <proc[round4].context[<[target_loc].x>]>
        - define z <proc[round4].context[<[target_loc].z>]>

        #find's the bottom center of the ENTIRE tower
        #using eye_loc y so the y doesn't go below anything
        - define closest_center <[target_loc].with_x[<[x]>].with_z[<[z]>].with_y[<[eye_loc].y>].with_pitch[90].ray_trace>

        #if there's a floor there already there
        #checking .below because ray_trace returns right before the block
        - if <[closest_center].below.has_flag[build.type]> && <[closest_center].below.flag[build.type]> == FLOOR:
          - define closest_center <[closest_center].below>
        #if the tile is underground
        - else if <[closest_center].material.name> != air:
          - define closest_center <[closest_center].above>

        #round the wall heights by 5 based on the floor below the target_loc
        - define add_y <proc[round4].context[<[target_loc].forward[2].distance[<[closest_center]>].vertical.sub[2.5]>]>
        - define closest_center <[closest_center].above[<[add_y].is[LESS].than[0].if_true[0].if_false[<[add_y]>]>]>

        - define tile <[closest_center].to_cuboid[<[closest_center]>].expand[2,0,2]>

        #-if there's ANY build on the left, right, front, or behind
        - if <[closest_center].left[2].has_flag[build]> || <[closest_center].right[2].has_flag[build]> || <[closest_center].forward_flat[2].has_flag[build]> || <[closest_center].backward_flat[2].has_flag[build]>:
          - define can_build True
        #otherwise default to the ground
        - else:
          - define center <[closest_center].with_y[<[eye_loc].y>].with_pitch[90].ray_trace>
          - define tile <[center].to_cuboid[<[center]>].expand[2,0,2]>
          #- if <[closest_center].material.name> != air:
            #- define tile <[tile].shift[0,1,0]>


        - define blocks <[tile].blocks>
        #making sure there's either all air in that area or any thing being placed there is breakable
        - if <[blocks].filter[material.name.equals[AIR].not].is_empty> || <[blocks].filter[material.name.equals[AIR].not].filter[has_flag[breakable].not].is_empty>:
          - define can_build True
          #- define blocks_in_way False
        #- else:
          #- define blocks_in_way True

        #it there's already a build there
        - if <[tile].center.has_flag[build]>:
          - define can_build False

        #if too far
        - define no_preview:!
        - if <[tile].center.distance[<[eye_loc]>].vertical> > 6:
          - define can_build False
          - define no_preview True
          #- define blocks_in_way False

        #if there are blocks in the way, you can't build, otherwise, you can
        - if <[can_build]>:
          - debugblock <[blocks]> d:2t color:0,255,0,128
          - flag player build.struct:<[tile]>
        - else:
          - flag player build.struct:!
          - flag player build.root:!
          #- if <[blocks_in_way]>:
          - if !<[no_preview].exists>:
            - debugblock <[blocks]> d:2t color:0,0,0,128

  wall:

      - flag player build.root:!
      - define can_build False

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

      #base tile
      - define tile <[bottom_center].left[2].to_cuboid[<[bottom_center].with_yaw[<[yaw]>].right[2].above[4]>]>
      - define center <[tile].center.with_yaw[<[yaw]>]>

      #this new_y should only exist if there's a wall verticall or horizontally
      - define new_y:!

      #if ANY block below the wall is a build, move it one down
      - define vertical:!

      #if the player is still looking at the tile below, dont move the tile upwards
      - define block_looking_at <[eye_loc].ray_trace[return=block;range=5;default=air]>
      - if !<[block_looking_at].has_flag[build]> || <[tile].center> != <[block_looking_at].flag[build.center]>:
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
      - if <[center].left[2].has_flag[build]>:
        - define horizontal True
        - define can_build True
        - define new_y <[center].left[2].flag[build.structure].min.y>
      #-if there's a wall on the RIGHT side
      - else if <[center].right[2].has_flag[build]>:
        - define horizontal True
        - define can_build True
        - define new_y <[center].right[2].flag[build.structure].min.y>

      - if <[new_y].exists>:
        - define bottom_center <[bottom_center].with_y[<[new_y]>]>
        - define tile <[bottom_center].left[2].to_cuboid[<[bottom_center].right[2].above[4]>]>

      #if there's nothing attached vertically and horizontally, default to the ground (if there's space between the wall and the ground)
      - if !<[vertical].exists> && !<[horizontal].exists>:
        #it's a root tile
        - if <[bottom_center].below.material.name> == AIR:
          - define bottom_center <[bottom_center].with_pitch[90].ray_trace.with_yaw[<[yaw]>]>
          - define tile <[bottom_center].left[2].to_cuboid[<[bottom_center].right[2].above[4]>]>
          #if you're looking high up in the air and there really are no connecting walls, it'll ray trace onto a wall
          - if <[tile].min.below.has_flag[build]>:
            - define tile <[tile].shift[0,-1,0]>
          - define can_build True

      # - "can place" check

      - define blocks <[tile].blocks>
      #making sure there's either all air in that area or any thing being placed there is breakable
      - if <[blocks].filter[material.name.equals[AIR].not].is_empty> || <[blocks].filter[material.name.equals[AIR].not].filter[has_flag[breakable].not].is_empty>:
        - define can_build True
        - define blocks_in_way False
      - else:
        - define blocks_in_way True

      - define center <[tile].center.with_yaw[<[yaw]>]>
      #it there's already a build there
      - if <[center].has_flag[build]>:
        - define can_build False

      #if too far
      - define no_preview:!
      - if <[center].distance[<[target_loc]>].vertical> > 10:
        - define can_build False
        - define no_preview True

      - define blocks <[tile].blocks>
      - if <[can_build]>:
        - debugblock <[blocks]> d:2t color:0,255,0,128
        - flag player build.struct:<[tile]>
        - foreach <[center].left[3]>|<[center].right[3]>|<[center].above[3]>|<[center].below[3]> as:loc:
          - if <[loc].material.name> != air && !<[loc].has_flag[build]>:
            - flag player build.root
            - foreach stop
      - else:
        - flag player build.struct:!
        #- if <[blocks_in_way]>:
        - if !<[no_preview].exists>:
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

    - define tile <player.flag[build.struct]>
    - define center <[tile].center>
    - define blocks <[tile].blocks>

    - modifyblock <[blocks]> glass
    - modifyblock <[tile].center> air

    ###-make all the tiles have tile data for what's connected to each other and what's not
    ###doing this BEFORE flagging the blocks as the build structures to find the other tiles before intersections occur

    - define connected_tiles <proc[find_connected_tiles].context[<[center]>]>

    - flag <[blocks]> build.center:<[center]>
    - flag <[blocks]> build.health:<script[nimnite_config].data_key[materials.<[material]>.hp]>
    - flag <[blocks]> build.type:<player.flag[build.type]>
    #the cuboid
    - flag <[blocks]> build.structure:<[tile]>
    - flag <[blocks]> breakable

    - if <player.has_flag[build.root]>:
      - flag <[blocks]> build.root

    - else if <[connected_tiles].any>:
      #first, find any directly connected tiles
      - define connected_roots <[connected_tiles].filter[center.has_flag[build.root]]>
      - define connected_tiles <[connected_tiles].filter[center.has_flag[build.root].not]>
      #then add the indirectly connected tiles
      - foreach <[connected_tiles]> as:c_tile:
        - foreach <[c_tile].center.flag[build.connected_roots]> as:root:
          - define connected_roots <[connected_roots].include[<[root]>]>

      - foreach <[connected_roots]> as:root:
        - flag <[root].blocks> build.tiles:->:<[tile]>
        - flag <[blocks]> build.connected_roots:->:<[root]>

      - narrate <[connected_roots].size>
      - foreach <[connected_roots]> as:root:
        - playeffect effect:FLAME offset:0 at:<[root].center> visibility:1000

    ##- if <[connected_tiles].any>:
    ##  #-all root tiles have the flag "connected tiles" and all non-root tiles have the flag "connected roots"
    ##  - foreach <[connected_tiles]> as:c_tile:
    ##    #the other tiles
    ##    - flag <[c_tile].blocks> build.connected_tiles:->:<[tile]>
    ##    #the tile being placed

    ##  - flag <[blocks]> build.connected_tiles:<[connected_tiles].first.center.flag[build.connected_tiles]>

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
    - define connected_tiles <[tile_center].find_blocks_flagged[build].within[4].parse[flag[build.center]].deduplicate.parse[flag[build.structure]].filter[intersects[<[tile]>]].exclude[<[tile]>]>

    - foreach <[connected_tiles]> as:other_tile:
      - define connectors <[tile].intersection[<[other_tile]>].blocks>
      #- playeffect effect:soul_fire_flame offset:0 at:<[tile].center>|<[other_tile].center>
      #- playeffect effect:FLAME offset:0 at:<[connectors].parse[center]>
      #swap the connectors to whatever is already placed
      - flag <[connectors]> build:<[other_tile].center.flag[build]>

    ##- if <[tile_center].has_flag[build.connected_tiles]>:
    ##  #remove the tile being removed from the total tile-list of all connected tiles of that structure
    ##  - foreach <[tile_center].flag[build.connected_tiles]> as:c_tile:
    ##    - flag <[c_tile].blocks> build.connected_tiles:<-:<[tile]>
    ##  - define total_tiles <[tile_center].flag[build.connected_tiles].exclude[<[tile]>]>

    #checking the build centers instead of type, so the connectors between walls can work with this too
    - define actual_blocks <[tile].blocks.filter[flag[build.center].equals[<[tile_center]>]]>

    - modifyblock <[actual_blocks]> air
    - flag <[actual_blocks]> build:!

    ##- if <[total_tiles].exists> && <[total_tiles].filter[center.has_flag[build.root]].is_empty>:
    ##  - foreach <[total_tiles]> as:tile:
    ##    - modifyblock <[tile]> air
    ##    - flag <[tile].blocks> build:!
    ##    - wait 3t

find_connected_tiles:
  type: procedure
  definitions: center
  debug: false
  script:
  - if <[center].left[3].has_flag[build]>:
    #- narrate a
    - define connected_tiles:->:<[center].left[3].flag[build.structure]>
  - if <[center].right[3].has_flag[build]>:
    #- narrate b
    - define connected_tiles:->:<[center].right[3].flag[build.structure]>
  - if <[center].above[3].has_flag[build]>:
    #- narrate c
    - define connected_tiles:->:<[center].above[3].flag[build.structure]>
  - if <[center].below[3].has_flag[build]>:
    #- narrate d
    - define connected_tiles:->:<[center].below[3].flag[build.structure]>

  - if <[center].below[2].forward_flat[2].has_flag[build]>:
    #- narrate e
    - define connected_tiles:->:<[center].below[2].forward_flat[2].flag[build.structure]>
  - if <[center].below[2].backward_flat[2].has_flag[build]>:
    #- narrate f
    - define connected_tiles:->:<[center].below[2].backward_flat[2].flag[build.structure]>

  - if <[center].above[2].forward_flat[2].has_flag[build]>:
    #- narrate g
    - define connected_tiles:->:<[center].above[2].forward_flat[2].flag[build.structure]>
  - if <[center].above[2].backward_flat[2].has_flag[build]>:
    #- narrate h
    - define connected_tiles:->:<[center].above[2].backward_flat[2].flag[build.structure]>

  - if <[connected_tiles].exists>:
    - determine <[connected_tiles].deduplicate>
  - else:
    - determine <list[]>
