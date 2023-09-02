fort_consumable_handler:
  type: world
  debug: false
  definitions: data
  events:

    #-Bush handler (any damage they take is negated once)
    on player damaged flagged:fort.bush priority:-10:
    - narrate "<&c>Player damage was negated. This is a debug message. If you see this still, please remind Nimsy to change it."
    - define bush <player.flag[fort.bush]>
    - define loc <[bush].location>

    - playsound <[loc]> sound:BLOCK_SWEET_BERRY_BUSH_BREAK pitch:0.9 volume:1.5
    - playeffect effect:TOTEM at:<[loc]> offset:0.3 quantity:15 data:0.35 visibility:100
    - remove <[bush]>
    - flag player fort.bush:!

    on player left clicks block with:fort_item_bush|fort_item_bandages|fort_item_medkit|fort_item_small_shield_potion|fort_item_shield_potion flagged:!fort.consuming:
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

    - if <[name]> == small_shield_potion && <[shield]> >= 50:
      - playsound <player> sound:ENTITY_VILLAGER_NO pitch:1.5
      - stop

    #so they can't reapply a bush if they're already wearing one
    - if <[name]> == bush && <player.has_flag[fort.bush]>:
      - playsound <player> sound:ENTITY_VILLAGER_NO pitch:1.5
      - stop

    - if <list[bandages|medkit|bush].contains[<[name]>]>:
      - playsound <player> sound:ITEM_ARMOR_EQUIP_LEATHER pitch:1
    - else:
      - playsound <player> sound:ENTITY_GENERIC_DRINK

    #to ticks
    - define use_time <[i].flag[use_time].mul[20]>

    - flag player fort.consuming
    - define loc <player.location.simple>

    - while <player.has_flag[fort.consuming]>:
      - if <player.location.simple> != <[loc]> || !<player.is_online> || <player.item_in_hand> != <[i]>:
        - playsound <player> sound:ENTITY_VILLAGER_NO pitch:1.5
        - actionbar <&sp>
        - flag player fort.consuming:!
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

      - case bush:
        - spawn <entity[item_display].with[item=<item[gold_nugget].with[custom_model_data=19]>;scale=1.2,1.2,1.2;translation=0,-0.75,0]> <player.location.with_pose[0,0].above> save:bush
        - define bush <entry[bush].spawned_entity>
        - mount <[bush]>|<player>
        - run fort_consumable_handler.use_bush def:<[bush]>
        - flag player fort.bush:<[bush]>
        - playsound <player> sound:ENTITY_EXPERIENCE_ORB_PICKUP pitch:1

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
    - flag player fort.consuming:!

  use_bush:
    - define bush <[data]>
    - look <[bush]> pitch:0

    #reset pitch
    - while <[bush].is_spawned> && <player.is_online>:

      - define bush_loc <[bush].location>
      #player leaf particle effects when moving
      - if <[p_loc].with_pose[0,0]||null> != <player.location.with_pose[0,0]> && <[loop_index].mod[2]> == 0:
        - define p_loc <player.location>
        #sneaking makes the sound loop interval get slower
        - if !<player.is_sneaking> && <[loop_index].mod[4]> == 0:
          - playsound <[p_loc]> sound:BLOCK_GRASS_STEP pitch:0.7 volume:0.5
        - else if <player.is_sneaking> && <[loop_index].mod[7]> == 0:
          - playsound <[p_loc]> sound:BLOCK_GRASS_STEP pitch:0.7 volume:0.5
        - playeffect effect:TOTEM at:<[p_loc].above.forward> offset:0.3 quantity:1 data:0.2 visibility:100

      #this way, it won't interpolate if the yaw was already the same
      - if <[yaw]||null> != <player.location.yaw>:
        - define yaw <player.location.yaw>
        - define angle <[yaw].to_radians>
        - define left_rotation <quaternion[0,0,0,1].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

        - adjust <[bush]> interpolation_start:0
        - adjust <[bush]> interpolation_duration:1t
        - adjust <[bush]> left_rotation:<[left_rotation]>

      - wait 1t

    - flag player fort.bush:!
    - remove <[bush]> if:<[bush].is_spawned>

fort_item_bush:
  type: item
  material: gold_nugget
  display name: <&f><&l>BUSH
  mechanisms:
    custom_model_data: 19
    hides: ALL
  flags:
    rarity: legendary
    #i can't find the actual drop chance?
    #replaces other consumables from chests
    chance: 5
    icon_chr: 7
    drop_quantity: 2
    stack_size: 2
    use_time: 3

## Heals
fort_item_bandages:
  type: item
  material: gold_nugget
  display name: <&f><&l>BANDAGES
  mechanisms:
    custom_model_data: 8
    hides: ALL
  flags:
    rarity: uncommon
    chance: 17.6
    icon_chr: 1
    drop_quantity: 5
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
    chance: 16
    icon_chr: 2
    drop_quantity: 1
    health: 100
    stack_size: 3
    use_time: 9.9

fort_item_small_shield_potion:
  type: item
  material: gold_nugget
  display name: <&f><&l>SMALL SHIELD POTION
  mechanisms:
    custom_model_data: 11
    hides: ALL
  flags:
    rarity: uncommon
    chance: 17.6
    icon_chr: 3
    drop_quantity: 3
    shield: 25
    stack_size: 9
    use_time: 2

fort_item_shield_potion:
  type: item
  material: gold_nugget
  display name: <&f><&l>SHIELD POTION
  mechanisms:
    custom_model_data: 12
    hides: ALL
  flags:
    rarity: rare
    chance: 17.6
    icon_chr: 4
    drop_quantity: 1
    shield: 50
    stack_size: 3
    use_time: 5