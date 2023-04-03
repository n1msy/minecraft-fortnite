fort_pic:
  type: item
  material: stone_pickaxe
  display name: Pickaxe

fort_pic_handler:
  type: world
  debug: false
  events:

    #on player animates ARM_SWING with:fort_pic flagged:fort.pic.block_target:
    #- define block <player.flag[fort.pic.block_target]>
    #- flag player fort.pic.block_target:<[block]> duration:3t

    #- if <[block].flag[health]> == -1:
      #- determine passively cancelled

    #- blockcrack <[block]> progress:0 players:<server.online_players>

    #- ratelimit <player> 1t

    on player clicks block type:!air:
    - stop if:<player.world.name.equals[fortnite_map].not>
    - determine passively cancelled

    #on player clicks block type:!air:
   # - stop if:<player.world.name.equals[fortnite_map].not>
   # - determine passively cancelled
    - if <player.item_in_hand.script.name||null> == fort_pic:
      - define i <player.item_in_hand>

      - define block <context.location>
      - define mat <[block].material.name>

      - if <[mat].contains_any_text[oak|spruce|birch|jungle|acacia|dark_oak|mangrove|warped|barrel]>:
        - define tool stone_axe
      - else:
        - define tool stone_pickaxe

      - if <[i].material.name> != <[tool]>:
        - inventory adjust slot:<player.held_item_slot> material:<[tool]>

      #- define type <proc[get_material_type].context[<[mat]>]>

     # - if <[type]> == null:
      #  - stop

     # - if <[type]> == wood:
       # - inventory adjust slot:<player.held_item_slot> material:stone_axe
      #- else:
        #- inventory adjust slot:<player.held_item_slot> material:stone_pickaxe

      #flag the block health if it hasn't been set yet
      #- if !<[block].has_flag[health]>:
       # - define mat <[block].material.name>
       # - define type <proc[get_material_type].context[<[mat]>]>

        #if it's not in the list of valid materials to return either wood, brick, or metal
      #  - if <[type]> == null:
       #   - define hp -1
      #  - else:
         # - define hp <script[nimnite_config].data_key[materials.<[type]>.hp]>

        #- flag <[block]> health:<[hp]>

    #infinite durability
    on fort_pic takes damage:
    - determine cancelled
    on player drops fort_pic:
    - determine cancelled
    on player clicks fort_pic in inventory:
    - determine cancelled

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