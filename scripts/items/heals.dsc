fort_heal_handler:
  type: world
  debug: false
  definitions: data
  events:
    after player drops bandages|medkit|small_shield_potion|shield_potion:
    - define item  <context.item>
    - define drop  <context.entity>

    - define name   <[item].display.strip_color>
    - define rarity <[item].flag[rarity]>
    - define qty    <[item].quantity>

    - define text <&l><[name].to_titlecase.color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=#ffaf24].get[<[rarity]>]>]><&f><&l>x<[qty]>

    - adjust <[drop]> custom_name:<[text]>
    - adjust <[drop]> custom_name_visible:true

    - inject update_hud

    on bandages|medkit|small_shield_potion|shield_potion merges:
    - define item <context.item>
    - define other_item <context.target.item>

    - if <[item].script.name> != <[other_item].script.name>:
      - determine passively cancelled
      - stop

    - define stack_size <[item].flag[stack_size]>
    - define qty        <[item].quantity.add[<[other_item].quantity>]>

    - if <[qty]> > <[stack_size]>:
      - determine passively cancelled
      - stop

    - define rarity <[item].flag[rarity]>
    - define text <&l><[item].display.strip_color.color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=#ffaf24].get[<[rarity]>]>]><&f><&l>x<[qty]>
    - adjust <context.target> custom_name:<[text]>

    on player picks up bandages|medkit|small_shield_potion|shield_potion:
    - determine passively cancelled
    - define i                  <context.item>
    - define item_to_stack_with <player.inventory.list_contents.filter[script.name.equals[<[i].script.name>]].sort_by_number[quantity].first||null>
    - define stack_size         <[i].flag[stack_size]>
    - define current_qty        <[item_to_stack_with].quantity||0>

    - if <[current_qty]> == <[stack_size]>:
      - define item_to_stack_with null
      - define current_qty        0

    #cancel pickup
    - if <[item_to_stack_with]> == null && <player.inventory.slot[2|3|4|5|6].filter[material.name.equals[air]].is_empty>:
      - stop

    - if <[item_to_stack_with]> == null:
      #next empty slot
      - define slot <list[2|3|4|5|6].filter_tag[<player.inventory.slot[<[filter_value]>].material.name.equals[air]>].first>
    - else:
      - define slot <list[2|3|4|5|6].parse_tag[<player.inventory.slot[<[parse_value]>]>/<[parse_value]>].filter[before[/].equals[<[item_to_stack_with]>]].sort_by_number[before[/].quantity].parse[after[/]].first>

    - define add_qty <[i].quantity>
    - define new_qty <[current_qty].add[<[add_qty]>]>

    - if <[new_qty]> > <[stack_size]>:
      - define left_over <[new_qty].sub[<[stack_size]>]>
      - define add_qty   <[add_qty].sub[<[left_over]>]>
      - run fort_heal_handler.drop_heal def:<map[heal_item=<[i].script.name>;qty=<[left_over]>]>

    - adjust <player> fake_pickup:<context.entity>
    - remove <context.entity>
    - give <[i].with[quantity=<[add_qty]>]> slot:<[slot]>

    on player left clicks block with:bandages|medkit|small_shield_potion|shield_potion flagged:!fort.healing:
    - define health <player.health.mul[5].round>
    - define real_shield <player.armor_bonus>
    - define shield <[real_shield].mul[5].round>

    - define i    <context.item>
    - define name <[i].script.name>

    - if <list[small_shield_potion|shield_potion].contains[<[name]>]> && <[shield]> == 100:
      - playsound <player> sound:ENTITY_VILLAGER_NO pitch:2
      - stop

    - if <list[bandages|medkit].contains[<[name]>]> && <[health]> == 100:
      - playsound <player> sound:ENTITY_VILLAGER_NO pitch:2
      - stop

    - if <[name]> == bandages && <[health]> >= 75:
      - playsound <player> sound:ENTITY_VILLAGER_NO pitch:2
      - stop

    - if <[name]> == small_shield_potion && <[shield]> >= 50:
      - playsound <player> sound:ENTITY_VILLAGER_NO pitch:2
      - stop

    #to ticks
    - define use_time <[i].flag[use_time].mul[20]>

    - flag player fort.healing
    - define loc <player.location.simple>

    - while <player.has_flag[fort.healing]>:
      - if <player.location.simple> != <[loc]> || !<player.is_online> || <player.item_in_hand> != <[i]>:
        - flag player fort.healing:!
        - stop

      - if <[loop_index]> == <[use_time]>:
        - while stop

      - define bar  <&chr[<[loop_index].mul[16].div[<[use_time]>].round_down.add[1]>].font[load]>
      - define time <[use_time].sub[<[loop_index]>].div[20].round_to[1]>
      - define time <[time]>.0 if:<[time].is_integer>
      - define time <&l><&sp><[time]>
      - define text <proc[spacing].context[-7]><[bar]><proc[spacing].context[-31]><[time]>
      - actionbar <[text].color[66,0,0]>

      - if <[loop_index]> == <[use_time]>:
        - while stop
      - wait 1t

    - define bar  <&chr[16].font[load]>
    - define time <&sp><&l>0.0
    - define text <proc[spacing].context[-7]><[bar]><proc[spacing].context[-30]><[time]>
    - actionbar <[text].color[66,0,0]>

    - define particle_loc <player.location.above.forward_flat[0.15]>

    - choose <[name]>:
      - case bandages:
        - if <[health].add[15]> > 75:
          - adjust <player> health:15
        - else:
          - heal 3
        - playeffect at:<[particle_loc]> offset:0.3,0.5,0.3 quantity:25 effect:REDSTONE special_data:1.5|LIME
        - playsound <player> sound:BLOCK_NOTE_BLOCK_PLING pitch:1.5

      - case medkit:
        - heal
        - playeffect at:<[particle_loc]> offset:0.3,0.5,0.3 quantity:25 effect:REDSTONE special_data:1.5|LIME
        - playsound <player> sound:BLOCK_NOTE_BLOCK_PLING pitch:1.5

      - case small_shield_potion:
        - if <[shield].add[25]> > 50:
          - adjust <player> armor_bonus:10
        - else:
          - adjust <player> armor_bonus:<[real_shield].add[5]>
        - playeffect at:<[particle_loc]> offset:0.3,0.5,0.3 quantity:25 effect:REDSTONE special_data:1.5|AQUA
        - playsound <player> sound:BLOCK_NOTE_BLOCK_CHIME pitch:1.5

      - case shield_potion:
        - if <[shield].add[50]> > 100:
          - adjust <player> armor_bonus:100
        - else:
          - adjust <player> armor_bonus:<[real_shield].add[10]>
        - playeffect at:<[particle_loc]> offset:0.3,0.5,0.3 quantity:25 effect:REDSTONE special_data:1.5|AQUA
        - playsound <player> sound:BLOCK_NOTE_BLOCK_CHIME pitch:1.5

    - inject update_hud
    - flag player fort.healing:!

  drop_heal:

    - define item   <[data].get[heal_item].as[item]>
    - define qty    <[data].get[qty]>
    - define rarity <[item].flag[rarity]>

    - define loc       <player.eye_location.forward[1.5].sub[0,0.5,0]>

    - define item <[item].with[quantity=<[qty]>]>

    - drop <[item]> <[loc]> delay:1s save:drop
    - define drop <entry[drop].dropped_entity>

    - define text <&l><[item].display.strip_color.color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=#ffaf24].get[<[rarity]>]>]><&f><&l>x<[qty]>

    - adjust <[drop]> custom_name:<[text]>
    - adjust <[drop]> custom_name_visible:true

bandages:
  type: item
  material: gold_nugget
  display name: <&f><&l>BANDAGES
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    rarity: uncommon
    health: 15
    stack_size: 15
    #in seconds
    use_time: 3.5

medkit:
  type: item
  material: gold_nugget
  display name: <&f><&l>MED KIT
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    rarity: uncommon
    health: 100
    stack_size: 3
    use_time: 9.9

small_shield_potion:
  type: item
  material: gold_nugget
  display name: <&f><&l>SMALL SHIELD POTION
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    rarity: uncommon
    shield: 25
    stack_size: 6
    use_time: 2

shield_potion:
  type: item
  material: gold_nugget
  display name: <&f><&l>SHIELD POTION
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    rarity: rare
    shield: 50
    stack_size: 3
    use_time: 5