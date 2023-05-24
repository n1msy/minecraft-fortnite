
###use shaders for health bar instead of repeating values (input the health in r values)

#-basically everything that's not the map
update_hud:
  type: task
  debug: false
  script:

  #falling icon turns to clock icon after bus is done dropping

  # - [ Ammo ] - #
  #depends on what gun you're holding
  - define ammo_ <empty>
  - if <player.item_in_hand.script.name.starts_with[gun_]||false>:
    - define gun_uuid      <player.item_in_hand.flag[uuid]>
    - define ammo_type     <player.item_in_hand.flag[ammo_type]>
    - define loaded_ammo   <server.flag[fort.temp.<[gun_uuid]>.loaded_ammo]>
    - define total_ammo    <player.flag[fort.ammo.<[ammo_type]>]||0>
    - define ammo_icon     <&chr[E00<map[light=1;medium=2;heavy=3;shells=4;rockets=5].get[<[ammo_type]>]>].font[icons]>
    - define ammo_text    "<element[<[loaded_ammo]> / <[total_ammo]>].font[ammo_text]> <[ammo_icon]>"
    #- define ammo_centered <element[<[loaded_ammo]> / <[total_ammo]>].font[neg_half_c]><[ammo_text]><element[<[loaded_ammo]> / <[total_ammo]>].font[neg_half_f]>
    - define ammo_         <[ammo_text].color[<color[12,0,0]>]>

  - define empty_bar <&chr[C000].font[icons]>

  # - [ Main Health/Shield Bars ] - #
  - define health      <player.health.mul[5].round>
  - define health_r    <[health].div[100].mul[255].round_down>
  - define health_bar  <[empty_bar].color[<[health_r]>,0,0]>
  - define health_text "<element[<proc[spacing].context[-215]><[health]>].color[<color[10,0,0]>]> <element[｜ 100].color[<color[101,0,0]>]>"
  - define health_icon <element[<&chr[C004].font[icons]><proc[spacing].context[1]>].color[<color[10,0,0]>]>
  - define health_     <[health_icon]><[health_bar]><[health_text]>

  - define shield      <player.armor_bonus.mul[5].round>
  - define shield_r    <[shield].div[100].mul[255].round_down>
  - define shield_bar  <[empty_bar].color[<[shield_r]>,0,1]>
  - define shield_text "<element[<proc[spacing].context[-215]><[shield]>].color[<color[11,0,0]>]> <element[｜ 100].color[<color[111,0,0]>]>"
  - define shield_icon <element[<&chr[C003].font[icons]><proc[spacing].context[1]>].color[<color[11,0,0]>]>
  - define shield_     <[shield_icon]><[shield_bar]><[shield_text]>

  # - [ Inventory / Builds ] - #
  #in case they were already defined by outside scripts
  - if !<[new_slot].exists> || !<[old_slot].exists>:
    - define new_slot <player.held_item_slot>
    - define old_slot <[new_slot]>
  - inject hud_handler.update_slots

  # - [ Materials ] - #
  - define selected_material none
  - if <player.has_flag[build.material]>:
    - define selected_material <player.flag[build.material]>

  - foreach <list[wood|brick|metal]> as:mat:

    - define mat_icon   <&chr[A00<[loop_index]>].font[icons]>
    - if <[selected_material]> == <[mat]>:
      - define mat_icon <&chr[A0<[loop_index]><[loop_index]>].font[icons]>

    - define mat_qty   <player.flag[fort.<[mat]>.qty]||null>
    - define mat_qty   <[override_qty.<[mat]>]> if:<[override_qty.<[mat]>].exists>

    - define mat_text  <&sp.repeat[<element[3].sub[<[mat_qty].length>]>]><[mat_qty].font[hud_text]>
    - define <[mat]>_  <element[<[mat_icon]><proc[spacing].context[-32]><[mat_text]>].color[<color[4<[loop_index]>,0,0]>]>

  # - [ Stats ] - #
  - define fall_icon  <&chr[0003].font[icons]>
  - define storm_icon <&chr[0005].font[icons]>
  - define clock_icon <&chr[0004].font[icons]>
  - define time       <element[0:00].font[hud_text]>
  - define time_      <element[<[clock_icon]> <[time]>].color[<color[50,0,0]>]>

  - define alive_icon <&chr[0002].font[icons]>
  - define alive      <element[100].font[hud_text]>
  - define alive_     <element[<[alive_icon]> <[alive]>].color[<color[51,0,0]>]>

  - define kills      <element[0].font[hud_text]>
  - define kills_icon <&chr[0001].font[icons]>
  - define kills_     <element[<[kills_icon]> <[kills]>].color[<color[52,0,0]>]>

  # - [ Team Health Bars ] - #
  - define small_health_bar <&chr[C001].font[icons]>
  - define small_shield_bar <&chr[C002].font[icons]>

  - define name <player.name>
  - define small_bar <[small_health_bar].color[<color[<[health_r]>,1,0]>]><proc[spacing].context[-106]><[small_shield_bar].color[<color[<[shield_r]>,1,1]>]>
  - define team_bars <[small_bar]><element[<proc[spacing].context[-106]><[name]>].color[<color[61,0,0]>]>

  - sidebar set title:<empty> values:<[ammo_]>|<[shield_]>|<[health_]>|<[build_]>|<[slots_]>|<[wood_]>|<[brick_]>|<[metal_]>|<[time_]>|<[alive_]>|<[kills_]>|<[team_bars]>|<proc[spacing].context[500]>

  - inject hud_handler.update_inventory

