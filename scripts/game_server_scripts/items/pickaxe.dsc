#TODO: make the break speed consistent across the three mats?

fort_pickaxe_default:
  type: item
  material: netherite_pickaxe
  display name: <&chr[1].font[item_name]><&f><&l><element[Pickaxe].font[item_name]>
  enchantments:
  - efficiency:3
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    rarity: common
    icon_chr: 1

fort_pic_handler:
  type: world
  debug: false
  definitions: data
  events:

    on player damages entity with:fort_pickaxe*:
    #do 20 damage consistenly
    - determine 2

    on player fort_pickaxe* takes damage:
    - determine cancelled

    # - [ Weak point / Crit ] - #
    on INTERACTION damaged:
    - stop if:<context.entity.has_flag[fort.weak_point].not>
    #-weak point check
    #two methods for weak point: method 1 make it directly *on* the block,
    #OR make it its own entity
    - define hitbox <context.entity>
    - define damage 100

    - flag player fort.weak_point.hits:++ duration:2s

    #-sfx
    #                         G   A    B    C    D   E    F#   G
    #what i found out by ear: 0.53|0.6|0.685|0.72|0.8|0.9|1.0|1.07
    #from the actual table:   0.529732|0.594604|0.667420|0.707107|0.793701|0.890899|1.0|1.059463
    - define # <player.flag[fort.weak_point.hits].mod[8]>
    - define # 8 if:<[#].equals[0]>
    - define pitch <list[0.529732|0.594604|0.667420|0.707107|0.793701|0.890899|1.0|1.059463].get[<[#]>]>
    #make amethyst sfx non randomized by going through the rp?
    # playsound <player> sound:BLOCK_AMETHYST_BLOCK_BREAK pitch:0 volume:0.25
    - playsound <player> sound:BLOCK_NOTE_BLOCK_PLING pitch:<[pitch]> volume:0.4

    - define center <[hitbox].flag[fort.weak_point.center]>
    #when this flag is cleared, the hitbox & display are removed and the player's fort.weak_point.hitbox flag is cleared too
    #(handled in fort_pic_handler.weak_point)
    #clearing it before running damage_tile so another crit can spawn
    - flag <[hitbox]> fort.weak_point:!
    - flag player     fort.weak_point.hitbox:!
    - run fort_pic_handler.damage_tile def:<map[center=<[center]>;damage=100]>


    #each swing is 50 hp, each crit is 100
    #on player breaks block with:fort_pickaxe*:
    #this way it also cancels any block breaking that isn't breakable
    on player breaks block:
    - determine passively cancelled
    - stop if:<player.item_in_hand.script.name.starts_with[fort_pickaxe].not||true>

    - define block <context.location>

    - if <[block].material.name> == WHEAT:
      - modifyblock <[block]> air
      - run fort_pic_handler.harvest def:<map[type=WOOD;qty=<util.random.int[1].to[3]>]>

    - if <[block].material.name> == RAIL:
      - modifyblock <[block]> air
      - run fort_pic_handler.harvest def:<map[type=METAL;qty=<util.random.int[1].to[4]>]>

   # - else if <[block].material.name> == WHEAT:
      #- modifyblock <[block]> air
      #- run fort_pic_handler.harvest def:<map[type=<[mat_type]>]>

    - if !<[block].has_flag[build.center]>:
      - stop

    #in case it was pasted from a different world (specifically for the pine trees, since i accidentally made em in a different world)
    - define center      <[block].flag[build.center].with_world[<[block].world>]>

    - run fort_pic_handler.damage_tile def:<map[center=<[center]>;damage=50]>

    #switch between axe and pic
    #i *could* just remove the block when you click it, but the immersion would be ruined since you can't hold left click while farming
    on player clicks block type:!air with:fort_pickaxe*:

    - define i <context.item>

    - define block <context.location>
    - define mat <[block].material.name>

    - if <[mat].contains_any_text[oak|spruce|birch|jungle|acacia|dark_oak|mangrove|warped|barrel]>:
      - define tool netherite_axe
    - else:
      - define tool netherite_pickaxe

    - if <[i].material.name> != <[tool]>:
      - inventory adjust slot:<player.held_item_slot> material:<[tool]>

    on player right clicks !air with:fort_pickaxe*:
    #so they can't strip logs
    - stop if:<context.location.material.name.contains_any_text[wood|trap].not||false>
    - stop if:<context.location.material.name.contains_text[door]||false>
    - determine cancelled
    - ratelimit <player> 1t

    #infinite durability
    on fort_pickaxe* takes damage:
    - determine cancelled
    on player drops fort_pickaxe*:
    - determine cancelled
    on player clicks fort_pickaxe* in inventory:
    - determine cancelled

    on player picks up oak_log|bricks|iron_block:
    - if !<context.entity.has_flag[qty]>:
      - stop
    - determine passively cancelled

    - define qty         <context.entity.flag[qty]>
    - define mat         <map[oak_log=wood;bricks=brick;iron_block=metal].get[<context.item.material.name>]>

    - if <player.flag[fort.<[mat]>.qty]||0> >= 999:
      - stop

    - adjust <player> fake_pickup:<context.entity>
    - remove <context.entity>

    - run fort_pic_handler.mat_count def:<map[qty=<[qty]>;mat=<[mat]>;action=add]>

    on oak_log|bricks|iron_block merges:
    - define e <context.entity>

    #then it hasn't spawned correctly/it's a natural block
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

  damage_tile:
    - define center      <[data].get[center]>
    - define damage      <[data].get[damage]>
    - define hp          <[center].flag[build.health]>
    - define mat_type    <[center].flag[build.material]>

    - define struct      <[center].flag[build.structure]>
    - define struct_type <[center].flag[build.type]>

    #filtering so connected blocks aren't affected
    - define blocks   <[struct].blocks.filter[flag[build.center].equals[<[center]>]]>
    #so you can see the entirety of the floor/wall break
    - if <list[wall|floor].contains[<[struct_type]>]>:
      - define blocks <[struct].blocks>

    #-harvest material
    #side note: thank fucking god i was smart enough to add a "placed by world" flag for man-made structures
    - if <[center].has_flag[build.natural]> || <[center].flag[build.placed_by]||null> == WORLD:
      - run fort_pic_handler.harvest def:<map[type=<[mat_type]>]>

    #create a proc for finding max health? (since used in like 3 different places)
    #i feel like there's a cleaner way for this in the config
    - if !<[center].has_flag[build.natural]>:
      - define max_health <script[nimnite_config].data_key[materials.<[mat_type]>.hp]>
    - else:
      # - for natural structures:
      - define struct_name <[center].flag[build.natural.name]>
      - define max_health   <script[nimnite_config].data_key[structures.<[struct_name]>.health]>

    - define new_health <[hp].sub[<[damage]>]>

    - if <[new_health]> > 0:
      - flag <[center]> build.health:<[new_health]>

      - run fort_pic_handler.display_build_health def:<map[tile_center=<[center]>;health=<[new_health]>;max_health=<[max_health]>]>

      - define progress <element[10].sub[<[new_health].div[<[max_health]>].mul[10]>]>
      - foreach <[blocks].filter[has_flag[build.existed].not]> as:b:
        - blockcrack <[b]> progress:<[progress]> players:<server.online_players>

      #weak points only appear if it takes more than two swings to break the structure
      #only show up if a previous one isn't existing
      #not sure if i like the "2 swings minimum" rule
      - if <[new_health]> > 50 && !<player.has_flag[fort.weak_point.hitbox]>:
        - run fort_pic_handler.weak_point def:<map[center=<[center]>]>

      - stop

    #-TILE BREAKS HERE

    - flag player fort.build_health:!

    #reset blockcrack in case a player places a wall in the same spot again
    - foreach <[blocks].filter[has_flag[build.existed].not]> as:b:
      - blockcrack <[b]> progress:0 players:<server.online_players>
      - playeffect effect:BLOCK_CRACK at:<[b].center> offset:0 special_data:<[b].material> quantity:10 visibility:100

    - if <[center].has_flag[build.natural]>:
      #sometimes the center isn't included
      - define blocks <[blocks].include[<[center]>]>
      - inject fort_pic_handler.break_natural_structure
      - stop

    #otherwise, break the tile and anything else connected to it
    - inject build_system_handler.break
  weak_point:
  - define center <[data].get[center]>
  - if <[data].contains[tree_blocks]>:
    - define blocks <[data].get[tree_blocks]>
  - else:
    - define blocks <[center].flag[build.structure].blocks.filter[flag[build.center].equals[<[center]>]].filter[material.name.equals[air].not]>

  - define p_loc <player.location>
  - define yaw   <map[North=0;South=180;West=-90;East=90].get[<[p_loc].yaw.simple>]>

  - define available_weak_points <[blocks].filter[center.with_yaw[<[yaw]>].forward[1].line_of_sight[<[p_loc]>]].filter[distance[<[p_loc]>].is[OR_LESS].than[5]]>
  - if <[available_weak_points].is_empty>:
    - stop
  - define weak_point_loc <[available_weak_points].random>
  - define loc             <[weak_point_loc].center.with_yaw[<[yaw]>].forward_flat[0.9].above[0.27]>

  #-play weak point ENTER animation
  #the spiny animation was simplified. in the original, the inner ring goes clock wise and outer goes counter

  - define text          <&chr[0009].font[icons]>
  - define pivot         center
  - define scale         <location[0.5,0.5,0.5]>
  - define translation   <location[0,-0.25,0]>
  - define text_shadowed true
  - define opacity       255
  - spawn <entity[text_display].with[text=<[text]>;background_color=transparent;pivot=<[pivot]>;scale=<[scale]>;text_shadowed=<[text_shadowed]>;opacity=<[opacity]>;translation=<[translation]>;opacity=<[opacity]>;hide_from_players=true]> <[loc]> save:e
  - spawn <entity[INTERACTION].with[hide_from_players=true;width=0.6;height=0.6]> <[loc].below[0.55]> save:hb
  - define e  <entry[e].spawned_entity>
  - define hb <entry[hb].spawned_entity>
  - adjust <player> show_entity:<[e]>
  - adjust <player> show_entity:<[hb]>
  - flag <[hb]> fort.weak_point.center:<[center]>
  - flag player fort.weak_point.hitbox:<[hb]>

  - wait 2t

  - adjust <[e]> interpolation_start:0
  - adjust <[e]> scale:<location[1,1,1]>
  - adjust <[e]> interpolation_duration:3t
  - adjust <[e]> opacity:255

  #eh, i dont think so actually
  #- run fort_pic_handler.weak_point_rotate def:<map[entity=<[e]>]>

  #i think optimally we should wait 2/3 ticks before the waituntil, in case the player somehow gets the weak point in less than 2 ticks but nah
  - waituntil !<[hb].has_flag[fort.weak_point]> max:2s

  #-play weak point EXIT animation
  #"break/pop" from hit
  #if it no longer has the flag, it means it was broken
  - if !<[hb].has_flag[fort.weak_point]>:
    - adjust <[e]> interpolation_start:0
    - adjust <[e]> scale:<location[5,5,5]>
    - adjust <[e]> interpolation_duration:3t
    #opacity no work?
    - adjust <[e]> opacity:0
  - else:
    #naturally exit (not hit)
    - adjust <[e]> interpolation_start:0
    - adjust <[e]> scale:<location[0,0,0]>
    - adjust <[e]> interpolation_duration:3t
    - adjust <[e]> opacity:255

  - flag player fort.weak_point.hitbox:!
  - remove <[hb]>
  - wait 3t
  - remove <[e]> if:<[e].is_spawned>

  weak_point_rotate:
  - define e <[data].get[entity]>
  - wait 3t
  - if <[e].is_spawned>:
    - adjust <[e]> interpolation_start:0
    - adjust <[e]> scale:<location[1,1,1]>
    - adjust <[e]> left_rotation:0,0,-1,0
    - adjust <[e]> interpolation_duration:2s


  drop_mat:
    - define qty  <[data].get[qty]>
    - define mat  <[data].get[mat]>
    - define loc  <[data].get[loc]||null>
    - define loc  <player.eye_location.forward[1.5].sub[0,0.5,0]> if:<[loc].equals[null]>

    - define item <map[wood=oak_log;brick=bricks;metal=iron_block].get[<[mat]>]>

    - drop <[item]> <[loc]> delay:1s save:drop
    - define drop <entry[drop].dropped_entity>
    - flag <[drop]> qty:<[qty]>

    - define icon <&chr[A<map[wood=111;brick=222;metal=333].get[<[mat]>]>].font[icons]>

    - define text <[icon]><&f><&l>x<[qty]>
    - define loc <[drop].location>

    - adjust <[drop]> custom_name:<[text]>
    - adjust <[drop]> custom_name_visible:true

    #make mats glow?
    - team name:ammo add:<[drop]> color:GRAY
    - adjust <[drop]> glowing:true

  #-increase/decrease materials after mining/placing
  mat_count:
    - define qty    <[data].get[qty]>
    - define mat    <[data].get[mat]>
    - define action <[data].get[action]>

    - define current_qty <player.flag[fort.<[mat]>.qty]>

    - define mat#     <list[wood|brick|metal].find[<[mat]>]>
    - define line     <map[wood=8;brick=7;metal=6].get[<[mat]>]>
    - define icon     <&chr[A00<[mat#]>].font[icons]>
    #selected icon in case they select it
    - define sel_icon <&chr[A0<[mat#]><[mat#]>].font[icons]>

    - if <[action]> == add:
      - if <player.flag[fort.<[mat]>.qty].add[<[qty]>]> > 999:
        - define total     <[current_qty].add[<[qty]>]>
        - define real_qty  <[qty]>
        - define qty       <[total].sub[<[total].sub[999]>].sub[<[current_qty]>]>
        - define left_over <[real_qty].sub[<[qty]>]>
        #any extras are dropped on the floor
        - if <[left_over]> > 0:
          - run fort_pic_handler.drop_mat def:<map[qty=<[left_over]>;mat=<[mat]>]>

      #first add the mat (so they can place it instantly)
      #(then "animate" the counter)
      - flag player fort.<[mat]>.qty:+:<[qty]>
      #doesn't work well
      #19,20,21
      #- define item      <map[wood=oak_log;brick=bricks;metal=iron_block].get[<[mat]>].as[item]>
      #- define item_slot <map[wood=19;brick=20;metal=21].get[<[mat]>]>
      #- inventory set o:<[item].with[quantity=<player.flag[fort.<[mat]>.qty]>]> slot:<[item_slot]>
      - repeat <[qty]>:

        - define mat_qty  <[current_qty].add[<[value]>]>
        - define mat_icon <[icon]>
        - if <player.flag[build.material]||null> == <[mat]>:
          - define mat_icon <[sel_icon]>

        - define mat_text <&sp.repeat[<element[3].sub[<[mat_qty].length>]>]><[mat_qty].font[hud_text]>
        - define mat_     <element[<[mat_icon]><proc[spacing].context[-32]><[mat_text]>].color[<color[4<[mat#]>,0,0]>]>
        - sidebar set_line scores:<[line]> values:<[mat_]>

        - wait 1t

    - else if <[action]> == remove:
      - flag player fort.<[mat]>.qty:-:<[qty]>
      - repeat <[qty]>:

        - define mat_qty  <[current_qty].sub[<[value]>]>
        - define mat_icon <[icon]>
        - if <player.flag[build.material]||null> == <[mat]>:
          - define mat_icon <[sel_icon]>

        - define mat_text <&sp.repeat[<element[3].sub[<[mat_qty].length>]>]><[mat_qty].font[hud_text]>
        - define mat_     <element[<[mat_icon]><proc[spacing].context[-32]><[mat_text]>].color[<color[4<[mat#]>,0,0]>]>
        - sidebar set_line scores:<[line]> values:<[mat_]>

        - wait 1t

  break_natural_structure:
    ##minor problem: sometimes parts of the leaves/tree stay because there was a mistake
    #-in the "tree removing" system, where the center loc's flags weren't reset.

    #sorting by y for trees so it goes
    - define blocks <[blocks].sort_by_number[y]>

    - flag player fort.build_health:!
    - flag <[blocks]> build:!

    - if <[struct_type]> != tree:
      - modifyblock <[blocks]> air
      - playsound <[blocks].first> sound:BLOCK_STONE_BREAK pitch:0.8
      - playeffect effect:BLOCK_CRACK at:<[blocks].parse[center]> offset:0 special_data:<[blocks].first.material> quantity:10 visibility:100

    #-tree animation
    - else:

      #in fort there's no "animation" like this, but i like it
      - define wood_blocks <[blocks].filter[material.block_sound_data.get[break_sound].contains_text[wood]]>
      - define leaves      <[blocks].exclude[<[wood_blocks]>]>
      - foreach <[wood_blocks].sub_lists[8]> as:sub_blocks:
        - modifyblock <[sub_blocks]> air
        - define sound <[sub_blocks].first.after_last[_].equals[leaves].if_true[BLOCK_GRASS_BREAK].if_false[BLOCK_WOOD_BREAK]>
        - playsound <[sub_blocks].first> sound:<[sound]> pitch:0.8
        - playeffect effect:BLOCK_CRACK at:<[sub_blocks].parse[center]> offset:0 special_data:<[sub_blocks].first.material> quantity:10 visibility:100
        - wait 2t

      - playsound <[center]> sound:BLOCK_GRASS_BREAK pitch:0.8 volume:1.2
      - foreach <[leaves]> as:leaf:
        - define leaf_mat <[leaf].material>
        - modifyblock <[leaf]> air
        - playeffect effect:BLOCK_CRACK at:<[leaf].center> offset:0 special_data:<[leaf_mat]> quantity:2 visibility:100

  harvest:
  - define type <[data].get[type]>
  #in case we want some custom qty too
  - define qty  <[data].get[qty]||null>
  - define mult <script[nimnite_config].data_key[harvesting_multiplier]>

  #idk what the quantity number should be
  - define qty <util.random.int[4].to[7].mul[<[mult]>]> if:<[qty].equals[null]>
  - define total_qty <[qty]>
  - define loc <player.eye_location.forward[2].left[1]>

  - run fort_pic_handler.mat_count def:<map[qty=<[qty]>;mat=<[type]>;action=add]>

  #-waiting for text displays to unbork with fonts...
  - define icon <&chr[A<map[wood=111;brick=222;metal=333].get[<[type]>]>].font[icons]>

  - if <player.has_flag[fort.harvest_display]>:
    - define total_qty <[total_qty].add[<player.flag[fort.harvest_display].flag[qty]>]>
    - if <player.flag[fort.harvest_display].is_spawned> && <player.flag[fort.harvest_display].location> == <[loc]>:
      - define harvest_display <player.flag[fort.harvest_display]>


  - define text <[icon]><&f><&l>+<[total_qty]>

  - if !<[harvest_display].exists>:
    - spawn <entity[text_display].with[text=<[text]>;pivot=center;scale=1,1,1;background_color=transparent]> <[loc]> save:harvest_display
    - define harvest_display <entry[harvest_display].spawned_entity>
    - adjust <[harvest_display]> hide_from_players
    - adjust <player> show_entity:<[harvest_display]>

  - flag <[harvest_display]> qty:<[total_qty]>
  - flag player fort.harvest_display:<[harvest_display]> duration:2s
  - adjust <[harvest_display]> text:<[text]>
  - run fort_pic_handler.bounce_anim def:<map[e=<[harvest_display]>]>

  #probably better way of doing this using whiles?
  - waituntil !<player.has_flag[fort.harvest_display]> || <player.flag[fort.harvest_display]> != <[harvest_display]> max:15s

  #this way, waituntils wont stack
  - if <[harvest_display].is_spawned> && !<[harvest_display].has_flag[remove_animation]>:
    #this way, it only plays scroll animation after player stops farming
    - if !<player.has_flag[fort.harvest_display]>:
      - flag <[harvest_display]> remove_animation
      - adjust <[harvest_display]> interpolation_start:0
      - adjust <[harvest_display]> translation:<location[0,0.3,0]>
      - adjust <[harvest_display]> opacity:0
      - adjust <[harvest_display]> interpolation_duration:1s
      - wait 1s
    - remove <[harvest_display]>

  bounce_anim:
  - define e <[data].get[e]>
  - define speed 2

  - wait 2t
  - adjust <[e]> interpolation_start:0
  - adjust <[e]> scale:<location[1.35,1.35,1.35]>
  - adjust <[e]> interpolation_duration:<[speed]>t

  - wait <[speed]>t

  - adjust <[e]> interpolation_start:0
  - adjust <[e]> scale:<location[1,1,1]>
  - adjust <[e]> interpolation_duration:<[speed]>t


  display_build_health:
    #- define yaw <map[North=0;South=180;West=-90;East=90].get[<player.location.yaw.simple>]>

    - define tile_center <[data].get[tile_center]>
    - define hp          <[data].get[health]>
    - define max_hp      <[data].get[max_health]>
    - define is_prop     <[data].get[is_prop]>

    #-find health bar loc
    - define loc <[tile_center]>
    - if !<[is_prop]>:
      - if !<[tile_center].has_flag[build.natural]>:
        #show the health at the center of the tile
        - define loc <[tile_center].flag[build.center].center.above[0.3]>
      - else:
        # - for natural structures:
        - define loc <[tile_center].with_y[<[tile_center].flag[build.structure].min.y.sub[1.5]>]>

    #-only show 1 health bar at a time?
    - if <player.has_flag[fort.build_health]> && <player.flag[fort.build_health].is_spawned> && <player.flag[fort.build_health].location> == <[loc]>:
      - define health_display <player.flag[fort.build_health]>
    - else:
      - spawn <entity[text_display].with[pivot=center;background_color=transparent;see_through=true;scale=0.7,0.7,0.7;translation=0,-0.35,0]> <[loc]> save:health_display
      - define health_display <entry[health_display].spawned_entity>
      #show it to all players, or just them?
      - adjust <[health_display]> hide_from_players
      - adjust <player> show_entity:<[health_display]>
    - flag player fort.build_health:<[health_display]> duration:5s

    #health goes from 0 to 255
    - define health_r <[hp].div[<[max_hp]>].mul[255].round_down>
    - define bar_icon    <&chr[C005].font[icons].color[<[health_r]>,2,50]>
    - define health_text "<[hp].format_number> <element[｜ <[max_hp].format_number>].color[209,255,196]>"
    - define health_text <[bar_icon]><proc[spacing].context[-163]><[health_text]><proc[spacing].context[126]>
    - adjust <[health_display]> text:<[health_text]>

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