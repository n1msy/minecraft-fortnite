####
####
####
#TODO
# - add a new flag tracking how much mats the player has
# - decrease/incrase that number based on how what happens
# - make a 5x5 pallette creator for builders

fort_pic:
  type: item
  material: netherite_pickaxe
  display name: Pickaxe
  enchantments:
  - efficiency:5
  mechanisms:
    hides: ALL

fort_pic_handler:
  type: world
  debug: false
  definitions: data
  events:

    #each swing is 50 hp, each crit is 100
    on player breaks block with:fort_pic:
    #- stop if:<player.world.name.equals[fortnite_map].not>
    - determine passively cancelled
    - stop if:<player.item_in_hand.script.name.equals[fort_pic].not||true>

    - define block <context.location>

    - if !<[block].has_flag[build.center]>:
      #because trees and boulders dont have a specific "build type"
      - if <[block].material.name.contains_text[wood]> || <[block].material.name.contains_text[fence]>:
        - inject fort_pic_handler.tree
      - stop

    - define center   <[block].flag[build.center]>
    - define hp       <[center].flag[build.health]>
    - define mat_type <[center].flag[build.material]>
    #filtering so connected blocks aren't affected
    - define blocks   <[center].flag[build.structure].blocks.filter[flag[build.center].equals[<[center]>]]>

    - define damage 50

    - define max_health <script[nimnite_config].data_key[materials.<[mat_type]>.hp]>
    - define new_health <[hp].sub[<[damage]>]>

    - if <[new_health]> > 0:
      - flag <[center]> build.health:<[new_health]>

      - run fort_pic_handler.display_build_health def:<map[loc=<[center]>;health=<[new_health]>;max_health=<[max_health]>]>

      - define progress <element[10].sub[<[new_health].div[<[max_health]>].mul[10]>]>
      - foreach <[blocks]> as:b:
        - blockcrack <[b]> progress:<[progress]> players:<server.online_players>

      - stop

    - flag player fort.build_health:!

    #reset blockcrack in case a player places a wall in the same spot again
    - foreach <[blocks]> as:b:
      - blockcrack <[b]> progress:0 players:<server.online_players>
      - playeffect effect:BLOCK_CRACK at:<[b].center> offset:0 special_data:<[b].material> quantity:10 visibility:100

    #otherwise, break the tile and anything else connected to it
    - inject build_system_handler.break

    #switch between axe and pic
    #i *could* just remove the block when you click it, but the immersion would be ruined since you can't hold left click while farming
    on player clicks block type:!air with:fort_pic:

    - define i <context.item>

    - define block <context.location>
    - define mat <[block].material.name>

    - if <[mat].contains_any_text[oak|spruce|birch|jungle|acacia|dark_oak|mangrove|warped|barrel]>:
      - define tool netherite_axe
    - else:
      - define tool netherite_pickaxe

    - if <[i].material.name> != <[tool]>:
      - inventory adjust slot:<player.held_item_slot> material:<[tool]>

    on player right clicks block with:fort_pic:
    #so they can't strip logs
    - stop if:<context.location.material.name.contains_text[wood].not>
    - determine cancelled

    #infinite durability
    on fort_pic takes damage:
    - determine cancelled
    on player drops fort_pic:
    - determine cancelled
    on player clicks fort_pic in inventory:
    - determine cancelled

  tree:

    - define damage 50

    #-tree
    - run fort_pic_handler.harvest def:<map[structure=tree;type=wood]>

    - define tree        <[block].flood_fill[50].types[*wood|*slab|*fence*]>
    #excluding in case there are any of the same fences
    - define leaves      <[tree].last.find_blocks[*leaves|*fence*].within[17].exclude[<[tree]>]>
    - define tree_blocks <[tree].include[<[leaves]>]>

    - define max_health <script[nimnite_config].data_key[structures.tree.hp]>

    - if !<[block].has_flag[build.health]>:
      - define new_health <[max_health].sub[<[damage]>]>
    - else:
      - define new_health <[block].flag[build.health].sub[<[damage]>]>

    - if <[new_health]> > 0:
      - flag <[tree_blocks]> build.health:<[new_health]>

      - run fort_pic_handler.display_build_health def:<map[loc=<[block]>;health=<[new_health]>;max_health=<[max_health]>]>

      - define progress <element[10].sub[<[new_health].div[<[max_health]>].mul[10]>]>
      - foreach <[tree_blocks]> as:b:
        - blockcrack <[b]> progress:<[progress]> players:<server.online_players>

      - stop

    - flag player fort.build_health:!
    - flag <[tree_blocks]> build:!

    - define tree_mat <[tree].first.material>
    - foreach <[tree].sub_lists[5]> as:blocks:
      - modifyblock <[blocks]> air
      - playsound <[blocks].first> sound:BLOCK_WOOD_BREAK pitch:0.8
      - playeffect effect:BLOCK_CRACK at:<[blocks].parse[center]> offset:0 special_data:<[tree_mat]> quantity:10 visibility:100
      - wait 2t

    - if <[leaves].any>:
      - define leaf_mat <[leaves].first.material>
      - modifyblock <[leaves]> air
      - playsound <[leaves].first> sound:BLOCK_GRASS_BREAK pitch:0.8
      - playeffect effect:BLOCK_CRACK at:<[leaves].parse[center]> offset:0 special_data:<[leaf_mat]> quantity:2 visibility:100

  harvest:
  - define struct <[data].get[structure]>
  - define type <[data].get[type]>
  - define mult <script[nimnite_config].data_key[harvesting_multiplier]>

  - define qty <util.random.int[5].to[6].mul[<[mult]>]>
  - define total_qty <[qty]>
  - define loc <player.eye_location.forward[0.75].left[0.5].below[0.1]>

  #-waiting for text displays to unbork with fonts...
  # define icon <&chr[A<map[wood=111;brick=222;metal=333].get[<[type]>]>].font[icons]>
  - define icon "<&lb><[type]> icon<&rb>"

  - if <player.has_flag[fort.harvest_display]> && <player.flag[fort.harvest_display].is_spawned>:

    - define old_harvest_display <player.flag[fort.harvest_display]>
    - define total_qty           <[qty].add[<[old_harvest_display].flag[qty]>]>
    #- define loc                 <[old_harvest_display].location>

    - remove <[old_harvest_display]>


  - define text      "<[icon]> <&f><&l>+<[total_qty]>"

  ##add bouncy effect
  - definemap display_entity_data:
      text: <[text]>
      billboard: center
      text_is_shadowed: true
      transformation_scale: 0.3,0.3,0.3
      transformation_left_rotation: 0|0|0|1
      transformation_right_rotation: 0|0|0|1
      transformation_translation: 0,0,0
      brightness_block: 15
      brightness_sky: 15
  - spawn <entity[text_display].with[display_entity_data=<[display_entity_data]>]> <[loc]> save:harvest_display
  - define harvest_display <entry[harvest_display].spawned_entity>

  - definemap display_entity_data <[display_entity_data].with[transformation_scale].as[1,1,1].with[interpolation_duration].as[3]>
  - adjust <[harvest_display]> display_entity_data:<[display_entity_data]>

  - flag <[harvest_display]> qty:<[total_qty]>

  - adjust <[harvest_display]> hide_from_players
  - adjust <player> show_entity:<[harvest_display]>

  #no expiration, it's fine
  - flag player fort.harvest_display:<[harvest_display]>

  - wait 1.5s

  - if !<player.has_flag[harvest_display]> || <player.flag[harvest_display].location> != <[harvest_display].location>:
    #in case it was already removed by top code
    - if <[harvest_display].is_spawned>:
      ##bounce animation, then go up
      - repeat 20:
        - teleport <[harvest_display]> <[harvest_display].location.above[0.015]>
        # adjust <[harvest_display]> display_entity_data:<map[transformation_translation=0,1,0]>
        - wait 1t
      #-play scroll up animation
      - remove <[harvest_display]>

  display_build_health:
    - define yaw <map[North=0;South=180;West=-90;East=90].get[<player.location.yaw.simple>]>

    - define loc     <[data].get[loc].center.below[0.1].with_yaw[<[yaw]>].forward_flat>
    - define hp      <[data].get[health]>
    - define max_hp  <[data].get[max_health]>

    #null fallback in case it's a wood structure
    - if <[data].get[loc].flag[build.center].flag[build.type]||null> == floor:
      - define loc <[loc].above>

    - if <player.has_flag[fort.build_health]> && <player.flag[fort.build_health].location> == <[loc]>:
      - define health_display <player.flag[fort.build_health]>
    - else:
      - spawn <entity[text_display].with[display_entity_data=<map[billboard=center]>]> <[loc]> save:health_display
      - define health_display <entry[health_display].spawned_entity>
      - adjust <[health_display]> hide_from_players
      - adjust <player> show_entity:<[health_display]>

    - flag player fort.build_health:<[health_display]> duration:3s

    ##make sure to remove the backdrop of the health bar after spigot aint so borked anymore
    #-once custom fonts start working on text displays, replace this health bar system with the shader version
    #- define neg <proc[spacing].context[-1]>
    #- define health_text <&a><element[▋].repeat[<[hp].div[15].round_down>]><&8><element[▋].repeat[<[max_hp].sub[<[hp]>].div[15].round_down>]><&r><[hp]>｜<[max_hp]>
    - define health_text "<&f><[hp]> <&7><&l>| <&f><[max_hp]>"
    - adjust <[health_display]> display_entity_data:<map[text=<[health_text]>]>

    - waituntil !<player.has_flag[fort.build_health]> || <player.flag[fort.build_health]> != <[health_display]> max:15s

    - if <[health_display].is_spawned>:
      - remove <[health_display]>


