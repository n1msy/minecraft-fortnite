fort_heal_handler:
  type: world
  debug: false
  definitions: data
  events:
    on player left clicks block with:fort_item_bandages|fort_item_medkit|fort_item_small_shield_potion|fort_item_shield_potion flagged:!fort.healing:
    - determine passively cancelled
    - cast FAST_DIGGING amplifier:9999 duration:1s no_icon no_ambient hide_particles

    - define health <player.health.mul[5].round>
    - define real_shield <player.armor_bonus>
    - define shield <[real_shield].mul[5].round>

    - define i    <context.item>
    - define name <[i].script.name.after[fort_item_]>

    - if <list[small_shield_potion|shield_potion].contains[<[name]>]> && <[shield]> == 100:
      - playsound <player> sound:ENTITY_VILLAGER_NO pitch:1.5
      - stop

    - if <list[bandages|medkit].contains[<[name]>]> && <[health]> == 100:
      - playsound <player> sound:ENTITY_VILLAGER_NO pitch:1.5
      - stop

    - if <[name]> == bandages && <[health]> >= 75:
      - playsound <player> sound:ENTITY_VILLAGER_NO pitch:1.5
      - stop

    - if <[name]> == small_shield_potion && <[shield]> >= 50:
      - playsound <player> sound:ENTITY_VILLAGER_NO pitch:1.5
      - stop

    - if <list[bandages|medkit].contains[<[name]>]>:
      - playsound <player> sound:ITEM_ARMOR_EQUIP_LEATHER pitch:1
    - else:
      - playsound <player> sound:ENTITY_GENERIC_DRINK

    #to ticks
    - define use_time <[i].flag[use_time].mul[20]>

    - flag player fort.healing
    - define loc <player.location.simple>

    - while <player.has_flag[fort.healing]>:
      - if <player.location.simple> != <[loc]> || !<player.is_online> || <player.item_in_hand> != <[i]>:
        - playsound <player> sound:ENTITY_VILLAGER_NO pitch:1.5
        - actionbar <&sp>
        - flag player fort.healing:!
        - stop

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
        - playsound <player> sound:ENTITY_EXPERIENCE_ORB_PICKUP pitch:1

      - case medkit:
        - heal
        - playeffect at:<[particle_loc]> offset:0.3,0.5,0.3 quantity:25 effect:REDSTONE special_data:1.5|LIME
        - playsound <player> sound:ENTITY_EXPERIENCE_ORB_PICKUP pitch:1

      - case small_shield_potion:
        - if <[shield].add[25]> > 50:
          - adjust <player> armor_bonus:10
        - else:
          - adjust <player> armor_bonus:<[real_shield].add[5]>
        - playeffect at:<[particle_loc]> offset:0.3,0.5,0.3 quantity:25 effect:REDSTONE special_data:1.5|AQUA
        - playsound <player> sound:BLOCK_NOTE_BLOCK_CHIME pitch:1.5

      - case shield_potion:
        - if <[shield].add[50]> > 100:
          - adjust <player> armor_bonus:20
        - else:
          - adjust <player> armor_bonus:<[real_shield].add[10]>
        - playeffect at:<[particle_loc]> offset:0.3,0.5,0.3 quantity:25 effect:REDSTONE special_data:1.5|AQUA
        - playsound <player> sound:BLOCK_NOTE_BLOCK_CHIME pitch:1.5

    - take item:<[i]>

    - inject update_hud
    - flag player fort.healing:!

fort_item_bandages:
  type: item
  material: gold_nugget
  display name: <&f><&l>BANDAGES
  mechanisms:
    custom_model_data: 8
    hides: ALL
  flags:
    rarity: uncommon
    health: 15
    stack_size: 15
    #in seconds
    use_time: 3.5

fort_item_medkit:
  type: item
  material: gold_nugget
  display name: <&f><&l>MED KIT
  mechanisms:
    custom_model_data: 9
    hides: ALL
  flags:
    rarity: uncommon
    health: 100
    stack_size: 3
    use_time: 9.9

fort_item_small_shield_potion:
  type: item
  material: gold_nugget
  display name: <&f><&l>SMALL SHIELD POTION
  mechanisms:
    custom_model_data: 10
    hides: ALL
  flags:
    rarity: uncommon
    shield: 25
    stack_size: 6
    use_time: 2

fort_item_shield_potion:
  type: item
  material: gold_nugget
  display name: <&f><&l>SHIELD POTION
  mechanisms:
    custom_model_data: 11
    hides: ALL
  flags:
    rarity: rare
    shield: 50
    stack_size: 3
    use_time: 5