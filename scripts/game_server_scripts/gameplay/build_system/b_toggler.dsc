## [ Part of: Build System ] ##
#separated between files to make it easier to read

# - [ Description: Enabling/Disabling build system. ] - #

build_toggle_handler:
  type: world
  debug: false
  events:

    on player swaps items:
    #- stop if:<player.world.name.equals[nimnite_map].not>
    - determine passively cancelled
    - if <player.has_flag[fort.using_glider]>:
      - stop

    - if <player.has_flag[fort.disable_build]>:
      - stop

    - if <player.has_flag[fort.on_bus]>:
      - stop

    - if <player.has_flag[fort.on_bus]>:
      - stop if:<player.has_flag[fort.on_bus.loading]>
      - if !<player.has_flag[fort.thanked_bus_driver]>:
        #teammates are orange? idc
        - announce "<&c><&l><player.name> <&7>thanked the bus driver"
        - flag player fort.thanked_bus_driver
      - stop

    - define new_type <map[inv=build;build=inv].get[<player.flag[fort.inv_type]||inv>]>
    - flag player fort.inv_type:<[new_type]>

    #stop the emote
    - flag player fort.emote:! if:<[new_type].equals[build]>
    - run build_toggle

    - inject update_hud

build_toggle:
  type: task
  debug: false
  definitions: slot|type|pencil
  script:
    # - [ Turn OFF builds ] - #
    - if <player.has_flag[build]>:
      - inventory clear
      - inventory set o:<player.flag[build.last_inventory]> d:<player.inventory>
      #it means these "edits" weren't saved
      - if <player.has_flag[build.edit_mode.blocks]>:
        - flag <player.flag[build.edit_mode.blocks]> build.edited:!
      - adjust <player> item_slot:<player.flag[build.last_slot]>
      - flag player build:!
      - stop

    # - [ Turn ON Builds ] - #
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

    - define tooltip_remover <list[<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|                                                                                                                                                                                                                                                                                                                                                                                                                           ]>
    - define pencil    <item[gold_nugget].with[display=<&sp>;custom_model_data=1;lore=<[tooltip_remover]>]>

    - while <player.is_online> && <player.has_flag[build]> && <player.is_spawned>:
      - define eye_loc <player.eye_location>
      - define loc <player.location>
      - define slot <player.held_item_slot>

      - define type <map[1=wall;2=floor;3=stair;4=pyramid].get[<[slot]>]||null>
      - define material <player.flag[build.material]>

      #running in separate queue for safety (so items aren't inaccurate)
      - run build_toggle.give_blueprint def.slot:<[slot]> def.type:<[type]> def.pencil:<[pencil]>

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
        - define block_looking_at <player.eye_location.ray_trace[return=block;range=4.5;default=air]>
        #world fall back since world structures dont have PLACED_BY
        - if <[block_looking_at].has_flag[build.center]> && <[block_looking_at].flag[build.center].flag[build.placed_by]||WORLD> == <player>:
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

  give_blueprint:
  #-do we want bob effect for pencil too?

    #adding a delay since if you scroll too fast, they are inaccurate
    - wait 1t
    #in case they disabled build
    - if !<player.has_flag[build]>:
      - stop

    #offhand slot = 41
    #null fallback is in case player is getting other slots by spamming
    - define cmd <map[wall=4;floor=5;stair=6;pyramid=7].get[<[type]>]||null>

    #traps
    - if <[slot]> == 5 || <[cmd]> == null:
      - equip offhand:air hand:air
      - stop

    - if <player.item_in_hand> == <item[air]>:
      - define inv_setup <list[<[pencil]>|<[pencil]>|<[pencil]>|<[pencil]>]>
      - define build_inv <inventory[generic[size=9;contents=<[inv_setup]>]]>
      - inventory set o:<[build_inv]>

    - define offhand <player.inventory.slot[41]>
    #check if there's already that blue print in their hands, otherwise, give it
    - if <[offhand]> == <item[air]> || <[offhand].custom_model_data||-1> != <[cmd]>:
      #run clear inv for pencil BOB effect
      #- inventory clear
      - equip offhand:<item[paper].with[custom_model_data=<[cmd]>]>
