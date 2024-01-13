## [ Part of: Build System ] ##
#separated between files to make it easier to read

# - [ Description: Testing new stuff / debugging build related stuff. ] - #


display_nodes:
  type: task
  debug: false
  script:
    - define center <player.cursor_on.flag[build.center]||null>
    - if <[center]> == null:
      - narrate "<&c>Invalid tile."
      - stop
    - define nodes <[center].flag[build.nodes]||<list[]>>

    - modifyblock <[nodes]> diamond_block
    - wait 4s
    - modifyblock <[nodes]> oak_planks


connected_tiles_check:
  type: task
  debug: false
  script:
    - define center <player.cursor_on.flag[build.center]||null>
    - if <[center]> == null:
      - narrate "<&c>Invalid tile."
      - stop
    - define tile <[center].flag[build.structure]>
    - define type <[center].flag[build.type]>

    - define nearby_tiles <proc[find_nearby_tiles].context[<[center]>|<[tile]>]>
    - define connected_tiles <[nearby_tiles].filter[intersects[<[tile]>]]>
    - narrate "nearby method: <[connected_tiles].size>"

    - define connected_tiles:!
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
      - modifyblock <[loc]> diamond_block
      - if <[loc].has_flag[build.center]> && <[loc].flag[build.center].flag[build.structure]> != <[current_struct]> && <[loc].material.name> != AIR:
        - define connected_tiles:->:<[loc].flag[build.center].flag[build.structure]>

    - narrate "connected method: <[connected_tiles].size>"

#testing
bake_structures:
  type: task
  debug: false
  script:
    - if <player.cursor_on> == null:
      - narrate "<&c>Invalid selection."
      - stop

    - define sel_tile_center <player.cursor_on.flag[build.center]||null>

    - if <[sel_tile_center]> == null:
      - narrate "<&c>Invalid tile."
      - stop

    - narrate "Baking tile structure data..."

    - define sel_tile <[sel_tile_center].flag[build.structure]>

    #get_surrounding_tiles gets all the tiles connected to the inputted tile
    - define branches           <proc[get_surrounding_tiles].context[<[sel_tile]>|<[sel_tile_center]>].exclude[<[sel_tile]>]>

    #There's only six four (or less) for each cardinal
    #direction, so we use a foreach, and go through each one.
    - foreach <[branches]> as:starting_tile:
        #The tiles to check are a list of tiles that we need to get siblings of.
        #Each tile in this list gets checked once, and removed.
        - define tiles_to_check <list[<[starting_tile]>]>
        #The structure is a list of every tile in a single continous structure.
        #When you determine that a group of tiles needs to be broken, you'll go through this list.
        - define structure <list[<[starting_tile]>]>

        #The two above lists are emptied at the start of each while loop,
        #so that way previous tiles from other branches don't bleed into this one.
        - while <[tiles_to_check].any>:
            #Just grab the tile on top of the pile. It doesn't matter the order
            #in which we check, we'll get to them all eventually, unless the
            #strucure is touching the ground, in which case it doesn't really
            #matter.
            - define tile <[tiles_to_check].last>

            #if it doesn't, it's already removed
            - foreach next if:!<[tile].center.has_flag[build.center]>


            - define center <[tile].center.flag[build.center]>

            - foreach next if:<[center].chunk.is_loaded.not>

            - define type   <[center].flag[build.type]>

            - define is_root <proc[is_root].context[<[center]>|<[type]>]>


            #-FAKE ROOT CHECK
            #ONLY doing this for WORLD tiles, because it works fine with regular builds
            - define fake_root:!
            - define is_arch:!
            #fake root means that it's not *actually* connected to the tile
            #getting the *previous* tile, to check if this root tile was really connected to it
            - if <[center].flag[build.placed_by]||null> == WORLD && <[is_root]> && <[previous_tile].exists>:
              - if !<[previous_tile].intersects[<[tile]>]> || <[previous_tile].intersection[<[tile]>].blocks.filter[material.name.equals[air].not].is_empty>:
                - define fake_root True
              #-ARCH check (in buildings, only applies to walls)
              - if <[type]> == WALL:
                - define t_blocks <[tile].blocks.filter[flag[build.center].equals[<[center]>]]>
                #check for arches
                - define strip_1 <[t_blocks].filter[y.equals[<[center].y.sub[1]>]]>
                #check for stuff like *fences*
                - define strip_2 <[t_blocks].filter[y.equals[<[center].y>]]>
                #if the second to last bottom strip of the wall is air, it means it's not connectewd to the ground
                #this means that the first check failed, meaning that it's connected to the ground; so it's rooted, but it's not a real root
                - if <[strip_1].filter[material.name.equals[air].not].is_empty>:
                  - define fake_root True
                  - define is_arch   True

                - else if <[strip_2].filter[material.name.equals[air].not].is_empty>:
                  - define fake_root True


            - if <[is_root]> && !<[fake_root].exists>:
              - define total_roots:->:<[tile]>


            - define tiles_to_check:<-:<[tile]>

            - if <[fake_root].exists>:
              #it's called a "fake root", because it's not actually connected to the tile, but it's still a root, so it shouldn't break
              #because arches should break
              - define structure <[structure].exclude[<[tile]>]> if:!<[is_arch].exists>

            - else:

              - define previous_tile <[tile]>

              #Next, we get every surrounding tile, but only if they're not already
              #in the structure list. That means that we don't keep rechecking tiles
              #we've already checked.
              - define surrounding_tiles <proc[get_surrounding_tiles].context[<[tile]>|<[center]>].exclude[<[structure]>]>
              #only get the surrounding tiles if they're actually connected (not by air blocks), if it's a world block

              #We add all these new tiles to the structure, and since we already excluded
              #the previous list of tiles in the structure, we don't need to deduplicate.
              - define structure:|:<[surrounding_tiles]>
              #Since these are all new tiles, we need to check them as well.
              - define tiles_to_check:|:<[surrounding_tiles]>

            - wait 1t
            #<[loop_index].mod[10].is[OR_MORE].than[10]>

    - define structure   <[structure].deduplicate>
    - define total_roots <[total_roots].deduplicate>
    - foreach <[structure]> as:tile:
      #sorting by closest, so the tiles break in correct order
      - flag <[center]> build.baked.structure:<[structure].sort_by_number[center.distance[<[center]>]]>
      - flag <[center]> build.baked.roots:<[total_roots]>

    - narrate "<&a>Structure data baked! <&7>(<&b><[structure].size><&7> tiles, <&b><[total_roots].size||null><&7> roots)"


