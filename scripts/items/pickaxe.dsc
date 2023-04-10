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

    on player picks up oak_log|bricks|iron_block:
    - if !<context.entity.has_flag[qty]>:
      - stop
    #- define name_entity <context.entity.flag[name_entity]||null>
    - define qty         <context.entity.flag[qty]>
    - define mat         <map[oak_log=wood;bricks=brick;iron_block=metal].get[<context.item.material.name>]>

    - if <player.flag[fort.<[mat]>.qty]||0> >= 999:
      - determine passively cancelled
      - stop

    #fallback in case they picked the drop before the name entity spawned
    #- if <[name_entity]> != null:
      #- remove <[name_entity]>
    - run fort_pic_handler.mat_count def:<map[qty=<[qty]>;mat=<[mat]>;action=add]>

    on oak_log|bricks|iron_block merges:
    - define e <context.entity>
    - if !<[e].has_flag[qty]>:
      - stop
    - define target <context.target>
    - define mat       <map[oak_log=wood;bricks=brick;iron_block=metal].get[<context.item.material.name>]>
    - define other_mat <map[oak_log=wood;bricks=brick;iron_block=metal].get[<[target].item.material.name>]>

    - if <[mat]> != <[other_mat]>:
      - determine passively cancelled
      - stop

    - define qty       <[e].flag[qty]>
    - define other_qty <[target].flag[qty]>
    - define new_qty   <[qty].add[<[other_qty]>]>

    - define icon <&chr[A<map[wood=111;brick=222;metal=333].get[<[mat]>]>].font[icons]>
    - define text <[icon]><&f><&l>x<[new_qty]>

    - flag <[target]> qty:<[new_qty]>
    - adjust <[target]> custom_name:<[text]>

  drop_mat:
    - define qty  <[data].get[qty]>
    - define mat  <[data].get[mat]>
    - define loc  <player.eye_location.forward[1.5].sub[0,0.5,0]>

    - define item <map[wood=oak_log;brick=bricks;metal=iron_block].get[<[mat]>]>

    - drop <[item]> <[loc]> delay:1s save:drop
    - define drop <entry[drop].dropped_entity>
    - flag <[drop]> qty:<[qty]>

    - define icon <&chr[A<map[wood=111;brick=222;metal=333].get[<[mat]>]>].font[icons]>

    - define text <[icon]><&f><&l>x<[qty]>
    - define loc <[drop].location>

    - adjust <[drop]> custom_name:<[text]>
    - adjust <[drop]> custom_name_visible:true

    #- waituntil !<[drop].is_spawned> || <[drop].is_on_ground> rate:5t
    #- if !<[drop].is_spawned>:
      #- stop

    #- spawn chicken[has_ai=false;gravity=false;collidable=false;invulnerable=true;silent=true] <[loc].backward_flat[0.5]> save:chicken
    #- define chicken <entry[chicken].spawned_entity>
    #- adjust <[chicken]> custom_name:<[text]>
    #- adjust <[chicken]> custom_name_visible:false

    #- spawn <entity[text_display].with[display_entity_data=<map[billboard=center;text=<[text]>]>]> <[loc]> save:count_display
    #- define count_display <entry[count_display].spawned_entity>

    #- flag <[count_display]> drop:<[drop]>
    #- flag <[drop]>    name_entity:<[count_display]>

  #-increase/decrease materials after mining/placing
  mat_count:
    - define qty    <[data].get[qty]>
    - define mat    <[data].get[mat]>
    - define action <[data].get[action]>

    - define current_qty <player.flag[fort.<[mat]>.qty]>

    - if <[action]> == add:
      - if <player.flag[fort.<[mat]>.qty].add[<[qty]>]> > 999:
        - define total    <[current_qty].add[<[qty]>]>
        - define real_qty <[qty]>
        - define qty      <[total].sub[<[total].sub[999]>].sub[<[current_qty]>]>
        - define left_over <[real_qty].sub[<[qty]>]>
        #any extras are dropped on the floor
        - if <[left_over]> > 0:
          - run fort_pic_handler.drop_mat def:<map[qty=<[left_over]>;mat=<[mat]>]>

      #first add the mat (so they can place it instantly)
      #(then "animate" the counter)
      - flag player fort.<[mat]>.qty:+:<[qty]>
      - repeat <[qty]>:
        - define override_qty.<[mat]>:<[current_qty].add[<[value]>]>
        - inject update_hud
        - wait 1t

    - else if <[action]> == remove:
      - flag player fort.<[mat]>.qty:-:<[qty]>
      - repeat <[qty]>:
        - define override_qty.<[mat]>:<[current_qty].sub[<[value]>]>
        - inject update_hud
        - wait 1t


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
  - define loc <player.eye_location.forward[2].left[1].below[2.5]>

  - run fort_pic_handler.mat_count def:<map[qty=<[qty]>;mat=wood;action=add]>

  #-waiting for text displays to unbork with fonts...
  - define icon <&chr[A<map[wood=111;brick=222;metal=333].get[<[type]>]>].font[icons]>

  - if <player.has_flag[fort.harvest_display]>:
    - define total_qty <[total_qty].add[<player.flag[fort.harvest_display].flag[qty]>]>
    - if <player.flag[fort.harvest_display].is_spawned> && <player.flag[fort.harvest_display].location> == <[loc]>:
      - define harvest_display <player.flag[fort.harvest_display]>

  - define neg  <proc[spacing].context[-50]>
  - define text <[neg]><[icon]><&f><&l>+<[total_qty]><[neg]>

  - if !<[harvest_display].exists>:
    - spawn <entity[armor_stand].with[custom_name=<[text]>;custom_name_visible=true;gravity=false;collidable=false;invulnerable=true;visible=false]> <[loc]> save:harvest_display
    - define harvest_display <entry[harvest_display].spawned_entity>
    - adjust <[harvest_display]> hide_from_players
    - adjust <player> show_entity:<[harvest_display]>

  - flag <[harvest_display]> qty:<[total_qty]>
  - flag player fort.harvest_display:<[harvest_display]> duration:2s
  - adjust <[harvest_display]> custom_name:<[text]>

  - waituntil !<player.has_flag[fort.harvest_display]> || <player.flag[fort.harvest_display]> != <[harvest_display]> max:15s

  #this way, waituntils wont stack
  - if <[harvest_display].is_spawned> && !<[harvest_display].has_flag[remove_animation]>:
    #this way, it only plays scroll animation after player stops farming
    - if !<player.has_flag[fort.harvest_display]>:
      - flag <[harvest_display]> remove_animation
      - repeat 20:
        - teleport <[harvest_display]> <[harvest_display].location.above[0.015]>
        - wait 1t
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

