#TODO: clean up this entire thing; it's pretty unorganized and ugly

##HOLD OFF ON PRE-BAKING UNTIL FURNTIRUE IS ADDED

##future for baking system: make sure you can place builds on it (and that they break)
#this is an attempt to significantly reduce lag by storing the data of the entire structure and its root data
#instead of looking for it in a while loop

#-is there a better way to bake these structures?

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


build_system_handler:
  type: world
  debug: false
  definitions: data
  events:
    #-editing
    #Q to enter/exit edit mode, Left-Click to edit, click again to remove edit, right-click to reset
    on player drops item flagged:build:
    - determine passively cancelled
    #to prevent build from placing, since it considers dropping as clicking a block
    - flag player build.dropped duration:1t
    - if <player.has_flag[build.edit_mode]>:
      #apply the edits
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

    - define eye_loc      <player.eye_location>
    - define target_block <[eye_loc].ray_trace[return=block;range=4.5;default=air]>
    - if !<[target_block].has_flag[build.center]>:
      - stop

    #so players cant edit other player's builds
    - if <[target_block].flag[build.center].flag[build.placed_by]> != <player>:
      - stop

    - playsound <player> sound:BLOCK_GRAVEL_BREAK pitch:1.75

    - define tile_center <[target_block].flag[build.center]>
    - define tile        <[tile_center].flag[build.structure]>
    - define build_type  <[tile_center].flag[build.type]>
    - define material    <[tile_center].flag[build.material]>

    - definemap tile_data:
        tile: <[tile]>
        center: <[tile_center]>
        build_type: <[build_type]>
        material: <[material]>
        is_editing: True
    #"reset" the tile while in edit mode to let players be able to click the blocks the wanna edit
    - run build_system_handler.place def:<[tile_data]>
    - flag player build.edit_mode.tile:<[tile]>

    on player clicks in inventory flagged:build:
    - determine cancelled

    #-material switch/remove edit
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
        - run build_system_handler.edit
        - stop

      - if !<player.has_flag[build.struct]>:
        - stop

      - define tile <player.flag[build.struct]>
      - define center <player.flag[build.center]>
      - define build_type <player.flag[build.type]>
      - define material <player.flag[build.material]>

        #automatically switch mats if you're out of the current material
      - if <player.flag[fort.<[material]>.qty]||0> < 10:
        - define other_mats <list[wood|brick|metal].exclude[<[material]>]>
        - foreach <[other_mats]> as:mat:
          - if <player.flag[fort.<[mat]>.qty]||0> > 10:
            - define switched True
            - flag player build.material:<[mat]>
            - define material <[mat]>
            - inject update_hud
            - foreach stop
        - stop if:<[switched].exists.not>

      - run fort_pic_handler.mat_count def:<map[qty=10;mat=<[material]>;action=remove]>

      #because walls and floors override stairs
      - define total_blocks <[tile].blocks>
      - define override_blocks <[total_blocks].filter[has_flag[build.center]].filter_tag[<list[pyramid|stair].contains[<[filter_value].flag[build.center].flag[build.type]>]>]>

      #checking if it doesn't have build.CENTER isntead of just "build" because for some reason some blocks have the "build" flag, even though they're info is removed?
      - define blocks <[total_blocks].filter[has_flag[build.center].not].include[<[override_blocks]>]>

      - definemap data:
          tile: <[tile]>
          center: <[center]>
          build_type: <[build_type]>
          material: <[material]>

      - run build_system_handler.place def:<[data]>

      - define health <script[nimnite_config].data_key[materials.<[material]>.hp]>

      - flag <[center]> build.structure:<[tile]>
      - flag <[center]> build.type:<[build_type]>
      - flag <[center]> build.health:<[health]>
      - flag <[center]> build.material:<[material]>
      - flag <[center]> build.placed_by:<player>

      - flag <[blocks]> build.center:<[center]>


      - define yaw <map[North=0;South=180;West=-90;East=90].get[<player.location.yaw.simple>]>

      #place fx
      - playsound <[center]> sound:<[center].material.block_sound_data.get[place_sound]> pitch:0.8
      #no need to filter materials for non-air, since block crack for air is nothing
      - foreach <[blocks]> as:b:
        - if <[build_type]> == wall:
          - define effect_loc <[b].center.with_yaw[<[yaw]>].forward_flat[0.5]>
        - else:
          - define effect_loc <[b].center.above>
        - playeffect effect:BLOCK_CRACK at:<[effect_loc]> offset:0 special_data:<[b].material> quantity:5 visibility:100

  edit:

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
    - define max_health <script[nimnite_config].data_key[materials.<[mat_type]>.hp]>
    - define new_health <[hp].sub[<[structure_damage]>]>
    - if <[new_health]> > 0:
      - flag <[center]> build.health:<[new_health]>
      - define progress <element[10].sub[<[new_health].div[<[max_health]>].mul[10]>]>
      - foreach <[blocks]> as:b:
        - blockcrack <[b]> progress:<[progress]> players:<server.online_players>
      - stop

    #otherwise, break the tile and anything else connected to it
    - foreach <[blocks]> as:b:
      - blockcrack <[b]> progress:0 players:<server.online_players>
      - playeffect effect:BLOCK_CRACK at:<[b].center> offset:0 special_data:<[b].material> quantity:10 visibility:100
    - inject build_system_handler.break

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

    - define remove_blocks <[tile].blocks.filter[has_flag[build_existed].not]>

    - if <[center].flag[build.placed_by]> == WORLD && <[type]> != FLOOR:
      #this way, there's no little holes on the ground after breaking walls that are on the floor
      #- if <[type]> == floor:
      #  - define keep_blocks <[remove_blocks].filter[below.material.name.equals[air].not].filter[flag[build.center].equals[<[center]>].not.if_null[true]]>
      #- else:
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

    #order: first placed -> last placed
    - define priority_order <list[wall|floor|stair|pyramid]>
    - foreach <[replace_tiles_data].parse_tag[<[parse_value]>/<[priority_order].find[<[parse_value].get[build_type]>]>].sort_by_number[after[/]].parse[before[/]]> as:tile_data:
      - run build_system_handler.place def:<[tile_data]>

    - run build_system_handler.remove_tiles def:<map[tile=<[tile]>;center=<[center]>]>

  remove_tiles:

    - define broken_tile        <[data].get[tile]>
    - define broken_tile_center <[data].get[center]>

    # - [ *Baked* Tile Removal ] - #
    ##- if <[broken_tile_center].has_flag[build.baked]>:
    ##  - narrate yes
      #should we bake the centers too?
    ##  - define structure <[broken_tile_center].flag[build.baked.structure]>
      #structure is a list of TILES
    ##  - define roots     <[broken_tile_center].flag[build.baked.roots]>
      #roots are TILES

    ##  - if <[roots].contains[<[broken_tile]>]>:
    ##    - define roots:<-:<[broken_tile]>

    ##  - if <[roots].any>:
    ##    - foreach <[structure].parse[center.flag[build.center]]> as:center:
    ##      - flag <[center]> build.baked.roots:<[roots]>
    ##    - stop

    ##  ##check if there are any roots nearby (placed by players)
    ##  - narrate BREAKING_WHOLE_STRUCTURE
    ##  - foreach <[structure]> as:tile:
    ##    - wait 3t
    ##    - define blocks <[tile].blocks.filter[flag[build.center].equals[<[tile].center.flag[build.center]||null>]]>
    ##    - define sound <[tile].center.material.block_sound_data.get[break_sound]>
    ##    - foreach <[tile].blocks> as:b:
    ##      - playeffect effect:BLOCK_CRACK at:<[b].center> offset:0 special_data:<[b].material> quantity:10 visibility:100
    ##    - ~modifyblock <[tile].blocks> air
    ##    - playsound <[tile].center> sound:<[sound]> pitch:0.8
    ##    - flag <[blocks]> build:!

    ##  - stop

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


            - define center <[tile].center.flag[build.center]>

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
    - define nearby_tiles <[center].find_blocks_flagged[build.center].within[5].parse[flag[build.center].flag[build.structure]].deduplicate.exclude[<[tile]>]>
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
    - define tile <[data].get[tile]>
    - define center <[data].get[center]>
    - define build_type <[data].get[build_type]>

    - define is_editing <[data].get[is_editing]||false>

    - define base_material <map[wood=oak;brick=brick;metal=cobblestone].get[<[data].get[material]>]>

    - choose <[build_type]>:

      - case stair:
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
        - define material <[base_material]>_stairs[direction=<[direction]>]
        - modifyblock <[set_blocks]> <[material]>

        #if they're stairs and they are going in the same direction, to keep the stairs "smooth", forget about adding connectors to them
        - define consecutive_stair_blocks <[set_connector_blocks].filter[flag[build.center].flag[build.type].equals[stair]].filter[material.direction.equals[<[direction]>]]>
        - define set_blocks               <[set_connector_blocks].exclude[<[consecutive_stair_blocks]>].exclude[<[override_blocks]>].filter[has_flag[build.edited].not]>
        - define set_blocks               <[set_blocks].filter[has_flag[build.edited].not]> if:!<[is_editing]>
        - define existing_blocks <proc[get_existing_blocks].context[<list_single[<[set_blocks]>]>]>
        - flag <[existing_blocks]> build_existed

        - define set_blocks      <[set_blocks].exclude[<[existing_blocks]>]>

        - modifyblock <[set_blocks]> <map[oak=oak_planks;brick=bricks;cobblestone=cobblestone].get[<[base_material]>]>

      - case pyramid:
        - run place_pyramid def:<[center]>|<[base_material]>|<[is_editing]>

      #floors/walls
      - default:
        #mostly for the stair overriding stuff with walls and floors
        - define total_blocks <[tile].blocks>

        - define exclude_blocks <list[]>

        - define nearby_tiles <[center].find_blocks_flagged[build.center].within[5].parse[flag[build.center].flag[build.structure]].deduplicate.exclude[<[tile]>]>
        - define connected_tiles <[nearby_tiles].filter[intersects[<[tile]>]]>
        - define stair_tiles <[connected_tiles].filter[center.flag[build.center].flag[build.type].equals[stair]]>

        - if <[stair_tiles].any>:
          - define stair_tile_center <[stair_tiles].first.center.flag[build.center]>

          - define top_middle <[stair_tile_center].forward_flat[2].above[2]>
          - define top_points <list[<[top_middle].left>|<[top_middle]>|<[top_middle].right>]>
          - define bot_middle <[stair_tile_center].backward_flat[2].below[2]>
          - define bot_points <list[<[bot_middle].left>|<[bot_middle]>|<[bot_middle].right>]>

          #with_pose part removes yaw/pitch data so we can exclude it from total blocks
          - define exclude_blocks <[top_points].include[<[bot_points]>].parse[with_pose[0,0]]>

        - define set_blocks <[total_blocks].exclude[<[exclude_blocks]>].deduplicate>
        - define set_blocks <[set_blocks].filter[has_flag[build.edited].not]> if:!<[is_editing]>
        - define existing_blocks <proc[get_existing_blocks].context[<list_single[<[set_blocks]>]>]>
        - flag <[existing_blocks]> build_existed

        - define set_blocks      <[set_blocks].exclude[<[existing_blocks]>]>

        - modifyblock <[set_blocks]> <map[oak=oak_planks;brick=bricks;cobblestone=cobblestone].get[<[base_material]>]>

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
    - define block <map[oak=oak_planks;brick=bricks;cobblestone=cobblestone].get[<[base_material]>]>

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

