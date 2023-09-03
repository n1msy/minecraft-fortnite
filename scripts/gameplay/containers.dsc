fort_chest:
  type: item
  material: gold_nugget
  display name: Chest
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    qty: 1

fort_ammo_box:
  type: item
  material: gold_nugget
  display name: Ammo Box
  mechanisms:
    custom_model_data: 17
    hides: ALL
  flags:
    qty: 1


fort_chest_handler:
  type: world
  debug: false
  definitions: data
  events:
    on player right clicks block with:fort_chest|fort_ammo_box:
    - determine passively cancelled
    - ratelimit <player> 1t
    - define loc <context.location.above.center.above[0.1]>
    - if <[loc].material.name> != air:
      - narrate "<&c>Invalid spot."
      - stop
    #-returns either "chest" or "ammo_box"
    - define container_type <context.item.script.name.after[fort_]>

    - define text "<&7><&l>[<&e><&l>Sneak<&7><&l>] <&f><&l>Search"
    - define yaw <player.eye_location.yaw>
    - define angle <[yaw].to_radians>
    - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>
    - define cmd           <map[chest=15;ammo_box=17].get[<[container_type]>]>
    - define scale         <map[chest=1.25;ammo_box=1].get[<[container_type]>]>
    - define model_loc     <map[chest=<[loc]>;ammo_box=<[loc].below[0.11]>].get[<[container_type]>]>
    - define text_loc      <map[chest=<[loc].above[0.75]>;ammo_box=<[loc].above[0.5]>].get[<[container_type]>]>
    - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=<[cmd]>]>;scale=<[scale]>,<[scale]>,<[scale]>;left_rotation=<[left_rotation]>] <[model_loc]> save:container
    - spawn TEXT_DISPLAY[text=<[text]>;pivot=center;scale=1,1,1;view_range=0.035;see_through=true] <[text_loc]> save:container_text

    - modifyblock <[loc]> barrier
    - define loc <context.location.above.center>

    - flag <[loc]> fort.<[container_type]>.model:<entry[container].spawned_entity>
    - flag <[loc]> fort.<[container_type]>.text:<entry[container_text].spawned_entity>
    - flag <[loc]> fort.<[container_type]>.yaw:<[yaw].add[180]>

    #so it's not using the fx constantly when not in use
    - flag <[loc]> fort.<[container_type]>.opened

    - if <[container_type]> == ammo_box:
      - flag server fort.ammo_boxes:->:<[loc]>
    - else:
      - flag server fort.chests:->:<[loc]>

    - narrate "<&a>Set <[container_type].replace[_].with[ ]> at <&f><[loc].simple>"


    on player breaks block location_flagged:fort.chest:
    - define loc <context.location.center>
    - remove <[loc].flag[fort.chest.model]> if:<[loc].flag[fort.chest.model].is_spawned>
    - remove <[loc].flag[fort.chest.text]> if:<[loc].flag[fort.chest.text].is_spawned>

    - narrate "<&c>Removed chest at <&f><[loc].simple>"

    - flag <[loc]> fort:!
    - flag server fort.chests:<-:<[loc]>

    on player breaks block location_flagged:fort.ammo_box:
    - define loc <context.location.center>
    - remove <[loc].flag[fort.ammo_box.model]> if:<[loc].flag[fort.ammo_box.model].is_spawned>
    - remove <[loc].flag[fort.ammo_box.text]> if:<[loc].flag[fort.ammo_box.text].is_spawned>

    - narrate "<&c>Removed ammo box at <&f><[loc].simple>"

    - flag <[loc]> fort:!
    - flag server fort.ammo_boxes:<-:<[loc]>

  open:
  #-handled in "guns.dsc" event "after player starts sneaking"
  #required definitions: look_loc, container_type

  - define loc <[look_loc]>
  - define text_display <[loc].flag[fort.<[container_type]>.text]>
  - define text         <[text_display].text>
  - define container    <[loc].flag[fort.<[container_type]>.model]>
  - adjust <[text_display]> see_through:false
  - while <player.is_online> && <player.is_sneaking> && <[loc].has_flag[fort.<[container_type]>]> && !<[loc].has_flag[fort.<[container_type]>.opened]> && <[text_display].is_spawned>:
    - define look_loc <player.eye_location.ray_trace[return=block;range=2.7;default=air]>
    - define bar <&chr[8].font[icons].color[<color[<[loop_index]>,0,1]>]>
    - adjust <[text_display]> text:<[text]><&r><proc[spacing].context[-92]><[bar]><proc[spacing].context[-1]>
    - if <[loop_index]> == 10:
      - define open_the_container True
      - while stop
    - wait 1t
  - adjust <[text_display]> see_through:true
  - adjust <[text_display]> text:<[text]>
  - stop if:<[open_the_container].exists.not>

  - flag <[loc]> fort.<[container_type]>.opened

  - remove <[text_display]> if:<[text_display].is_spawned>

  - adjust <[container]> item:<item[gold_nugget].with[custom_model_data=<map[chest=16;ammo_box=18].get[<[container_type]>]>]>

  - define drop_loc <[loc].with_yaw[<[loc].flag[fort.<[container_type]>.yaw]>].forward>

  - choose <[container_type]>:
    - case chest:
      - playsound <[container].location> sound:BLOCK_CHEST_OPEN volume:0.5 pitch:1
      - playsound <[container].location> sound:BLOCK_AMETHYST_CLUSTER_BREAK pitch:0.85 volume:2

      - define mat       <[loc].flag[fort.chest.loot.mat]>
      - define item      <[loc].flag[fort.chest.loot.item]>
      - define item_qty  <[item].flag[drop_quantity]>
      - define gun       <[loc].flag[fort.chest.loot.gun]>
      - define ammo_type <[gun].flag[ammo_type]>
      - define ammo_qty  <[gun].flag[mag_size]>
      - if <item[ammo_<[ammo_type]>].has_flag[drop_quantity]>:
        - define ammo_qty <item[ammo_<[ammo_type]>].flag[drop_quantity]>

      - run fort_pic_handler.drop_mat def:<map[mat=<[mat]>;qty=30;loc=<[drop_loc]>]>
      - run fort_item_handler.drop_item def:<map[item=<[item]>;qty=<[item_qty]>;loc=<[drop_loc]>]>
      - run fort_gun_handler.drop_gun def:<map[gun=<[gun]>;loc=<[drop_loc]>]>
      - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[ammo_qty]>;loc=<[drop_loc]>]>

    - case ammo_box:
      - playsound <[container].location> sound:BLOCK_CHEST_OPEN volume:0.1 pitch:1.3
      - playsound <[container].location> sound:ITEM_ARMOR_EQUIP_CHAIN volume:1.6 pitch:0.8

      - define ammo_type <[loc].flag[fort.ammo_box.loot.ammo_type]>
      - define ammo_qty  <map[light=18;medium=10;heavy=6;shells=4;rockets=2].get[<[ammo_type]>]>

      #i can kind of just take this ammo dropping line outside of the switch, but maybe not in case i wanted to add new containers that dont drop it
      - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[ammo_qty]>;loc=<[drop_loc]>]>

  chest_fx:
    - define loc        <[data].get[loc]>
    - define p_loc      <[loc].with_yaw[<[loc].flag[fort.chest.yaw]>].forward[0.4]>
    - define gold_shine <[p_loc].left[0.5].points_between[<[p_loc].right[0.55]>].distance[0.1]>
    - while !<[loc].has_flag[fort.chest.opened]> && <[loc].has_flag[fort.chest]>:
      - if <[loop_index].mod[5]> == 0:
        - playsound <[loc]> sound:BLOCK_AMETHYST_BLOCK_CHIME pitch:1.5 volume:0.5
      - playeffect at:<[gold_shine].random[15]> effect:DUST_COLOR_TRANSITION offset:0 quantity:1 special_data:1|<color[#ffc02e]>|<color[#fff703]>
      - wait 4t

  fill_chest:
    #- handled in "commands.dsc"

    #required definitions:
    # - <[loc]> - #

    #removing definitions since they're re-used for each chest
    - define item_to_drop:!
    - define gun_type:!
    - define gun_to_drop:!
    - define rarity:!

    ## - [ Item Drops ] - ##
    - define rarity_priority <map[common=1;uncommon=2;rare=3;epic=4;legendary=5]>
    # - [ Materials ] - #
    - define mat_to_drop <list[wood|brick|metal].random>

    # - [ Items ] - #
    #try to find out the same system as guns with the subtypes?
    - define items <util.scripts.filter[name.starts_with[fort_item_]].exclude[<script[fort_item_handler]>].parse[name.as[item]].parse_tag[<[parse_value]>/<[rarity_priority].get[<[parse_value].flag[rarity]>]>].sort_by_number[after[/]].parse[before[/]]>
    - while !<[item_to_drop].exists>:
      - foreach <[items]> as:i:
        - if <util.random_chance[<[i].flag[chance]>]>:
          - define item_to_drop <[i]>
          - foreach stop
      - wait 1t

    # - [ Guns ] - #
    #im not so sure about the chance for the common guns?
    #right now, they use the same values of as the category
    - define gun_categories <map[ar=43;shotgun=22;smg=14;pistol=11;sniper=10;rpg=5]>
    - while !<[gun_type].exists>:
      - define type <[gun_categories].keys.get[<[loop_index].mod[6].add[1]>]>
      - if <util.random_chance[<[gun_categories].get[<[type]>]>]>:
        - define gun_type <[type]>
        - while stop
      - wait 1t

    - define guns <util.scripts.filter[name.starts_with[gun_]].exclude[<script[gun_particle_origin]>].parse[name.as[item]].parse_tag[<[parse_value]>/<[rarity_priority].get[<[parse_value].flag[rarity]>]>].sort_by_number[after[/]].parse[before[/]].filter[flag[type].equals[<[gun_type]>]]>
    - foreach <[guns]> as:g:
      - define rarities <[g].flag[rarities].exclude[common]>
        #excluding, since common is the default if none other pass
      - foreach <[rarities].keys> as:r:
        - if <util.random_chance[<[g].flag[rarities.<[r]>.chance]>]>:
          - define rarity <[r]>
          - foreach stop
      - if <[rarity].exists>:
        - define gun_to_drop <[g].with[flag=rarity:<[rarity]>]>
        - foreach stop
    #default rarity is already the lowest
    - define gun_to_drop  <[guns].first> if:!<[gun_to_drop].exists>

    - flag <[loc]> fort.chest.loot.mat:<[mat_to_drop]>
    - flag <[loc]> fort.chest.loot.item:<[item_to_drop]>
    - flag <[loc]> fort.chest.loot.gun:<[gun_to_drop]>

    - if <[loc].has_flag[fort.chest.opened]>:
      - define text "<&7><&l>[<&e><&l>Sneak<&7><&l>] <&f><&l>Search"
      - if !<[loc].flag[fort.chest.model].is_spawned>:
        - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=15]>;scale=1.25,1.25,1.25;left_rotation=0,1,0,0] <[loc]> save:chest
        - flag <[loc]> fort.chest.model:<entry[chest].spawned_entity>
      - else:
        - adjust <[loc].flag[fort.chest.model]> item:<item[gold_nugget].with[custom_model_data=15]>
      - if !<[loc].flag[fort.chest.text].is_spawned>:
        - spawn TEXT_DISPLAY[text=<[text]>;pivot=center;scale=1,1,1;view_range=0.035;see_through=true] <[loc].above[0.75]> save:chest_text
        - flag <[loc]> fort.chest.text:<entry[chest_text].spawned_entity>
      - flag <[loc]> fort.chest.opened:!
      - run fort_chest_handler.chest_fx def:<map[loc=<[loc]>]>

  fill_ammo_box:
    #- handled in "commands.dsc"

    #required definitions:
    # - <[loc]> - #

    #removing definitions since they're re-used for each ammo box
    - define ammo_to_drop:!
    - define ammo_to_drop <list[light|medium|heavy|shells|rockets].random>

    - flag <[loc]> fort.ammo_box.loot.ammo_type:<[ammo_to_drop]>


    #this if runs only if the ammo box was already opened, otherwise there's no need for it to run
    - if <[loc].has_flag[fort.ammo_box.opened]>:
      - define text "<&7><&l>[<&e><&l>Sneak<&7><&l>] <&f><&l>Search"
      #in case the original model somehow despawned, otherwise just close it again (since its being filled)
      - if !<[loc].flag[fort.ammo_box.model].is_spawned>:
        - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=17]>;scale=1.25,1.25,1.25;left_rotation=0,1,0,0] <[loc]> save:ammo_box
        - flag <[loc]> fort.ammo_box.model:<entry[ammo_box].spawned_entity>
      - else:
        - adjust <[loc].flag[fort.ammo_box.model]> item:<item[gold_nugget].with[custom_model_data=17]>

      - if !<[loc].flag[fort.ammo_box.text].is_spawned>:
        - spawn TEXT_DISPLAY[text=<[text]>;pivot=center;scale=1,1,1;view_range=0.035;see_through=true] <[loc].above[0.75]> save:ammo_box_text
        - flag <[loc]> fort.ammo_box.text:<entry[ammo_box_text].spawned_entity>
      - flag <[loc]> fort.ammo_box.opened:!

  send_supply_drop:

    - define drop_loc <[data].get[loc].above[2.9]>

    - define size 2
    - define height 45

    - define start_loc <[drop_loc].above[<[height]>]>

    ## - [ SET SUPPLY DROP LOOT ] ##
    #only one random factor, the gun

    #75% chance for epic, 25 for legendary
    - if <util.random_chance[25]>:
      - define rarity legendary
    - else:
      - define rarity epic
    - define guns <util.scripts.filter[name.starts_with[gun_]].exclude[<script[gun_particle_origin]>].parse[name.as[item]]>
    - while !<[gun_to_drop].exists>:
      - foreach <[guns]> as:g:
        - if <util.random_chance[<[g].flag[rarities.<[rarity]>.chance]>]>:
          - define gun_to_drop <[g].with[flag=rarity:<[rarity]>]>
          - foreach stop

    - spawn INTERACTION[height=6;width=2.5] <[start_loc].below[3]> save:hitbox
    - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=20]>;scale=<[size]>,<[size]>,<[size]>] <[start_loc]> save:supply_drop
    - define hb <entry[hitbox].spawned_entity>
    - define sp <entry[supply_drop].spawned_entity>

    - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=21]>;scale=3.25,3.25,3.25] <[drop_loc].below[1.25]> save:circle
    - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=22]>;scale=2.25,2.25,2.25] <[drop_loc].below[1.76]> save:arrows
    - define circle <entry[circle].spawned_entity>
    - define arrows <entry[arrows].spawned_entity>

    - flag <[hb]> fort.supply_drop.hitbox.model:<[sp]>
    - flag <[hb]> fort.supply_drop.hitbox.health:150
    - flag <[hb]> fort.supply_drop.hitbox.loot.gun:<[gun_to_drop]>

    - run fort_chest_handler.supply_drop_activate_sfx def:<map[loc=<[drop_loc]>;hitbox=<[hb]>;volume_multiplier=3]>

    - wait 2t

    - adjust <[arrows]> interpolation_start:0
    - adjust <[arrows]> scale:2.75,2.25,2.75
    - adjust <[arrows]> interpolation_duration:2s

    - define one_third <[height].div[3]>

    - define points <[start_loc].points_between[<[drop_loc]>].distance[0.1]>
    #updating each tick so players can see it "animated" even out of render distance
    - foreach <[points]> as:loc:

      - if !<[sp].is_spawned>:
        - remove <[hb]>     if:<[hb].is_spawned>
        - remove <[circle]> if:<[circle].is_spawned>
        - remove <[arrows]> if:<[arrows].is_spawned>
        - stop

      - if <[loop_index].mod[20]> == 0:
        - playsound <[loc].below[3]> sound:BLOCK_BEACON_AMBIENT pitch:1.5 volume:2

      #second check is so smokes stop when the supply drop is 1/3 to the ground
      - if <[loop_index].mod[5]> == 0 && <[loc].distance[<[start_loc]>]> < <[one_third]>:
        - run fort_chest_handler.supply_drop_smoke_fx def:<map[loc=<[drop_loc]>]>

      - teleport <[hb]> <[loc].below[3]>
      - adjust <[sp]> interpolation_start:0
      - adjust <[sp]> translation:<[loc].sub[<[sp].location>]>
      - adjust <[sp]> interpolation_duration:1t

      - adjust <[circle]> interpolation_start:0
      - adjust <[circle]> left_rotation:<quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[loop_index].div[75]>]>]>
      - adjust <[circle]> interpolation_duration:1t

      - if <[loop_index].mod[40]> == 0:
        - if <[loop_index].mod[80]> < 40:
          - adjust <[arrows]> interpolation_start:0
          - adjust <[arrows]> scale:2.75,2.25,2.75
          - adjust <[arrows]> interpolation_duration:2s
        - else:
          - adjust <[arrows]> interpolation_start:0
          - adjust <[arrows]> scale:2.25,2.25,2.25
          - adjust <[arrows]> interpolation_duration:2s

      #instantly take it down
      - if !<[hb].has_flag[fort.supply_drop.hitbox.health]>:
        - adjust <[sp]> interpolation_start:0
        - adjust <[sp]> translation:<[drop_loc].sub[<[sp].location>]>
        - adjust <[sp]> interpolation_duration:0
        - teleport <[hb]> <[drop_loc].below[3]>
        - foreach stop

      - wait 1t

    #so it can't be damaged anymore when landed
    - flag <[hb]> fort.supply_drop.hitbox.health:!

    - remove <[circle]> if:<[circle].is_spawned>
    - remove <[arrows]> if:<[arrows].is_spawned>

    - run fort_chest_handler.supply_drop_land_fx def:<map[loc=<[drop_loc]>]>

    - adjust <[hb]> width:1.75
    - adjust <[hb]> height:1.5

    - foreach <[drop_loc].find_players_within[10]> as:p:
      - adjust <[p]> stop_sound:minecraft:block.beacon.ambient

    - playsound <[drop_loc]> sound:BLOCK_ANVIL_FALL pitch:0 volume:3
    - playsound <[drop_loc]> sound:BLOCK_AMETHYST_BLOCK_FALL pitch:0.6 volume:3
    - playsound <[drop_loc]> sound:BLOCK_BONE_BLOCK_STEP pitch:0.75 volume:3
    - playsound <[drop_loc]> sound:BLOCK_NETHERITE_BLOCK_FALL pitch:0 volume:3.5

    #-set the text displays
    - define text "<&7><&l>[<&e><&l>Sneak<&7><&l>] <&f><&l>Search"
    - spawn TEXT_DISPLAY[text=<[text]>;pivot=center;scale=1,1,1;view_range=0.04;see_through=false] <[hb].location.above[2]> save:text
    - flag <[hb]> fort.supply_drop.hitbox.text:<entry[text].spawned_entity>

    - wait 1t
    - run fort_chest_handler.supply_drop_activate_sfx def:<map[loc=<[drop_loc]>;hitbox=<[hb]>]>

  supply_drop_activate_sfx:
    - define hb <[data].get[hitbox]>
    - define drop_loc <[data].get[loc]>
    - define vol_mult <[data].get[volume_multiplier]||1>
    - repeat 15:
      - playsound <[drop_loc]> sound:BLOCK_NOTE_BLOCK_XYLOPHONE pitch:1.575 volume:<element[16].sub[<[value]>].div[16].mul[<[vol_mult]>]>
      - if !<[hb].is_spawned>:
        - repeat stop
      - wait 2t

  supply_drop_smoke_fx:
    - define drop_loc <[data].get[loc]>
    - define smoke_points <[drop_loc].above[3].random_offset[0.1].points_between[<[drop_loc].above[<util.random.decimal[10].to[15]>].random_offset[1]>]>
    - foreach <[smoke_points]> as:p:
      - playeffect effect:REDSTONE offset:<util.random.decimal[0.05].to[0.075].mul[<[loop_index]>].mul[<util.random.decimal[0.5].to[1.5]>].add[0.05]> quantity:20 at:<[p]> visibility:100 special_data:<[loop_index].div[2].add[0.5]>|<list[<color[#33c2ff]>|<color[#1482ff]>].random>
      - wait 3t

  open_supply_drop:
  #-used by "after player starts sneaking" event in guns.dsc
    - define hb <player.eye_location.ray_trace_target[range=2.4;ignore=<player>]>

    - define text_display <[hb].flag[fort.supply_drop.hitbox.text]>
    - define text         <[text_display].text>
    - define model        <[hb].flag[fort.supply_drop.hitbox.model]>
    - define drop_loc     <[hb].location.above[0.5]>

    - while <player.is_online> && <player.is_sneaking> && <[hb]||null> != null && !<[hb].has_flag[fort.supply_drop.hitbox.opened]> && <[text_display].is_spawned>:
      - define hb <player.eye_location.ray_trace_target[range=2.4;ignore=<player>]||null>
      - define bar <&chr[8].font[icons].color[<color[<[loop_index]>,0,1]>]>
      - adjust <[text_display]> text:<[text]><&r><proc[spacing].context[-92]><[bar]><proc[spacing].context[-1]>
      - if <[loop_index]> == 10:
        - define open_the_container True
        - while stop
      - wait 1t
    - adjust <[text_display]> text:<[text]>
    - stop if:<[open_the_container].exists.not>

    - define gun <[hb].flag[fort.supply_drop.hitbox.loot.gun]>
    - define ammo_type <[gun].flag[ammo_type]>
    - define ammo_qty  <[gun].flag[mag_size]>
    - if <item[ammo_<[ammo_type]>].has_flag[drop_quantity]>:
      - define ammo_qty <item[ammo_<[ammo_type]>].flag[drop_quantity]>

    - remove <[text_display]> if:<[text_display].is_spawned>
    - remove <[model]> if:<[model].is_spawned>
    - remove <[hb]> if:<[hb].is_spawned>

    # - [ DROP LOOT ] - #

    - foreach <list[wood|brick|metal]> as:mat:
      - run fort_pic_handler.drop_mat def:<map[mat=<[mat]>;qty=30;loc=<[drop_loc]>]>

    - run fort_item_handler.drop_item def:<map[item=fort_item_medkit;qty=1;loc=<[drop_loc]>]>
    - run fort_item_handler.drop_item def:<map[item=fort_item_small_shield_potion;qty=3;loc=<[drop_loc]>]>
    - run fort_item_handler.drop_item def:<map[item=fort_item_shield_potion;qty=1;loc=<[drop_loc]>]>

    - run fort_gun_handler.drop_gun def:<map[gun=<[gun]>;loc=<[drop_loc]>]>
    - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[ammo_qty]>;loc=<[drop_loc]>]>

    - run fort_chest_handler.supply_drop_open_fx def:<map[loc=<[drop_loc]>]>

    - playsound <[drop_loc]> sound:ENTITY_FIREWORK_ROCKET_BLAST pitch:1 volume:2.5
    - wait 4t
    - playsound <[drop_loc]> sound:ENTITY_FIREWORK_ROCKET_BLAST pitch:0.6 volume:1.5
    - playsound <[drop_loc]> sound:ENTITY_FIREWORK_ROCKET_TWINKLE pitch:1 volume:1.2

  supply_drop_land_fx:
  - define drop_loc <[data].get[loc].below[2.8]>
  - playeffect effect:FLASH offset:0 at:<[drop_loc].below[2.8]>
  - repeat 5:
    - playeffect effect:CLOUD offset:0 at:<[drop_loc].points_around_y[radius=<[value].div[2]>;points=<[value].mul[5]>]> visibility:100
    - wait 1t

  supply_drop_open_fx:
  - define drop_loc <[data].get[loc].above[0.5]>
  - playeffect effect:FLASH offset:0 at:<[drop_loc]>
  - repeat 3 as:radius:
    - define sphere <list[]>
    - repeat 18 as:circle_value:
      - define angle <[circle_value].mul[10]>
      - define circle <util.list_numbers_to[15].parse_tag[<[drop_loc].add[<location[0,<[radius]>,0].rotate_around_z[<[Parse_Value].to_radians.mul[24]>].rotate_around_x[0].rotate_around_y[<[angle].to_radians>]>]>]>
      - define sphere <[sphere].include[<[circle]>]>

    - playeffect effect:REDSTONE at:<[sphere]> offset:0.1 quantity:1 visibility:100 special_data:1|<color[#c9c9c9]>
    - wait 1t
