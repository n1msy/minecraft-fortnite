#required flags for all fort_items
#   rarity: x
#   stack_size: x

#create a universal dropping/pick up system for items ? (because of text displays)

fort_item_handler:
  type: world
  debug: false
  definitions: data
  events:

    on entity removed from world:
    - if <context.entity.has_flag[text_display]> && <context.entity.flag[text_display].is_spawned>:
      - remove <context.entity.flag[text_display]>

    on gun_*|ammo_*|fort_item_*|oak_log|bricks|iron_block despawns:
    - determine cancelled

    on player drops fort_item_*:
    - define item  <context.item>
    - flag player fort.item_dropped:<[item]> duration:1t
    #safety
    - wait 1t

    - define drop  <context.entity>

    - define name   <[item].display.strip_color>
    - define rarity <[item].flag[rarity]>
    - define qty    <[item].quantity>

    - define text <&l><[name].to_uppercase.color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=ffaf24].get[<[rarity]>]>]><&f><&l>x<[qty]>

    - run fort_item_handler.item_text def:<map[text=<[text]>;drop=<[drop]>;rarity=<[rarity]>]>

    #- team name:<[rarity]> add:<[drop]> color:<map[Common=GRAY;Uncommon=GREEN;Rare=AQUA;Epic=LIGHT_PURPLE;Legendary=GOLD].get[<[rarity]>]>
    #- adjust <[drop]> glowing:true

    - inject update_hud

    on fort_item_* merges:
    - define item <context.item>
    - define other_item <context.target.item>

    - if <[item].has_flag[thrown_grenade]>:
      - determine passively cancelled
      - stop

    - if <[item].script.name> != <[other_item].script.name>:
      - determine passively cancelled
      - stop

    - define stack_size <[item].flag[stack_size]>
    - define qty        <[item].quantity.add[<[other_item].quantity>]>

    - if <[qty]> > <[stack_size]>:
      - determine passively cancelled
      - stop

    - define target <context.target>
    - if <context.entity.has_flag[text_display]>:
      - remove <context.entity.flag[text_display]>

    - define rarity <[item].flag[rarity]>
    - define text <&l><[item].display.strip_color.color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=ffaf24].get[<[rarity]>]>]><&f><&l>x<[qty]>
    - if <[target].has_flag[text_display]>:
      - adjust <[target].flag[text_display]> text:<[text]>

    on player picks up fort_item_*:
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
      #-excluding slot 1 because of pickaxe?
      #next empty slot
      - define slot <list[2|3|4|5|6].filter_tag[<player.inventory.slot[<[filter_value]>].material.name.equals[air]>].first>
    - else:
      - define slot <list[2|3|4|5|6].parse_tag[<player.inventory.slot[<[parse_value]>]>/<[parse_value]>].filter[before[/].equals[<[item_to_stack_with]>]].sort_by_number[before[/].quantity].parse[after[/]].first>

    - define add_qty <[i].quantity>
    - define new_qty <[current_qty].add[<[add_qty]>]>

    - if <[new_qty]> > <[stack_size]>:
      - define left_over <[new_qty].sub[<[stack_size]>]>
      - define add_qty   <[add_qty].sub[<[left_over]>]>
      - run fort_item_handler.drop_item def:<map[item=<[i].script.name>;qty=<[left_over]>]>

    - define e <context.entity>
    - adjust <player> fake_pickup:<[e]>
    - if <[e].has_flag[text_display]>:
      - remove <[e].flag[text_display]>
    - remove <[e]>

    - define rarity <[i].flag[rarity]>
    - define rarity_line <[rarity].to_titlecase.color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=ffaf24].get[<[rarity]>]>]>
    - define lore <list[<[rarity_line]>]>

    - give <[i].with[quantity=<[add_qty]>;lore=<[lore]>;color=<color[#000000]>]> slot:<[slot]>

  item_text:
    - define text   <[data].get[text]>
    - define rarity <[data].get[rarity]||Common>
    #remove the control pixel
    - define text   <[text].replace_text[<[text].strip_color.to_list.first>].with[<empty>]>
    - define drop   <[data].get[drop]>

    - choose <[drop].item.script.name.after[fort_item_]>:
      - case bush:
        - define translation 0,1,0
      - default:
        - define translation 0,0.75,0

    - spawn <entity[text_display].with[text=<[text]>;pivot=center;scale=1,1,1;translation=<[translation]>;view_range=0.06]> <[drop].location> save:txt
    - define txt <entry[txt].spawned_entity>
    - mount <[txt]>|<[drop]>

    - flag <[drop]> text_display:<[txt]>

    - define rarity_color <color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=ffaf24].get[<[rarity]>]>]>
    - adjust <[drop]> item:<[drop].item.with[color=<[rarity_color]>]>

  drop_item:

    - define item   <[data].get[item].as[item]>
    - define qty    <[data].get[qty]>
    - define loc    <[data].get[loc]||null>
    - define loc    <player.eye_location.forward[1.5].sub[0,0.5,0]> if:<[loc].equals[null]>

    - define rarity <[item].flag[rarity]>
    - define item   <[item].with[quantity=<[qty]>]>

    - drop <[item]> <[loc]> delay:1s save:drop
    - define drop <entry[drop].dropped_entity>

    - define text <&l><[item].display.strip_color.color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=ffaf24].get[<[rarity]>]>]><&f><&l>x<[qty]>

    - run fort_item_handler.item_text def:<map[text=<[text]>;drop=<[drop]>;rarity=<[rarity]>]>

    #- team name:<[rarity]> add:<[drop]> color:<map[Common=GRAY;Uncommon=GREEN;Rare=AQUA;Epic=LIGHT_PURPLE;Legendary=GOLD].get[<[rarity]>]>
    #- adjust <[drop]> glowing:true


  # - [ DROP ALL ITEMS ] - #
  #safely drops all items, mats, and ammo in a player's inventory
  drop_everything:

    - define drops <player.inventory.list_contents>
    - define loc   <player.location>

    - flag player fort.emote:!

    - if <player.has_flag[build]>:
      - define drops <player.flag[build.last_inventory]>
      #dont really need to remove this flag, since the while also checks if the player is alive but oh well
      - flag player build:!

    #so clickable shit in the inventory doesn't drop
    - define drops <[drops].filter[has_flag[action].not].filter[has_flag[type].not]>

    #turn any scoped guns back into unscoped
    - if <player.has_flag[fort.gun_scoped]>:
      - define gun_in_hand <player.item_in_hand>
      - define cmd         <[gun_in_hand].custom_model_data>
      - define drops <[drops].exclude[<[gun_in_hand]>].include[<[gun_in_hand].with[custom_model_data=<[cmd].sub[1]>]>]>
      - flag player fort.gun_scoped:!

    #-drop ammo
    - foreach <list[light|medium|heavy|shells|rockets]> as:ammo_type:
      - if <player.flag[fort.ammo.<[ammo_type]>]> > 0:
        - define qty <player.flag[fort.ammo.<[ammo_type]>]>
        - run fort_gun_handler.drop_ammo def:<map[ammo_type=<[ammo_type]>;qty=<[qty]>;loc=<[loc]>]>
        - flag player fort.ammo.<[ammo_type]>:0

    #-drop mats
    - foreach <list[wood|brick|metal]> as:mat:
      - if <player.flag[fort.<[mat]>.qty]> > 0:
        - define qty <player.flag[fort.<[mat]>.qty]>
        - run fort_pic_handler.drop_mat def:<map[mat=<[mat]>;qty=<[qty]>]>
        - flag player fort.<[mat]>.qty:0

    #-drop guns
    - foreach <[drops].filter[script.name.starts_with[gun_]]> as:gun:
      - run fort_gun_handler.drop_gun def:<map[gun=<[gun]>]>

    #-drop all items (consumables)
    - foreach <[drops].filter[script.name.starts_with[fort_item_]]> as:item:
      - run fort_item_handler.drop_item def:<map[item=<[item].script.name>;qty=<[item].quantity>;loc=<[loc]>]>

    #no need to exclude the fort_pic, since it's not being dropped by any of these
    #clearing inventory in case players were holding the pencil and blueprint while building
    - inventory clear