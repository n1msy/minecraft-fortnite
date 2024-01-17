#required flags for all fort_items
#   rarity: x
#   stack_size: x

#create a universal dropping/pick up system for items ? (because of text displays)

fort_item_handler:
  type: world
  debug: false
  definitions: data
  events:

    #make the item unequipable
    #in the future, add the guidelines to make it throwable here?
    on player right clicks block with:fort_item_*:
    #if check so you can open doors
    - determine passively cancelled if:!<context.location.material.name.contains_text[door]||false>

    - cast FAST_DIGGING amplifier:9999 duration:1s no_icon no_ambient hide_particles
    #giving dropped flag so the consume event doesn't fire
    - flag player fort.item_dropped duration:1t

    #removed in favor of "tracking" event for item displays
    #on entity removed from world:
    #- if <context.entity.has_flag[text_display]> && <context.entity.flag[text_display].is_spawned>:
    #  - remove <context.entity.flag[text_display]>

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

    #so all items match to merge
    - adjust <[drop].item> lore:<list[]>

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

    #-either re-calculate the name, or use the name of the item that was already on the ground?
    - define rarity <[item].flag[rarity]>
    #remove the control pixel
    - define text   <[item].script.name.as[item].display.strip_color>
    - define text   <[text].replace_text[<[text].to_list.first>].with[<empty>]>
    - define text   <&l><[text].color[#<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=ffaf24].get[<[rarity]>]>]><&f><&l>x<[qty]>
    - if <[target].has_flag[text_display]>:
      - adjust <[target].flag[text_display]> text:<[text]>

    on player picks up fort_item_*:
    - determine passively cancelled

    #-save hotbar
    #save ordered hotbar items with slot data
    - foreach <list[2|3|4|5|6]> as:slot:
      - define i      <player.inventory.slot[<[slot]>]>
      - define is_air <[i].material.name.equals[air]>
      #storing slot data in case
      - define hotbar_items:->:<map[item=<[i]>;slot=<[slot]>;is_air=<[is_air]>]>

    #item being picked up
    - define item   <context.item>
    - define current_qty <[item].quantity>

    #define here, but stack items take priority over air slots
    - define air_slots <[hotbar_items].filter[get[item].material.name.equals[air]]||null>

    - define stack_size <[item].flag[stack_size]>
    - define same_items <[hotbar_items].filter[get[item].script.name.equals[<[item].script.name>]]>
    #look for the same item that's not completely full
    - define same_incomplete_stack_items <[same_items].filter[get[item].quantity.is[LESS].than[<[stack_size]>]]>

    #stacked slots take priority
    - define available_slots_data <[same_incomplete_stack_items].include[<[air_slots]>]>

    #you can't pick up anything
    - if <[available_slots_data].is_empty>:
      - stop

    #no need to do left_over math if we're doing this
    # repeat <[current_qty]>:
    - define rarity       <[item].flag[rarity]>
    - define rarity_color #<map[Common=bfbfbf;Uncommon=4fd934;Rare=45c7ff;Epic=bb33ff;Legendary=ffaf24].get[<[rarity]>]>
    - define rarity_line  <[rarity].to_titlecase.color[<[rarity_color]>]>
    - define lore         <list[<[rarity_line]>]>
    #reconstruct the name
    - define item_name <[item].script.name.as[item].display>

    - define item <[item].with[display=<[item_name]>;lore=<[lore]>;color=black]>


    #doing a foreach in case there are multiples of that in complete stack throughout the hotbar
    - foreach <[available_slots_data]> as:slot_data:
      #both have to be true if we want to continue
      - if <[current_qty]> == 0:
        - foreach stop


      - define item_to_stack_with <[slot_data].get[item]>

      #no need for defining slot, but just doing it anyways because it's being defined by air slot
      - define slot               <[slot_data].get[slot]>

      - define other_qty          <[item_to_stack_with].quantity>
      #total of that item that's being picked up (pre stack size check)
      - define give_qty           <[current_qty]>
      - define total_qty          <[give_qty].add[<[other_qty]>]>

      #drop the quantity of items that's exceeding the stack size
      - if <[total_qty]> > <[stack_size]>:
        #the drop quantity would be what's left over
        - define left_over <[total_qty].sub[<[stack_size]>]>
        - define give_qty  <[give_qty].sub[<[left_over]>]>
      #defining this, so the next iteration knowns how much is left
      - define current_qty    <[current_qty].sub[<[give_qty]>]>
      - if <[left_over].exists>:
        - define left_over:-:<[current_qty]>

      - define item_to_give      <[item].with[quantity=<[give_qty].add[<[other_qty]>]>]>
      - define item_give_data:->:<map[item=<[item_to_give]>;slot=<[slot]>]>

    - if <[left_over].exists> && <[left_over]> > 0:
      - run fort_item_handler.drop_item def:<map[item=<[item].script.name>;qty=<[left_over]>]>

    - define drop <context.entity>
    - adjust <player> fake_pickup:<[drop]>
    - if <[drop].has_flag[text_display]>:
      - remove <[drop].flag[text_display]>
    - remove <[drop]>

    - foreach <[item_give_data]> as:data:
      - inventory set o:<[data].get[item]> slot:<[data].get[slot]>

    - run update_hud

  item_text:
    - define text   <[data].get[text]>
    - define rarity <[data].get[rarity]||Common>
    #remove the control pixel
    - define text   <[text].replace_text[<[text].strip_color.to_list.first>].with[<empty>]>
    - define drop   <[data].get[drop]>

    #- choose <[drop].item.script.name.after[fort_item_]>:
      #- case bush:
      #  - define translation 0,1,0
      #- default:
    - define translation 0,0.75,0

    - spawn <entity[text_display].with[text=<[text]>;pivot=center;scale=1,1,1;translation=<[translation]>;view_range=0.06]> <[drop].location> save:txt
    - define txt <entry[txt].spawned_entity>
    - mount <[txt]>|<[drop]>

    - flag <[txt]>  linked_drop:<[drop]>
    - flag <[drop]> text:<[txt]>
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

    #reset the lore so items that were intialized in hotbar can stack with non-intialized ones
    - drop <[item].with[lore=<list[]>]> <[loc]> delay:1s save:drop
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