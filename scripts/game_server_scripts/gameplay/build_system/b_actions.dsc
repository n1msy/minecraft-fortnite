## [ Part of: Build System ] ##
#separated between files to make it easier to read

# - [ Description: Placing/Breaking/Editing tiles. ] - #

build_system_handler:
  type: world
  debug: false
  definitions: data|nodes
  events:
    # - [ Enable / Disable Editing ] - #
    on player drops item flagged:build:
    - determine passively cancelled
    #to prevent build from placing, since it considers dropping as clicking a block
    - flag player build.dropped duration:1t
    - inject build_edit.toggle

    on player clicks in inventory flagged:build:
    - determine cancelled

    # - [ Material Switch / Remove Edit ] - #
    on player right clicks block flagged:build.material:
    - if <player.has_flag[build.edit_mode]>:
      #-reset edits
      - define edited_blocks <player.flag[build.edit_mode.tile].blocks.filter[has_flag[build.edited]]>
      - if <[edited_blocks].is_empty>:
        - stop
      - playsound <player> sound:BLOCK_GRAVEL_BREAK pitch:1
      - flag <[edited_blocks]> build.edited:!
      - flag player build.edit_mode.blocks:!
      - stop
    #-switch materials
    - define new_mat <map[wood=brick;brick=metal;metal=wood].get[<player.flag[build.material]>]>
    - define sound   <map[wood=ITEM_ARMOR_EQUIP_LEATHER;brick=ITEM_ARMOR_EQUIP_GENERIC;metal=ITEM_ARMOR_EQUIP_NETHERITE].get[<[new_mat]>]>

    - flag player build.material:<[new_mat]>

    - playsound <player> sound:<[sound]> pitch:1.75 volume:0.5

    - inject update_hud

    #-place
    on player left clicks block flagged:build:
      - determine passively cancelled

      #so builds dont place when pressing Q or "drop"
      - if <player.has_flag[build.dropped]>:
        - stop

      - if <player.has_flag[build.edit_mode]>:
        - run build_edit
        - stop

      #they can't build if they dont have this flag
      - if !<player.has_flag[build.struct]>:
        - stop

      - define tile <player.flag[build.struct]>
      - define center <player.flag[build.center]>
      - define build_type <player.flag[build.type]>
      - define material <player.flag[build.material]>

        #automatically switch mats if you're out of the current material
      - inject build_system_handler.auto_switch

      - run fort_pic_handler.mat_count def:<map[qty=10;mat=<[material]>;action=remove]>

      #because walls and floors override stairs
      - define total_blocks <[tile].blocks>
      - define override_blocks <[total_blocks].filter[has_flag[build.center]].filter_tag[<list[pyramid|stair].contains[<[filter_value].flag[build.center].flag[build.type]>]>]>

      - define terrain_override_whitelist <list[polished_blackstone_slab|blackstone_slab]>
      #checking if it doesn't have build.CENTER isntead of just "build" because for some reason some blocks have the "build" flag, even though they're info is removed?
      - define terrain_blocks <[tile].blocks.filter[has_flag[build].not].filter[material.name.equals[air].not].filter_tag[<[terrain_override_whitelist].contains[<[filter_value].material.name>].not>]>
      - define blocks <[total_blocks].filter[has_flag[build.center].not].exclude[<[terrain_blocks]>].include[<[override_blocks]>]>

      #defining nodes so i dont have to check twice
      - define connected_nodes <proc[find_nodes].context[<[center]>|<[build_type]>]>
      - definemap data:
          tile:            <[tile]>
          center:          <[center]>
          build_type:      <[build_type]>
          material:        <[material]>
          connected_nodes: <[connected_nodes]>

      # - [ ! ] Places the tile [ ! ] - #
      - run build_system_handler.place def:<[data]>

      - define health <script[nimnite_config].data_key[materials.<[material]>.hp]>

      #do this before flagging the blocks, that way the nodes correctly find its connected tiles
      - flag <[center]> build.nodes:|:<[connected_nodes]>

      - flag <[center]> build.structure:<[tile]>
      - flag <[center]> build.type:<[build_type]>
      - flag <[center]> build.health:<[health]>
      - flag <[center]> build.material:<[material]>
      - flag <[center]> build.placed_by:<player>
      - flag <[center]> build.is_root if:<proc[is_root].context[<[center]>|<[build_type]>]>

      - flag <[blocks]> build.center:<[center]>

      #doing it after intializing the tile, just because it makes more sense
      - flag <[connected_nodes]> build.nodes:->:<[center]>

      - define yaw <map[North=0;South=180;West=-90;East=90].get[<player.location.yaw.simple>]>

      #-Tile place fx
      - playsound <[center]> sound:<[center].material.block_sound_data.get[place_sound]> pitch:0.8
      #no need to filter materials for non-air, since block crack for air is nothing
      - foreach <[blocks]> as:b:
        - if <[build_type]> == wall:
          - define effect_loc <[b].center.with_yaw[<[yaw]>].forward_flat[0.5]>
        - else:
          - define effect_loc <[b].center.above>
        - playeffect effect:BLOCK_CRACK at:<[effect_loc]> offset:0 special_data:<[b].material> quantity:5 visibility:100

  auto_switch:
    - if <player.flag[fort.<[material]>.qty]||0> < 10:
      - define other_mats <list[wood|brick|metal].exclude[<[material]>]>
      - foreach <[other_mats]> as:mat:
        - if <player.flag[fort.<[mat]>.qty]||0> > 10:
          - define switched True
          - flag player build.material:<[mat]>
          - define material <[mat]>
          - inject update_hud
          - foreach stop
      #aka there's no mats left to build with
      - stop if:<[switched].exists.not>

  structure_damage:
    - define center           <[data].get[center]>
    - define structure_damage <[data].get[damage]>

    - if <[center].as[location]||null> == null:
      - narrate "<&c>An error occured during structure damage."
      - stop

    - define hp       <[center].flag[build.health]>
    - define mat_type <[center].flag[build.material]>
    #filtering so connected blocks aren't affected
    - define blocks   <[center].flag[build.structure].blocks.filter[flag[build.center].equals[<[center]>]]>
    - if !<[center].has_flag[build.natural]>:
      - define max_health <script[nimnite_config].data_key[materials.<[mat_type]>.hp]>
    #for natural structures
    - else:
      - define struct_name <[center].flag[build.natural.name]>
      - define max_health   <script[nimnite_config].data_key[structures.<[struct_name]>.health]>

    - define new_health <[hp].sub[<[structure_damage]>]>
    - if <[new_health]> > 0:
      - flag <[center]> build.health:<[new_health]>

      - run fort_pic_handler.display_build_health def:<map[tile_center=<[center]>;health=<[new_health]>;max_health=<[max_health]>]>

      - define progress <element[10].sub[<[new_health].div[<[max_health]>].mul[10]>]>
      - foreach <[blocks]> as:b:
        - blockcrack <[b]> progress:<[progress]> players:<server.online_players>
      - stop

    #otherwise, break the tile and anything else connected to it
    - foreach <[blocks]> as:b:
      - blockcrack <[b]> progress:0 players:<server.online_players>
      - playeffect effect:BLOCK_CRACK at:<[b].center> offset:0 special_data:<[b].material> quantity:10 visibility:100

    #-natural structures break a bit differently
    - if <[center].has_flag[build.natural]>:
      - define struct_type <[center].flag[build.type]>
      - define blocks <[blocks].include[<[center]>]>
      - run fort_pic_handler.break_natural_structure def:<map[center=<[center]>;blocks=<[blocks]>;struct_type=<[struct_type]>]>
      - stop

    - inject build_system_handler.break

  break:
  #required definitions:
  # - <[center]>
  #

    - define tile      <[center].flag[build.structure]>
    - define center    <[center].flag[build.center]>
    - define type      <[center].flag[build.type]>
    - define nodes     <[center].flag[build.nodes]||<list[]>>
    - define placed_by <[center].flag[build.placed_by]>

    #get the real blocks *before* resetting tile data, so it can be removed correctly
    #(whatever is removed gets added back at the end)
    - define real_blocks <[tile].blocks.filter[flag[build.center].equals[<[center]>]]>


    - define remove_blocks  <[real_blocks].filter[material.name.equals[barrier].not]>

    #place the connected tiles again to update flag data of the intersecting tiles
    #applies to WORLD tiles too, except ONLY the flag DATA
    - inject build_system_handler.update_connected_tiles

    #NOW get the "real blocks" of the tile, after connected tile data has been restored
    #so it only includes the parts of the tile that are its own (since each cuboid intersects by one)

    - define real_blocks <[real_blocks].exclude[<[exclude_block_from_reset].if_null[<list[]>]>]>

    #
    - if <[placed_by]> == WORLD:
      #this way, there's no little holes on the ground after breaking walls that are on the floor
      - if <[type]> != FLOOR:
        - define keep_blocks <[remove_blocks].filter[below.material.name.equals[air].not].filter[below.has_flag[build].not]>
        - define remove_blocks <[remove_blocks].exclude[<[keep_blocks]>]>
      #remove world-placed tiles
      - modifyblock <[remove_blocks]> air
      - inject build_system_handler.break_props
      - flag <[real_blocks]> build:!
      # - ~ Chain effect disabled for world structures. ~ - #
      - stop
     #

    #remove player-placed tiles
    - modifyblock <[remove_blocks]> air

    - flag <[nodes]> build.nodes:<-:<[center]>
    #excluding connecting interesection blocks
    - flag <[real_blocks]> build:!

    #- maybe a better, more optimized way to do this?
    #reset any connected tiles
    - define priority_order <list[wall|floor|stair|pyramid]>
    - foreach <[replace_tiles_data].parse_tag[<[parse_value]>/<[priority_order].find[<[parse_value].get[build_type]>]>].sort_by_number[after[/]].parse[before[/]]> as:tile_data:
      - run build_system_handler.place def:<[tile_data]>

    - run build_system_handler.chain_effect def.nodes:<[nodes]>

  #-this *safely* prepares the tile for removal (by replacing the original tile data with the intersecting tile data)
  update_connected_tiles:
    #required definitions:
    # - <[tile]>
    # - <[center]>

    - define replace_tiles_data <list[]>

    - foreach <[nodes]> as:c_tile_center:

      - define c_tile            <[c_tile_center].flag[build.structure]>
      - define c_tile_type       <[c_tile_center].flag[build.type]>
      - define c_connected_nodes <[c_tile_center].flag[build.nodes]>
      #flag the "connected blocks" to the other tile data values that were connected to the tile being removed
      - define connecting_blocks <[c_tile].intersection[<[tile]>].blocks>

      - definemap tile_data:
          tile:           <[c_tile]>
          center:         <[c_tile_center]>
          build_type:     <[c_tile_type]>
          #doing this instead of center, since pyramid center is a slab
          material:       <[c_tile_center].flag[build.material]>
          connected_nodes: <[c_connected_nodes].exclude[<[center]>]>

      #if_null is for natural structures (they don't have PLACED_BY flag) -> probably shouldve done something like, "PLACED_BY: NATURAL", but it's identified with build.natural
      #world fallback is for NATURAL structures
      - if <[c_tile_center].flag[build.placed_by]||WORLD> != WORLD:
        - define replace_tiles_data:<[replace_tiles_data].include[<[tile_data]>]>

      - define exclude_block_from_reset:|:<[connecting_blocks]>
      #make the connectors a part of the other tile
      - flag <[connecting_blocks]> build.center:<[c_tile_center]>

      #if there's a center among the stairs (left or right side) that was removed
      #checking for both pyramids AND stairs, since they both take up an entire cube, and not flat
      - if <[type]> == WALL:
        - if <[c_tile_type]> == STAIR || <[c_tile_type]> == PYRAMID:
          - define removed_center <[connecting_blocks].filter[has_flag[build.placed_by]].first||null>
          #not just removing the build flag, in case it's being used somewhere else
          #(probably will never happen, but better to be safe than sorry)
          - if <[removed_center]> != null:
            - flag <[removed_center]> build.nodes:!
            - flag <[removed_center]> build.structure:!
            - flag <[removed_center]> build.type:!
            - flag <[removed_center]> build.health:!
            - flag <[removed_center]> build.material:!
            - flag <[removed_center]> build.placed_by:!
            - flag <[removed_center]> build.is_root:!

  chain_effect:

    - define branches <[nodes].parse[flag[build.structure]]>

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

            #alternating between the top to bottom to find the root tiles the fastest
            #(only problem is if the structure is massive and the root is in the middle)
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

            # - [ DISABLED CHAIN SYSTEM FOR BUILDINGS ] - #
            - foreach next if:<[tile].flag[build.placed_by].equals[WORLD]||false>
            - foreach next if:<[center].chunk.is_loaded.not>

            - define type   <[center].flag[build.type]>

            - define is_root <[center].has_flag[build.is_root]>

            #If the tile is touching the ground, then skip this branch. The
            #tiles_to_check and structure lists get flushed out and we start
            #on the next branch. When we next the foreach, we are
            #also breaking out of the while, so we don't need to worry about
            #keeping track (like you had with has_root)
            - foreach next if:<[is_root]>

            #If the tile ISN'T touching the ground, then first, we remove it
            #from the tiles to check list, because obvi we've already checked
            #it.

            - define tiles_to_check:<-:<[tile]>


            - define previous_tile <[tile]>

            #Next, we get every surrounding tile, but only if they're not already
            #in the structure list. That means that we don't keep rechecking tiles
            #we've already checked.
            - define surrounding_tiles <[center].flag[build.nodes].parse[flag[build.structure]].exclude[<[structure]>]>
  
            #We add all these new tiles to the structure, and since we already excluded
            #the previous list of tiles in the structure, we don't need to deduplicate.
            - define structure:|:<[surrounding_tiles]>
            #Since these are all new tiles, we need to check them as well.
            - define tiles_to_check:|:<[surrounding_tiles]>

            - wait 1t
        #If we get to this point, then that means we didn't skip out early with foreach.
        #That means we know it's not touching ground anywhere, so now we want to break
        #each tile. So we go through the structure list, and break each one (however you handle that.)

        #-break the tiles
        - foreach <[structure]> as:tile:
          - wait 3t
          - define blocks <[tile].blocks.filter[flag[build.center].equals[<[tile].center.flag[build.center]||null>]]>
          #defining sound before turning material to air
          - define sound <[tile].center.material.block_sound_data.get[break_sound]>

          - foreach <[tile].blocks> as:b:
            - playeffect effect:BLOCK_CRACK at:<[b].center> offset:0 special_data:<[b].material> quantity:10 visibility:100
          #everything is being re-applied anyways, so it's ok
          - ~modifyblock <[tile].blocks> air
          - playsound <[tile].center> sound:<[sound]> pitch:0.8

          - flag <[blocks]> build:!

  place:
    #im not sure if this path is even necessary atp lol

    - define tile            <[data].get[tile]>
    - define center          <[data].get[center]>
    - define build_type      <[data].get[build_type]>
    - define connected_nodes <[data].get[connected_nodes]>

    - define is_editing     <[data].get[is_editing]||false>

    - define base_material <map[wood=oak;brick=brick;metal=weathered_copper].get[<[data].get[material]>]>

    ##optimization thing: we can do all the calculating for the place tile stuff, when the player places the tile down and just once that time
    ##i feel like im repeating the same thing twice?
    #exclude any terrain terrain
    - define terrain_override_whitelist <list[polished_blackstone_slab|blackstone_slab]>
    - define exclude_blocks <[tile].blocks.filter[has_flag[build].not].filter[material.name.equals[air].not].filter_tag[<[terrain_override_whitelist].contains[<[filter_value].material.name>].not>]>
    - define exclude_blocks:|:<[tile].blocks.filter[has_flag[build.edited]]> if:!<[is_editing]>

    #so player builds don't override WORLD builds
    - foreach <[connected_nodes]> as:n:
      - if <[n].flag[build.placed_by]> == WORLD:
        - define exclude_blocks:|:<[n].flag[build.structure].blocks.filter[flag[build.center].equals[<[n]>]].filter[material.name.equals[air].not]>

    #build_place_tile task script found in: b_tiles.dsc
    - inject build_place_tile.<[build_type]>

  break_props:
    #not breaking containers, because they dont break in fort either
    #- define containers <[center].flag[build.attached_containers]||list<[]>>
    #- foreach <[containers]> as:c_loc:
      #- run fort_chest_handler.break_container def:<map[loc=<[c_loc]>]>
    - define props <[center].flag[build.attached_props]||null>
    - if <[props]> != null:
      - foreach <[props].filter[is_spawned]> as:prop_hb:
        - run fort_prop_handler.break def:<map[prop_hb=<[prop_hb]>]>