round4:
  type: procedure
  definitions: i
  debug: false
  script:
    - determine <element[<element[<[i]>].div[4]>].round.mul[4]>


build_toggle:
  type: task
  debug: false
  script:
    - if <player.has_flag[build]>:
      - inventory clear
      - inventory set o:<player.flag[build.last_inventory]> d:<player.inventory>
      #it means these "edits" weren't saved
      - if <player.has_flag[build.edit_mode.blocks]>:
        - flag <player.flag[build.edit_mode.blocks]> build.edited:!
      - adjust <player> item_slot:<player.flag[build.last_slot]>
      - flag player build:!
      - stop

    - define world <player.world.name>
    - define origin <location[0,0,0,<[world]>]>

    - flag player build.material:wood
    - flag player build.last_inventory:<player.inventory.list_contents>
    - flag player build.last_slot:<player.held_item_slot>

    - adjust <player> item_slot:1
    - inventory clear

    #text color
    - define tc <color[71,0,0]>
    #bracket color
    - define bc <color[72,0,0]>
    #left click color
    - define lc <color[73,0,0]>
    #right click color
    - define rc <color[74,0,0]>
    #drop color
    - define dt <color[75,0,0]>

    - define lb <element[<&l><&lb>].color[<[bc]>]>
    - define rb <element[<&l><&rb>].color[<[bc]>]>

    - define l_button     <[lb]><element[<&l>L].color[<[lc]>]><[rb]>
    - define r_button     <[lb]><element[<&l>R].color[<[rc]>]><[rb]>
    - define drop_key     <&keybind[key.drop].font[build_text]>
    - define drop_button  <[lb]><element[<&l><[drop_key]>].color[<[dt]>]><[rb]>

    - define build_txt   "<[l_button]> <element[<&l>BUILD].color[<[tc]>]>"
    - define mat_txt     "<[r_button]> <element[<&l>MATERIAL].color[<[tc]>]>"
    - define edit_txt    "<[drop_button]> <element[<&l>EDIT].color[<[tc]>]>"
    - define confirm_txt "<[drop_button]> <element[<&l>CONFIRM].color[<[tc]>]>"
    - define reset_txt   "<[r_button]> <element[<&l>RESET].color[<[tc]>]>"

    - while <player.is_online> && <player.has_flag[build]> && <player.is_spawned>:
      - define eye_loc <player.eye_location>
      - define loc <player.location>
      - define type <map[1=wall;2=floor;3=stair;4=pyramid].get[<player.held_item_slot>]||null>
      - define material <player.flag[build.material]>

      #sometimes the pencil isn't in the right slot when too fast
      - define slot <player.held_item_slot>
      - if <[slot]> == 5:
        - equip offhand:air hand:air
      - else:
        - inventory clear
        - equip offhand:<item[paper].with[custom_model_data=<[slot].add[3]>]>
        #slot hand changes, so give it to the next slot
        - give <item[gold_nugget].with[display=<&sp>;custom_model_data=10]> slot:<[slot]>

      - if <player.has_flag[build.edit_mode]>:
        - define tile             <player.flag[build.edit_mode.tile]>
        - define tile_center      <[tile].center.flag[build.center]>
        - define tile_blocks      <[tile].blocks.filter[flag[build.center].equals[<[tile_center]>]].filter[material.name.equals[air].not]>
        - define edited_blocks    <[tile_blocks].filter[has_flag[build.edited]]>
        - define nonedited_blocks <[tile_blocks].exclude[<[edited_blocks]>]>

        - define text "<[confirm_txt]> <[reset_txt]>"

        - debugblock <[edited_blocks]>    d:2t color:0,0,0,150
        - debugblock <[nonedited_blocks]> d:2t color:45,167,237,150

      - else if <[type]> != null:

        - if <player.eye_location.ray_trace[return=block;range=4.5;default=air].has_flag[build.center]>:
          - define text "<[edit_txt]> <[mat_txt]>"
        - else:
          - define text "<[build_txt]> <[mat_txt]>"

        - flag player build.type:<[type]>
        - inject build_tiles.<[type]>

        # keeping this here, just in case, but we might not need it and can let players break the terrain with the builds, since it gives more freedom
        # AND the world regenerates each match anyways

        #checks if:
        # 1) there's something unbreakable there
        # 2) if there's already a build there (and if that build is NOT a pyramid or a stair (since those can be "overwritten"))
        #if none pass, it's buildable
        - define can_build True
        #- define unbreakable_blocks <[display_blocks].filter[material.name.equals[air].not].filter[has_flag[build].not]>
        #this way, grass and shit is overwritten because screw that

        #- if <[unbreakable_blocks].filter[material.vanilla_tags.contains[replaceable_plants].not].any> || <[final_center].has_flag[build.center]>:
          #make sure you can place walls around stairs and pyramids (in that order)
          #made it so you cant place stairs on stairs and pyramids on pyramids
          #- if !<[final_center].has_flag[build.center]> || !<list[pyramid|stair].contains[<[final_center].flag[build.center].flag[build.type]>]> || <list[pyramid|stair].contains[<[type]>]>:
            #- define can_build False

        #-so you can't place tiles over other tiles
        #checks are so:
          #you can place walls around stairs and pyramids (in that order)
        - if <[final_center].has_flag[build.center]> && !<list[pyramid|stair].contains[<[final_center].flag[build.center].flag[build.type]>]>:
          - define can_build False

        #you cant place stairs on stairs and pyramids on pyramids
        - if <[final_center].has_flag[build.center]> && <list[pyramid|stair].contains[<[final_center].flag[build.center].flag[build.type]>]> && <list[pyramid|stair].contains[<[type]>]>:
          - define can_build False

        #-so you can't place a floor down on the ground if it's being fully covered
        - if <[type]> == FLOOR && <[final_center].material.name> != AIR:
          - define can_build False

        #-you can't place builds on natural structures
        - if <[tile].blocks.filter[has_flag[build.center]].filter[flag[build.center].has_flag[build.natural]].any>:
          - define can_build False

        #-so you can't place builds too far away
        - define too_far False
        - if <[final_center].distance[<player.eye_location>]> > 5:
          - define can_build False
          - define too_far True

        - define build_color 45,167,237,150
        - if <player.flag[fort.<[material]>.qty]||0> < 10:
          - define build_color 219,55,55,150

        #show debug blocks to spectating players too?
        - if <[can_build]>:
          #-set flags
          - flag player build.struct:<[tile]>
          - flag player build.center:<[final_center]>
          - debugblock <[display_blocks]> d:2t color:<[build_color]>
        - else:
          - flag player build.struct:!
          - debugblock <[display_blocks]> d:2t color:219,55,55,150 if:!<[too_far]>

      - actionbar <[text]>

      - wait 1t

    - actionbar <&sp>
    - flag player build:!

#test:
  #type: task
  #debug: false
  #script:
    #- spawn ITEM_DISPLAY[item=stone] <player.location.above[2]> save:e
    #- define e <entry[e].spawned_entity>
    #- adjust <[e]> display_entity_data:<map[transformation_scale=<location[0,1,0]>]>