hud_handler:
  type: world
  debug: false
  events:


    after player scrolls their hotbar:
    - stop if:<player.world.name.equals[fortnite_map].not>
    - define new_slot <context.new_slot>
    - define old_slot <context.previous_slot>

    - inject update_hud

    - if <player.item_in_hand.script.name.starts_with[gun].not||true>:
      - stop
    - define gun      <player.item_in_hand>
    - define gun_uuid <[gun].flag[uuid]>
    - if <server.flag[fort.temp.<[gun_uuid]>.loaded_ammo]> == 0:
      - run fort_gun_handler.reload def:<map[gun=<[gun]>]>

    on player swaps items:
    - stop if:<player.world.name.equals[fortnite_map].not>
    - determine passively cancelled
    - define new_type <map[inv=build;build=inv].get[<player.flag[fort.inv_type]||inv>]>
    - flag player fort.inv_type:<[new_type]>

    - run build_toggle

    - inject update_hud

  update_inventory:

  - define drop_text "<&r><n><&9><&l>Left-Click <&f>to drop one.<n><&c><&l>Right-Click <&f>to drop multiple."

  #resources
  - foreach <list[wood|brick|metal]> as:mat:
    - define slot <[loop_index].add[18]>
    - if !<player.has_flag[fort.<[mat]>.qty]> || <player.flag[fort.<[mat]>.qty]> == 0:
      - inventory set o:air slot:<[slot]>
      - foreach next
    - define name <[mat].to_uppercase.bold>
    - define lore <list[<&7>Qty: <&f><player.flag[fort.<[mat]>.qty]>|<[drop_text]>]>
    - define item <item[paper].with[display=<[name]>;lore=<[lore]>;custom_model_data=<[loop_index].add[7]>;flag=type:material;flag=mat:<[mat]>]>
    - inventory set o:<[item]> slot:<[slot]>

  #ammo
  - foreach <list[light|medium|heavy|shells|rockets]> as:ammo_type:
    - define slot <[loop_index].add[22]>
    - if !<player.has_flag[fort.ammo.<[ammo_type]>]> || <player.flag[fort.ammo.<[ammo_type]>]> == 0:
      - inventory set o:air slot:<[slot]>
      - foreach next
    - define name <[ammo_type].to_uppercase.bold>
    - define lore <list[<&7>Qty: <&f><player.flag[fort.ammo.<[ammo_type]>]>|<[drop_text]>]>
    - define item <item[paper].with[display=<[name]>;lore=<[lore]>;custom_model_data=<[loop_index].add[11]>;flag=type:ammo;flag=ammo_type:<[ammo_type]>]>
    - inventory set o:<[item]> slot:<[slot]>



  update_slots:
  #-have a icon for opening the full map?
  #required definitions:
  # <[new_slot]>
  # <[old_slot]>
    - define slot <[new_slot]>

    - define inv_type <player.flag[fort.inv_type]||inv>

    - define unselected_slot     <&chr[B000].font[icons]>
    - define selected_slot       <&chr[B001].font[icons]>

    - define wall                <&chr[D001].font[icons]>
    - define floor               <&chr[D002].font[icons]>
    - define stair               <&chr[D003].font[icons]>
    - define pyramid             <&chr[D004].font[icons]>

    - define backdrop <&chr[A000].font[buttons]>

    - if <[inv_type]> == inv:
      - if <[new_slot]> > 6:
        - define slot <[old_slot].is_more_than[3].if_true[1].if_false[6]>
        - adjust <player> item_slot:<[slot]>
      - define slots  <[unselected_slot].repeat_as_list[6]>
      - define backdrop <&chr[A000].font[buttons]>
      - define keys:!
      - define count 6
      - define spacing 42
      - repeat <[count]>:
        - define k <&keybind[key.hotbar.<[value]>]>
        - define keys:->:<[backdrop]><proc[spacing].context[-9]><[k].font[neg_half_f]><[k].font[visitor]><[k].font[neg_half_c]>

      - define keys <proc[spacing].context[-<[count].mul[16].add[<[spacing].mul[<[count]>]>]>]><[keys].separated_by[<proc[spacing].context[<[spacing].add[1]>]>].color[<color[69,0,0]>]>

      - define k <&keybind[key.swapOffhand]>
      - define build_toggle <[backdrop]><proc[spacing].context[-9]><[k].font[neg_half_f]><[k].font[visitor]><[k].font[neg_half_c]><proc[spacing].context[9]>

      - define slots_ <[slots].set[<[selected_slot]>].at[<[slot]>].space_separated.color[<color[20,0,0]>]><[keys]>
      - define build_ <[build_toggle].color[68,0,0]><proc[spacing].context[-17]><element[<[wall]> <[floor]> <[stair]> <[pyramid]> <[unselected_slot]>].color[<color[30,0,0]>]>

    - else if <[inv_type]> == build:
      - if <[new_slot]> > 5:
        - define slot <[old_slot].is_more_than[3].if_true[1].if_false[5]>
        - adjust <player> item_slot:<[slot]>
      - define wall_sel       <&chr[D011].font[icons]>
      - define floor_sel      <&chr[D022].font[icons]>
      - define stair_sel      <&chr[D033].font[icons]>
      - define pyramid_sel    <&chr[D044].font[icons]>
      - define selection      <map[1=<[wall_sel]>;2=<[floor_sel]>;3=<[stair_sel]>;4=<[pyramid_sel]>;5=<[selected_slot]>].get[<[slot]>]>
      - define build_slots    <list[<[wall]>|<[floor]>|<[stair]>|<[pyramid]>|<[unselected_slot]>].set[<[selection]>].at[<[slot]>]>

      - define keys:!
      - define count 5
      - define spacing 42
      - repeat <[count]>:
        - define k <&keybind[key.hotbar.<[value]>]>
        - define keys:->:<[backdrop]><proc[spacing].context[-9]><[k].font[neg_half_c]><&l><[k].font[visitor]><&r><[k].font[neg_half_f]>

      - define keys <proc[spacing].context[-<[count].mul[16].add[<[spacing].mul[<[count]>]>]>]><[keys].separated_by[<proc[spacing].context[<[spacing]>]>].color[<color[67,0,0]>]>

      - define inv_toggle   <&chr[A001].font[buttons].color[<color[70,0,0]>]>

      - define build_         <[build_slots].space_separated.color[<color[30,0,0]>]><[keys]>
      - define slots_         <[inv_toggle]><proc[spacing].context[-17]><[unselected_slot].repeat_as_list[6].space_separated.color[<color[20,0,0]>]>

      #being handled in build_toggle now
      #trap
      #- if <[slot]> == 5:
        #- equip offhand:air hand:air
      #- else:
        #- inventory clear
        #- equip offhand:<item[paper].with[custom_model_data=<[slot].add[3]>]>
        #slot hand changes, so give it to the next slot
        #- give <item[gold_nugget].with[custom_model_data=10]> slot:<[slot]>

    #- sidebar set_line scores:8|9 values:<[slots_]>|<[build_]>