harvest_anim:
  type: task
  debug: false
  definitions: e|text
  script:
    - wait 3t
    - definemap display_entity_data:
        text: <[text]>
        interpolation_delay: 0.1
        interpolation_duration: 0.1
        transformation_scale: 1.25,1.25,1.25
        transformation_left_rotation: 0|0|0|1
        transformation_right_rotation: 0|0|0|1
        transformation_translation: 0,0,0
    - adjust <[e]> display_entity_data:<[display_entity_data]>
    - wait 4t
    - definemap display_entity_data:
        interpolation_delay: 0.1
        interpolation_duration: 0.1
        transformation_scale: 1,1,1
        transformation_left_rotation: 0|0|0|1
        transformation_right_rotation: 0|0|0|1
        transformation_translation: 0,0,0
    - adjust <[e]> display_entity_data:<[display_entity_data]>
    - wait 1s
    - definemap display_entity_data:
        interpolation_delay: 1
        interpolation_duration: 1
        transformation_scale: 1,1,1
        transformation_left_rotation: 0|0|0|1
        transformation_right_rotation: 0|0|0|1
        transformation_translation: 0,0.4,0
    - adjust <[e]> display_entity_data:<[display_entity_data]>
    - wait 1.5s
    - waituntil !<player.has_flag[fort.harvest_display]> || <player.flag[fort.harvest_display]> != <[e]> max:2s
    - if <[e].is_spawned>:
      - remove <[e]>


harvest_display:
  type: entity
  debug: false
  entity_type: text_display
  mechanisms:
    display_entity_data:
      text: hi
      text_is_shadowed: true
      text_is_see_through: false
      text_opacity: 0
      billboard: center
      transformation_scale: 1,1,1
      transformation_left_rotation: 0|0|0|1
      transformation_right_rotation: 0|0|0|1
      transformation_translation: 0,0,0
      #brightness_block: 15
      #brightness_sky: 15