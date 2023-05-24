fort_chest:
  type: item
  material: gold_nugget
  display name: Chest
  mechanisms:
    custom_model_data: 15
    hides: ALL
  flags:
    qty: 1

fort_chest_handler:
  type: world
  debug: false
  definitions: data
  events:
    on player right clicks block with:fort_chest:
    - determine passively cancelled
    - ratelimit <player> 1t
    - define loc <context.location.above.center.above[0.1]>
    - if <[loc].material.name> != air:
      - narrate "<&c>Invalid spot."
      - stop
    - define text "<&7><&l>[<&e><&l>Sneak<&7><&l>] <&f><&l>Search"
    - define angle <player.location.yaw.add[180].to_radians>
    - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>
    - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=15]>;scale=1.25,1.25,1.25;left_rotation=<[left_rotation]>] <[loc]> save:chest
    - spawn TEXT_DISPLAY[text=<[text]>;pivot=center;scale=1,1,1;view_range=0.035;see_through=true] <[loc].above[0.75]> save:chest_text
    - modifyblock <[loc]> barrier
    - define loc <context.location.above.center>
    - flag <[loc]> fort.chest.model:<entry[chest].spawned_entity>
    - flag <[loc]> fort.chest.text:<entry[chest_text].spawned_entity>
    - flag <[loc]> fort.chest.yaw:<player.location.yaw.add[180]>
    #so it's not using the fx constantly when not in use
    - flag <[loc]> fort.chest.opened
    - flag server fort.chests:->:<[loc]>
    - narrate "<&a>Set chest at <&f><[loc].simple>"

    on player breaks block location_flagged:fort.chest:
    - define loc <context.location.center>
    - remove <[loc].flag[fort.chest.model]> if:<[loc].flag[fort.chest.model].is_spawned>
    - remove <[loc].flag[fort.chest.text]> if:<[loc].flag[fort.chest.text].is_spawned>
    #is this safe to do? (what if there was another flag in the same loc?)
    - flag <[loc]> fort:!
    - flag server fort.chests:<-:<[loc]>

  open:
  #required definitions: look_loc
  - define loc <[look_loc]>
  - define text_display <[loc].flag[fort.chest.text]>
  - define text         <[text_display].text>
  - define chest        <[loc].flag[fort.chest.model]>
  - adjust <[text_display]> see_through:false
  - while <player.is_online> && <player.is_sneaking> && <[loc].has_flag[fort.chest]> && !<[loc].has_flag[fort.chest.opened]> && <[text_display].is_spawned>:
    - define look_loc <player.eye_location.ray_trace[return=block;range=2.7;default=air]>
    - define bar <&chr[8].font[icons].color[<color[<[loop_index]>,0,1]>]>
    - adjust <[text_display]> text:<[text]><&r><proc[spacing].context[-92]><[bar]><proc[spacing].context[-1]>
    - if <[loop_index]> == 10:
      - define open_the_chest True
      - while stop
    - wait 1t
  - adjust <[text_display]> see_through:true
  - adjust <[text_display]> text:<[text]>
  - stop if:<[open_the_chest].exists.not>

  - flag <[loc]> fort.chest.opened

  - remove <[text_display]> if:<[text_display].is_spawned>

  - adjust <[chest]> item:<item[gold_nugget].with[custom_model_data=16]>

  - playsound <[chest].location> sound:BLOCK_CHEST_OPEN volume:0.5 pitch:1
  - playsound <[chest].location> sound:BLOCK_AMETHYST_CLUSTER_BREAK pitch:0.85 volume:2

  - define drop_loc <[chest].location.forward>

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
    #required definitions:
    # - <[loc]> - #

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
      - define rarities <[g].flag[rarities]>
        #excluding, since common is the default if none other pass
      - foreach <[rarities].keys> as:r:
        - if <util.random_chance[<[g].flag[rarities.<[r]>.chance]>]>:
          - define rarity <[r]>
          - foreach stop
      - if <[rarity].exists>:
        - define gun <[g].with[flag=rarity:<[rarity]>]>
        - foreach stop
    #default rarity is already the lowest
    - define gun  <[guns].first> if:!<[gun].exists>

    - flag <[loc]> fort.chest.loot.mat:<[mat_to_drop]>
    - flag <[loc]> fort.chest.loot.item:<[item_to_drop]>
    - flag <[loc]> fort.chest.loot.gun:<[gun]>

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