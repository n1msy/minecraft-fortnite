#required flags for all fort_items
#   rarity: x
#   stack_size: x

fort_item_handler:
  type: world
  debug: false
  definitions: data
  events:
    after player drops fort_item_*:
    - define item  <context.item>
    - define drop  <context.entity>

    - define name   <[item].display.strip_color>
    - define rarity <[item].flag[rarity]>
    - define qty    <[item].quantity>

    - define text <&l><[name].to_uppercase.color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=#ffaf24].get[<[rarity]>]>]><&f><&l>x<[qty]>

    - adjust <[drop]> custom_name:<[text]>
    - adjust <[drop]> custom_name_visible:true

    - inject update_hud

    on fort_item_* merges:
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
      #next empty slot
      - define slot <list[2|3|4|5|6].filter_tag[<player.inventory.slot[<[filter_value]>].material.name.equals[air]>].first>
    - else:
      - define slot <list[2|3|4|5|6].parse_tag[<player.inventory.slot[<[parse_value]>]>/<[parse_value]>].filter[before[/].equals[<[item_to_stack_with]>]].sort_by_number[before[/].quantity].parse[after[/]].first>

    - define add_qty <[i].quantity>
    - define new_qty <[current_qty].add[<[add_qty]>]>

    - if <[new_qty]> > <[stack_size]>:
      - define left_over <[new_qty].sub[<[stack_size]>]>
      - define add_qty   <[add_qty].sub[<[left_over]>]>
      - run fort_item_handler.drop_item def:<map[heal_item=<[i].script.name>;qty=<[left_over]>]>

    - adjust <player> fake_pickup:<context.entity>
    - remove <context.entity>
    - give <[i].with[quantity=<[add_qty]>]> slot:<[slot]>

  drop_item:

    - define item   <[data].get[heal_item].as[item]>
    - define qty    <[data].get[qty]>
    - define rarity <[item].flag[rarity]>

    - define loc    <player.eye_location.forward[1.5].sub[0,0.5,0]>

    - define item <[item].with[quantity=<[qty]>]>

    - drop <[item]> <[loc]> delay:1s save:drop
    - define drop <entry[drop].dropped_entity>

    - define text <&l><[item].display.strip_color.color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=#ffaf24].get[<[rarity]>]>]><&f><&l>x<[qty]>

    - adjust <[drop]> custom_name:<[text]>
    - adjust <[drop]> custom_name_visible:true