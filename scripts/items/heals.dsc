fort_heal_handler:
  type: world
  debug: false
  events:
    on player picks up bandages|medkit|small_shield_potion|shield_potion:
    - define stack_size <context.item.flag[stack_size]>
    - define qty        <player.inventory.find_all_items[<context.item>].size.add[1]>
    - if <[qty]> > <[stack_size]>:
      - determine passively cancelled
      - stop

    on player left clicks block with:bandages|medkit flagged:!fort.healing:
    - define health <player.health.mul[5].round>

    - if <[health]> > 75:
      - narrate "<&c>Cannot use bandages over 75 hp."
      - stop

    - define i <context.item>
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

    ##play a cute green splash effect

    - flag player fort.healing:!

    - define bar  <&chr[16].font[load]>
    - define time <&sp><&l>0.0
    - define text <proc[spacing].context[-7]><[bar]><proc[spacing].context[-30]><[time]>
    - actionbar <[text].color[66,0,0]>

bandages:
  type: item
  material: gold_nugget
  display name: <&f><&l>BANDAGES
  mechanisms:
    custom_model_data: 1
    hides: ALL
  flags:
    rarity: uncommon
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
    stack_size: 3
    use_time: 5