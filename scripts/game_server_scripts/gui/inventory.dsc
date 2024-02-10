fort_inventory_handler:
  type: task
  debug: false
  definitions: mat|ammo_type|slot
  script:
    - narrate "inventory-handling related tasks"

  # - [ Player Inventory Item Updates ] - #
  update:
    #slot data: wood = 19, brick = 20, metal= 21
    material:
      #<[material]> definition is defined upon running task
      # - none check - #
      - define slot <map[wood=19;brick=20;metal=21].get[<[mat]>]>

      - if !<player.has_flag[fort.<[mat]>.qty]> || <player.flag[fort.<[mat]>.qty]> == 0:
        - inventory set o:air slot:<[slot]>
        - stop
      - define drop_text "<&r><n><&9><&l>Left-Click <&f>to drop one.<n><&c><&l>Right-Click <&f>to drop multiple."
      - define cmd        <map[wood=8;brick=9;metal=10].get[<[mat]>]>

      - define name <[mat].to_uppercase.bold>
      - define lore <list[<&7>Qty: <&f><player.flag[fort.<[mat]>.qty]>|<[drop_text]>]>
      - define item <item[paper].with[display=<[name]>;lore=<[lore]>;custom_model_data=<[cmd]>;flag=type:material;flag=mat:<[mat]>]>
      - inventory set o:<[item]> slot:<[slot]>

    ammo:
      #<[ammo_type]> is inputted

      - define slot <map[light=23;medium=24;heavy=25;shells=26;rockets=27].get[<[ammo_type]>]>
      - if !<player.has_flag[fort.ammo.<[ammo_type]>]> || <player.flag[fort.ammo.<[ammo_type]>]> == 0:
        - inventory set o:air slot:<[slot]>
        - stop

      - define drop_text "<&r><n><&9><&l>Left-Click <&f>to drop one.<n><&c><&l>Right-Click <&f>to drop multiple."
      - define cmd       <map[light=12;medium=13;heavy=14;shells=15;rockets=16].get[<[ammo_type]>]>

      - define name <[ammo_type].to_uppercase.bold>
      - define lore <list[<&7>Qty: <&f><player.flag[fort.ammo.<[ammo_type]>]>|<[drop_text]>]>
      - define item <item[paper].with[display=<[name]>;lore=<[lore]>;custom_model_data=<[cmd]>;flag=type:ammo;flag=ammo_type:<[ammo_type]>]>
      - inventory set o:<[item]> slot:<[slot]>

  update_rarity_bg:
    # - [ Rarity Backgrounds in Player Inventory ] - #
    #<[slot]> is inputted

    #this should fire only when:
    #player clicks item in inventory
    #player picks up item
    #player drops item

    - define item <player.inventory.slot[<[slot]>]>

    # - remove rarity bg - #
    - if !<[item].has_flag[rarity]>:
      - inventory set o:air slot:<[slot].add[27]>
      - stop

    - define rarity_list <list[common|uncommon|rare|epic|legendary]>
    - define tooltip_remover <list[<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|<empty>|                                                                                                                                                                                                                                                                                                                                                                                                                           ]>

    - define rarity <[item].flag[rarity]>

    #get the CMD for the rarity
    - define rarity_number <[rarity_list].find[<[rarity]>]>
    - inventory set o:<item[paper].with[lore=<[tooltip_remover]>;custom_model_data=<[rarity_number].add[19]>]> slot:<[slot].add[27]>