clear_build_queues:
  type: task
  debug: false
  script:
    - foreach <script[build_system_handler].queues> as:q:
      - queue clear <[q]>

tile_visualiser_command:
  type: command
  name: tv
  debug: false
  description: View the tile you're looking at in the form of debugblocks
  usage: /tv
  aliases:
    - tv
  script:
  - if <player.has_flag[tv]>:
    - flag player tv:!
    - stop
  - narrate "tile visualiser program initiated"
  - flag player tv
  - while <player.has_flag[tv]>:
    - define target_block <player.cursor_on||null>
    - if <[target_block]> != null && <[target_block].has_flag[build.center]>:
      - define center <[target_block].flag[build.center]>
      - define blocks <[center].flag[build.structure].blocks.filter[flag[build.center].equals[<[center]>]]>
      - debugblock <[blocks]> d:2t color:0,0,0,75
    - wait 1t
  - narrate "tile visualiser program terminated"

  break:
  #required definitions:
  # - <[center]>
  #

    - define tile <[center].flag[build.structure]>
    - define center <[center].flag[build.center]>
    - define type <[center].flag[build.type]>

    - inject build_system_handler.replace_tiles

    #-actually removing the original tile
    #so it only includes the parts of the tile that are its own (since each cuboid intersects by one)
    - define blocks <[tile].blocks.filter[flag[build.center].equals[<[center]>]]>

    #so you don't break barrier blocks either (for chests and ammo boxes)
    - define remove_blocks <[tile].blocks.filter[has_flag[build_existed].not].filter[material.name.equals[barrier].not]>

      #this way, there's no little holes on the ground after breaking walls that are on the floor
    - if <[center].flag[build.placed_by]> == WORLD && <[type]> != FLOOR:
      - define keep_blocks <[remove_blocks].filter[below.material.name.equals[air].not].filter[below.has_flag[build].not]>
      - define remove_blocks <[remove_blocks].exclude[<[keep_blocks]>]>

    - modifyblock <[remove_blocks]> air

    - if <[center].flag[build.placed_by]> == WORLD:
      #not breaking containers, because they dont break in fort either
      #- define containers <[center].flag[build.attached_containers]||list<[]>>
      #- foreach <[containers]> as:c_loc:
        #- run fort_chest_handler.break_container def:<map[loc=<[c_loc]>]>
      - define props <[center].flag[build.attached_props]||null>
      - if <[props]> != null:
        #should i check is_spawned, or just remove the attached prop flag from the tile?
        - foreach <[props].filter[is_spawned]> as:prop_hb:
          - run fort_prop_handler.break def:<map[prop_hb=<[prop_hb]>]>

      - flag <[blocks]> build:!
      #not doing build DOT existed, since it'll mess up other checks
      - flag <[blocks].filter[has_flag[build_existed]]> build_existed:!

    ######## [ DISABLED CHAIN SYSTEM FOR BUILDINGS ] ############
      - stop
    ########

    #order: first placed -> last placed
    - define priority_order <list[wall|floor|stair|pyramid]>
    - foreach <[replace_tiles_data].parse_tag[<[parse_value]>/<[priority_order].find[<[parse_value].get[build_type]>]>].sort_by_number[after[/]].parse[before[/]]> as:tile_data:
      - run build_system_handler.place def:<[tile_data]>

    - run build_system_handler.remove_tiles def:<map[tile=<[tile]>;center=<[center]>]>

  stair:
    - define total_set_blocks <proc[stair_blocks_gen].context[<[center]>]>

    #in case this stair is just being "re-applied" (so the has_flag[build.not] doesn't exclude its own stairs)
    - define own_stair_blocks <[total_set_blocks].filter[has_flag[build.center]].filter[flag[build.center].equals[<[center]>]]>

    #"extra" stair blocks from other stairs/pyramids (turn them into planks like pyramids do)
    - define set_connector_blocks <[total_set_blocks].filter[has_flag[build.center]].filter[material.name.after_last[_].equals[stairs]].exclude[<[own_stair_blocks]>]>

    #this way, the top of walls and bottom of walls turn into stairs (but not the sides)
    - define top_middle <[center].forward_flat[2].above[2]>
    - define top_points <list[<[top_middle].left>|<[top_middle]>|<[top_middle].right>]>
    - define bot_middle <[center].backward_flat[2].below[2]>
    - define bot_points <list[<[bot_middle].left>|<[bot_middle]>|<[bot_middle].right>]>
    #this way, pyramid stairs still can't be overriden
    - define override_blocks <[top_points].include[<[bot_points]>].filter[flag[build.center].flag[build.type].equals[pyramid].not]>

    #so it doesn't completely override any previously placed tiles
    - define set_blocks      <[total_set_blocks].filter[has_flag[build.center].not].include[<[own_stair_blocks]>].include[<[override_blocks]>]>

    #-don't include edited blocks
    - define set_blocks      <[set_blocks].filter[has_flag[build.edited].not]> if:!<[is_editing]>

    #-don't include blocks that existed there before hand
    #existing blocks are either world-placed blocks, or just terrain blocks
    - define existing_blocks <proc[get_existing_blocks].context[<list_single[<[set_blocks]>]>]>
    - flag <[existing_blocks]> build_existed

    - define set_blocks      <[set_blocks].exclude[<[existing_blocks]>]>

    - define direction <[center].yaw.simple>
    - define material <[base_material]>_stairs
    - define material weathered_cut_copper_stairs if:<[base_material].equals[weathered_copper]>
    - define material <[material]>[direction=<[direction]>]
    - modifyblock <[set_blocks]> <[material]>

    #if they're stairs and they are going in the same direction, to keep the stairs "smooth", forget about adding connectors to them
    - define consecutive_stair_blocks <[set_connector_blocks].filter[flag[build.center].flag[build.type].equals[stair]].filter[material.direction.equals[<[direction]>]]>
    - define set_blocks               <[set_connector_blocks].exclude[<[consecutive_stair_blocks]>].exclude[<[override_blocks]>].filter[has_flag[build.edited].not]>
    - define set_blocks               <[set_blocks].filter[has_flag[build.edited].not]> if:!<[is_editing]>
    - define existing_blocks <proc[get_existing_blocks].context[<list_single[<[set_blocks]>]>]>
    - flag <[existing_blocks]> build_existed

    - define set_blocks      <[set_blocks].exclude[<[existing_blocks]>]>

    - modifyblock <[set_blocks]> <map[oak=oak_planks;brick=bricks;weathered_copper=weathered_copper].get[<[base_material]>]>

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

  remove_tiles:

    - define broken_tile        <[data].get[tile]>
    - define broken_tile_center <[data].get[center]>

    #get_surrounding_tiles gets all the tiles connected to the inputted tile
    - define branches           <proc[get_surrounding_tiles].context[<[broken_tile]>|<[broken_tile_center]>].exclude[<[broken_tile]>]>

    #There's only six four (or less) for each cardinal
    #direction, so we use a foreach, and go through each one.
    - foreach <[branches]> as:starting_tile:

        - if <[tile_check_timeout].exists>:
          - foreach stop

        #The tiles to check are a list of tiles that we need to get siblings of.
        #Each tile in this list gets checked once, and removed.
        - define tiles_to_check <list[<[starting_tile]>]>
        #The structure is a list of every tile in a single continous structure.
        #When you determine that a group of tiles needs to be broken, you'll go through this list.
        - define structure <list[<[starting_tile]>]>

        #The two above lists are emptied at the start of each while loop,
        #so that way previous tiles from other branches don't bleed into this one.
        - while <[tiles_to_check].any>:
            #Just grab the tile on top of the pile. It doesn't matter the order
            #in which we check, we'll get to them all eventually, unless the
            #strucure is touching the ground, in which case it doesn't really
            #matter.
            - if <[loop_index].mod[2]> == 0:
              - define tile <[tiles_to_check].first>
            - else:
              - define tile <[tiles_to_check].last>

            #if it doesn't, it's already removed
            - foreach next if:!<[tile].center.has_flag[build.center]>

            #returns null i think whenever players die and they place the build
            - define center <[tile].center.flag[build.center]||null>
            - if <[center]> == null:
              - stop

            ######## [ DISABLED CHAIN SYSTEM FOR BUILDINGS ] ############
            - foreach next if:<[tile].flag[build.placed_by].equals[WORLD]||false>
            ########
            - foreach next if:<[center].chunk.is_loaded.not>

            - define type   <[center].flag[build.type]>

            - define is_root <proc[is_root].context[<[center]>|<[type]>]>

            #- [For Debug Purposes]
            #- debugblock <[tile].blocks> d:3m color:0,0,0,150 if:<[is_root]>

            #-FAKE ROOT CHECK
            #ONLY doing this for WORLD tiles, because it works fine with regular builds
            - define fake_root:!
            - define is_arch:!
            #fake root means that it's not *actually* connected to the tile
            #getting the *previous* tile, to check if this root tile was really connected to it
            - if <[center].flag[build.placed_by]||null> == WORLD && <[is_root]> && <[previous_tile].exists>:
              #- debugblock <[tile].blocks> d:3m color:155,0,0,150
              - if !<[previous_tile].intersects[<[tile]>]> || <[previous_tile].intersection[<[tile]>].blocks.filter[material.name.equals[air].not].is_empty>:
                #- debugblock <[tile].blocks> d:3m color:155,0,0,150
                - define fake_root True
              #-ARCH check (in buildings, only applies to walls)
              - if <[type]> == WALL:
                - define t_blocks <[tile].blocks.filter[flag[build.center].equals[<[center]>]]>
                #check for arches
                - define strip_1 <[t_blocks].filter[y.equals[<[center].y.sub[1]>]]>
                #check for stuff like *fences*
                - define strip_2 <[t_blocks].filter[y.equals[<[center].y>]]>
                #if the second to last bottom strip of the wall is air, it means it's not connectewd to the ground
                #this means that the first check failed, meaning that it's connected to the ground; so it's rooted, but it's not a real root
                - if <[strip_1].filter[material.name.equals[air].not].is_empty>:
                  - define fake_root True
                  - define is_arch   True

                - else if <[strip_2].filter[material.name.equals[air].not].is_empty>:
                  - define fake_root True

            #If the tile is touching the ground, then skip this branch. The
            #tiles_to_check and structure lists get flushed out and we start
            #on the next branch. When we next the foreach, we are
            #also breaking out of the while, so we don't need to worry about
            #keeping track (like you had with has_root)
            - foreach next if:<[is_root].and[<[fake_root].exists.not>]>

            #If the tile ISN'T touching the ground, then first, we remove it
            #from the tiles to check list, because obvi we've already checked
            #it.

            - define tiles_to_check:<-:<[tile]>

            - if <[fake_root].exists>:
              #it's called a "fake root", because it's not actually connected to the tile, but it's still a root, so it shouldn't break
              #because arches should break
              - define structure <[structure].exclude[<[tile]>]> if:!<[is_arch].exists>
            - else:

              - define previous_tile <[tile]>

              #Next, we get every surrounding tile, but only if they're not already
              #in the structure list. That means that we don't keep rechecking tiles
              #we've already checked.
              - define surrounding_tiles <proc[get_surrounding_tiles].context[<[tile]>|<[center]>].exclude[<[structure]>]>
              #only get the surrounding tiles if they're actually connected (not by air blocks), if it's a world block

              #We add all these new tiles to the structure, and since we already excluded
              #the previous list of tiles in the structure, we don't need to deduplicate.
              - define structure:|:<[surrounding_tiles]>
              #Since these are all new tiles, we need to check them as well.
              - define tiles_to_check:|:<[surrounding_tiles]>

              #calculating total loop index, since there are whiles inside of foreaches
              - define total_loop_index:++
              ##this is added as an attempt to fix lag, untested
              #- actionbar <[total_loop_index]>
            #so if it's too many tiles, it wont even load them
              #- if <[broken_tile_center].flag[build.placed_by]||null> == WORLD && <[total_loop_index]> >= 30:
              #  - define tile_check_timeout True
              #  - narrate :LSDKJF:SLDKFJ
              #  - while stop

            - wait 1t
        #If we get to this point, then that means we didn't skip out early with foreach.
        #That means we know it's not touching ground anywhere, so now we want to break
        #each tile. So we go through the structure list, and break each one (however you handle that.)
        #-break the tiles
        - foreach <[structure]> as:tile:

          #attempts to fix the "too many sounds compare to tiles" issue
          - if !<[tile].center.has_flag[build.center]>:
            - foreach next

          #- announce <[tile].center.flag[build.center]> to_console
          #do you get mats from world structures that are broken by chain? (i dont think so)

          - wait 3t

          - define blocks <[tile].blocks.filter[flag[build.center].equals[<[tile].center.flag[build.center]||null>]]>

          #defining sound before turning material to air
          - define sound <[tile].center.material.block_sound_data.get[break_sound]>

          - foreach <[tile].blocks> as:b:
            - playeffect effect:BLOCK_CRACK at:<[b].center> offset:0 special_data:<[b].material> quantity:10 visibility:100
          #everything is being re-applied anyways, so it's ok
          - ~modifyblock <[tile].blocks> air
          #-often too many sounds compared to blocks breaking? (i just made modifyblock waitable)
          - playsound <[tile].center> sound:<[sound]> pitch:0.8

          - flag <[blocks]> build:!

    # narrate "removed <[structure].size||0> tiles"

  #-this *safely* prepares the tile for removal (by replacing the original tile data with the intersecting tile data)
  replace_tiles:
    #required definitions:
    # - <[tile]>
    # - <[center]>

    - define replace_tiles_data <list[]>
    #-connecting blocks system
    - define nearby_tiles <proc[find_nearby_tiles].context[<[center]>|<[tile]>]>

    #excluding tile in attempts to prevent tile center error?
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

      ##only adding player-placed tiles to replace tile data (since world-placed shouldn't be replaced with player builds, but flag replace is ok)
      #doing this so AFTER the original tile is completely removed
      #if_null is for natural structures (they don't have PLACED_BY flag) -> probably shouldve done something like, "PLACED_BY: NATURAL", but it's identified with build.natural
      - define replace_tiles_data:<[replace_tiles_data].include[<[tile_data]>]> if:<[c_tile_center].flag[build.placed_by].equals[WORLD].not.if_null[false]>

      #make the connectors a part of the other tile
      - flag <[connecting_blocks]> build.center:<[c_tile_center]>

  place:
    - define tile       <[data].get[tile]>
    - define center     <[data].get[center]>
    - define build_type <[data].get[build_type]>

    - define is_editing <[data].get[is_editing]||false>

    - define base_material <map[wood=oak;brick=brick;metal=weathered_copper].get[<[data].get[material]>]>

    #build_place_tile task script found in: b_tiles.dsc
    - choose <[build_type]>:

      - case wall floor:
        - inject build_place_tile.square

      - case stair:
        - inject build_place_tile.stair

      - case pyramid:
        - inject build_place_tile.pyramid

      - case trap:
        - narrate "<&e>Coming soon."