#based on the material inputted, it returns either wood, brick, or metal
get_material_type:
  type: procedure
  debug: false
  definitions: actual_material
  script:

    - foreach <list[wood|brick|metal]> as:type:
      - if <script[nimnite_config].data_key[materials.<[type]>.valid_materials].contains[<[actual_material]>]>:
        - define material_type <[type]>
        - foreach stop
    - define material_type null if:!<[material_type].exists>

    - determine <[material_type]>

#-circle spawn
#- spawn <entity[block_display].with[material=purpur_block;tracking_range=1000;glowing=true;display_entity_data=<map[view_range=500;transformation_scale=1000,1,1000]>]>

test:
  type: task
  script:
    - spawn test_ent save:ent
    - wait 1s
    - definemap display_entity_data:
        interpolation_delay: 1
        interpolation_duration: 0.5
        transformation_scale: 0.5,0.5,0.5
        transformation_left_rotation: 0|0|0|1
        transformation_right_rotation: 0|0|0|1
        transformation_translation: 0,0,0
    - adjust <entry[ent].spawned_entity> display_entity_data:<[display_entity_data]>

test_ent:
  type: entity
  debug: false
  entity_type: text_display
  mechanisms:
    display_entity_data:
      text: hi
      text_is_shadowed: true
      billboard: center
      transformation_scale: 0.3,0.3,0.3
      transformation_left_rotation: 0|0|0|1
      transformation_right_rotation: 0|0|0|1
      transformation_translation: 0,0,0
      brightness_block: 15
      brightness_sky: 15