## [ Part of: Build System ] ##
#separated between files to make it easier to read

# - [ Description: Testing new stuff / debugging build related stuff. ] - #

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