#Q to enter/exit edit mode, Left-Click to edit, click again to remove edit, right-click to reset
build_edit:
  type: task
  debug: false
  script:
    # - [ Modify Edit Blocks ] - #
    #ran by "on player left clicks block flagged:build:"

    - define edit_tile    <player.flag[build.edit_mode.tile]>
    - define eye_loc      <player.eye_location>
    - define target_block <[eye_loc].ray_trace[return=block;range=5;default=air]>
    #if they're not even looking at an edit block
    - if !<[target_block].has_flag[build.center]>:
      - stop
    #if they're looking at a different tile instead of the target tile
    - if <[target_block].flag[build.center].flag[build.structure]> != <[edit_tile]>:
      - stop

    #in case the target_block is air because pyramids and stairs use full 5x5x5 grids
    - if <[target_block].material.name> == air:
      - stop

    #-add edit
    - if !<[target_block].has_flag[build.edited]>:
      - define edited_blocks <[edit_tile].blocks.filter[flag[build.center].equals[<[target_block].flag[build.center]>].if_null[false]].filter[has_flag[build.edited]]>
      #-so the max blocks you can edit out is 9 (so you can't edit out an entire tile)
      - if <[edited_blocks].size> == 9:
        - playsound <player> sound:ENTITY_VILLAGER_NO pitch:2
        - stop
      - playsound <player> sound:BLOCK_GRAVEL_BREAK pitch:1.5
      - flag <[target_block]> build.edited
      #this flag is for checking which blocks the player edited during the session, in case they toggle
      #build without "saving" their edit (it's not really necessary to do this, but it's good for safety and good practice it feels like)
      - flag player build.edit_mode.blocks:->:<[target_block]>
    #-remove edit
    - else:
      - playsound <player> sound:BLOCK_GRAVEL_BREAK pitch:1.25
      - flag <[target_block]> build.edited:!

  toggle:
    # - Toggle Editing [ OFF ]
    #and apply edits
    #ran by on player drops item flagged:build:

    - if <player.has_flag[build.edit_mode]>:
      - define tile          <player.flag[build.edit_mode.tile]>
      - define edited_blocks <[tile].blocks.filter[has_flag[build.edited]]>
      - if <[edited_blocks].any>:
        - playsound <[tile].center> sound:<[tile].center.material.block_sound_data.get[break_sound]> pitch:0.8
      - foreach <[edited_blocks]> as:b:
        - playeffect effect:BLOCK_CRACK at:<[b].center> offset:0 special_data:<[b].material> quantity:5 visibility:100
        - modifyblock <[b]> air
      - flag player build.edit_mode:!
      - playsound <player> sound:BLOCK_GRAVEL_BREAK pitch:1
      - stop

    # - Toggle Edit [ ON ]
    - define eye_loc      <player.eye_location>
    - define target_block <[eye_loc].ray_trace[return=block;range=4.5;default=air]>
    - if !<[target_block].has_flag[build.center]>:
      - stop

    #so players cant edit other player's builds
    - if <[target_block].flag[build.center].flag[build.placed_by]> != <player>:
      - stop

    - playsound <player> sound:BLOCK_GRAVEL_BREAK pitch:1.75

    - define tile_center     <[target_block].flag[build.center]>
    - define tile            <[tile_center].flag[build.structure]>
    - define build_type      <[tile_center].flag[build.type]>
    - define material        <[tile_center].flag[build.material]>
    - define connected_nodes <[tile_center].flag[build.nodes]>

    - definemap tile_data:
        tile: <[tile]>
        center: <[tile_center]>
        build_type: <[build_type]>
        material: <[material]>
        is_editing: True
        connected_nodes: <[connected_nodes]>

    #"reset" the tile while in edit mode to let players be able to click the blocks the wanna edit
    - run build_system_handler.place def:<[tile_data]>
    - flag player build.edit_mode.tile:<[tile]>
