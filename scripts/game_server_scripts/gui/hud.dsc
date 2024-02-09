#-basically everything that's not the map

##update every element of the hud every time, or just isolate things to update?

##im starting to think i should isolate to improve performance, not sure though

#-Hud Sidebar Layout
#- 1: (spacing)
#- 2: Small bars (top left)
#- 3: Kills
#- 4: Alive
#- 5: Time
#- 6: Metal
#- 7: Brick
#- 8: Wood
#- 9: Slots
#- 10: Build
#- 11: Health
#- 12: Shield
#- 13: Ammo

#TODO: cache spectator data in flags instead of constantly regenerating spectators list

#ie update_slots, update_mats, update_health
update_hud:
  type: task
  debug: false
  script:

    #update everything (to setup the first time)
    - run update_hud.ammo
    - run update_hud.health
    - run update_hud.hotbar
    - run update_hud.materials
    - run update_hud.timer
    - run update_hud.alive
    - run update_hud.kills
    - run update_hud.spacing

  ammo:
    # - [ Ammo ] - #
    #depends on what gun you're holding
    - define ammo_ <&sp>
    - if <player.item_in_hand.script.name.starts_with[gun_]||false>:
      - define gun_uuid      <player.item_in_hand.flag[uuid]>
      - define ammo_type     <player.item_in_hand.flag[ammo_type]>
      - define loaded_ammo   <server.flag[fort.temp.<[gun_uuid]>.loaded_ammo]||0>
      - define total_ammo    <player.flag[fort.ammo.<[ammo_type]>]||0>
      - define ammo_icon     <&chr[E00<map[light=1;medium=2;heavy=3;shells=4;rockets=5].get[<[ammo_type]>]>].font[icons]>
      - define ammo_text    "<element[<[loaded_ammo]> / <[total_ammo]>].font[ammo_text]> <[ammo_icon]>"
      - define ammo_         <[ammo_text].color[<color[12,0,0]>]>

    - define shared_players <server.online_players_flagged[fort.spectating].filter[flag[fort.spectating].equals[<player>]].include[<player>]>
    - sidebar set_line scores:13 values:<[ammo_]> players:<[shared_players]>

  health:

    # - [ Main Health/Shield Bars ] - #
    - define name      <player.name>
    - define empty_bar <&chr[C000].font[icons]>
    - define health      <player.health.mul[5].round>
    - if <[health]> > 100:
      - announce to_console "<&b>[Nimnite <&f>-<&gt> <&c>Error <&f>]<&r> <[name]><&r>'s <&a>health<&r> exceeded 100 (<&c><[health]><&r>). Fixing..."
      - adjust <player> max_health:20
      - define health 100
    - define health_r    <[health].div[100].mul[255].round_down>
    - define health_bar  <[empty_bar].color[<[health_r]>,0,2]>
    - define health_text "<element[<proc[spacing].context[-215]><[health]>].color[<color[10,0,0]>]> <element[｜ 100].color[<color[101,0,0]>]>"
    - define health_icon <element[<&chr[C004].font[icons]><proc[spacing].context[1]>].color[<color[10,0,0]>]>
    - define health_     <[health_icon]><[health_bar]><[health_text]>
    #shield
    - define shield      <player.armor_bonus.mul[5].round>
    - if <[shield]> > 100:
      - announce to_console "<&b>[Nimnite <&f>-<&gt> <&c>Error<&b>]<&r> <[name]><&r>'s <&b>shield<&r> exceeded 100 (<&c><[shield]><&r>). Fixing..."
      - adjust <player> armor_bonus:20
      - define shield 100
    - define shield_r    <[shield].div[100].mul[255].round_down>
    - define shield_bar  <[empty_bar].color[<[shield_r]>,0,1]>
    - define shield_text "<element[<proc[spacing].context[-215]><[shield]>].color[<color[11,0,0]>]> <element[｜ 100].color[<color[111,0,0]>]>"
    - define shield_icon <element[<&chr[C003].font[icons]><proc[spacing].context[1]>].color[<color[11,0,0]>]>
    - define shield_     <[shield_icon]><[shield_bar]><[shield_text]>

    # - [ Team Health Bars ] - #
    - define small_health_bar <&chr[C001].font[icons]>
    - define small_shield_bar <&chr[C002].font[icons]>

    - define small_bar <[small_health_bar].color[<color[<[health_r]>,1,2]>]><proc[spacing].context[-106]><[small_shield_bar].color[<color[<[shield_r]>,1,1]>]>
    - define team_bars <[small_bar]><element[<proc[spacing].context[-106]><[name]>].color[<color[61,0,0]>]>

    - define shared_players <server.online_players_flagged[fort.spectating].filter[flag[fort.spectating].equals[<player>]].include[<player>]>
    - sidebar set_line scores:12|11|2 values:<[shield_]>|<[health_]>|<[team_bars]> players:<[shared_players]>

  hotbar:

    # - [ Inventory / Builds ] - #
    #in case it was defined by "scrolls" event

    - if !<[new_slot].exists> || !<[old_slot].exists>:
      - define new_slot <player.held_item_slot>
      - define old_slot <[new_slot]>

    - define shared_players <server.online_players_flagged[fort.spectating].filter[flag[fort.spectating].equals[<player>]].include[<player>]>
    - inject hud_handler.update_slots

    - sidebar set_line scores:10|9 values:<[build_]>|<[slots_]> players:<[shared_players]>

  materials:

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

    - define shared_players <server.online_players_flagged[fort.spectating].filter[flag[fort.spectating].equals[<player>]].include[<player>]>
    - sidebar set_line scores:8|7|6 values:<[wood_]>|<[brick_]>|<[metal_]> players:<[shared_players]>

  timer:

    # - [ Timer ] - #
    - choose <server.flag[fort.temp.phase]||null>:
      - case bus:
        #bus icon
        - define timer_icon <&chr[0025].font[icons]>
      - case fall:
        #fall icon
        - define timer_icon <&chr[0003].font[icons]>
      - case grace_period:
        #storm icon
        - define timer_icon <&chr[B005].font[icons]>
      - case storm_shrink:
        - define timer_icon <&chr[0005].font[icons]>
        #clock icon
      - default:
        - define timer_icon <&chr[0004].font[icons]>
    - define timer       <server.flag[fort.temp.timer].if_null[-].font[hud_text]>
    - define time_      <element[<[timer_icon]> <[timer]>].color[<color[50,0,0]>]>

    - define shared_players <server.online_players_flagged[fort.spectating].filter[flag[fort.spectating].equals[<player>]].include[<player>]>
    - sidebar set_line scores:5 values:<[time_]> players:<[shared_players]>

  alive:
    # - [ Players Alive ] - #
    - define alive_icon <&chr[0002].font[icons]>
    #- define alive      <element[-].font[hud_text]>
    - define alive      <element[<server.online_players_flagged[!fort.spectating].size>].font[hud_text]>
    - define alive_     <element[<[alive_icon]> <[alive]>].color[<color[51,0,0]>]>

    - define shared_players <server.online_players_flagged[fort.spectating].filter[flag[fort.spectating].equals[<player>]].include[<player>]>
    - sidebar set_line scores:4 values:<[alive_]> players:<[shared_players]>

  kills:
    # - [ Kills ] - #
    - define kills      <element[<player.flag[fort.kills]||->].font[hud_text]>
    - define kills_icon <&chr[0001].font[icons]>
    - define kills_     <element[<[kills_icon]> <[kills]>].color[<color[52,0,0]>]>

    - define shared_players <server.online_players_flagged[fort.spectating].filter[flag[fort.spectating].equals[<player>]].include[<player>]>
    - sidebar set_line scores:3 values:<[kills_]> players:<[shared_players]>

  spacing:
   # - [ Correctly offsets the hud ] - #
   #should only be run once during setup

  #we dont really need shared players for this, but all g (we might for spectators)
  - define shared_players <server.online_players_flagged[fort.spectating].filter[flag[fort.spectating].equals[<player>]].include[<player>]>
  - sidebar set_line scores:1 values:<proc[spacing].context[500]> players:<[shared_players]>

hud_handler:
  type: world
  debug: false
  events:

    #-INVENTORY LOCKS ADJUSTED IN "global_events.dsc"
    #only let players change item locations within the 2-6 slots

    on player scrolls their hotbar:
    - if <player.has_flag[fort.using_glider]> || <player.has_flag[fort.spectating]>:
      - determine passively cancelled
      - stop

    - if <player.has_flag[fort.on_bus]> && <script[nimnite_config].data_key[bus_view_mode]> == 2:
      - determine passively cancelled
      - wait 1t
      #in case they cheese / spam it and somehow get out
      - adjust <player> item_slot:9
      - stop

    #(added wait instead of using after in event, so i can cancel event if necessary)
    - wait 1t

    - define new_slot <context.new_slot>
    - define old_slot <context.previous_slot>
    #dont use run, because new_slot and old_slot is defined
    - inject update_hud.hotbar

    - if <player.item_in_hand.script.name.starts_with[gun].not||true>:
      - stop

    # - [ Auto Reload if the player's gun is out of ammo ] - #
    - define gun      <player.item_in_hand>
    - define gun_uuid <[gun].flag[uuid]>
    - if <server.flag[fort.temp.<[gun_uuid]>.loaded_ammo]> == 0:
      - run fort_gun_handler.reload def:<map[gun=<[gun]>;auto_reload=true]>

  update_slots:
  #-have a icon for opening the full map?
  #required definitions:
  # <[new_slot]>
  # <[old_slot]>
    - define slot <[new_slot]>

    #so it doesn't change to the slot the glider is in
    - define slot <player.flag[fort.using_glider.previous_slot]> if:<player.has_flag[fort.using_glider]>

    - define inv_type <player.flag[fort.inv_type]||inv>
    - if <[inv_type]> == inv:
      - define inv_items <player.inventory.list_contents>
    - else:
      - define inv_items <player.flag[build.last_inventory]>

    - define common              <&chr[0001].font[rarities]>
    - define common_selected     <&chr[A001].font[rarities]>
    - define uncommon            <&chr[0002].font[rarities]>
    - define uncommon_selected   <&chr[A002].font[rarities]>
    - define rare                <&chr[0003].font[rarities]>
    - define rare_selected       <&chr[A003].font[rarities]>
    - define epic                <&chr[0004].font[rarities]>
    - define epic_selected       <&chr[A004].font[rarities]>
    - define legendary           <&chr[0005].font[rarities]>
    - define legendary_selected  <&chr[A005].font[rarities]>

    - define unselected_slot     <&chr[B000].font[icons]>
    - define selected_slot       <&chr[B001].font[icons]>

    - define wall                <&chr[D001].font[icons]>
    - define floor               <&chr[D002].font[icons]>
    - define stair               <&chr[D003].font[icons]>
    - define pyramid             <&chr[D004].font[icons]>

    - define backdrop <&chr[A000].font[buttons]>

    - if <[inv_type]> == inv && <[new_slot]> > 6:
      - define slot <[old_slot].is_more_than[3].if_true[1].if_false[6]>
      - adjust <player> item_slot:<[slot]>

    - define slots <[unselected_slot].repeat_as_list[6]>

    #this puts all the correct items and item rarities in the custom hotbar
    #maybe in the future somehow isolate all the items / find a way to not have to "reset" every time?
    - inject hud_handler.fill_custom_hotbar

    ## [ Inventory Mode ] ##
    - if <[inv_type]> == inv:
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

      #-in case the player is holding nothing (skip the "nothing" slot, or let them select it?)
      - define slots <[slots].set[<[selected_slot]>].at[<[slot]>]> if:!<[item_selected].exists>

      - define slots_ <[slots].space_separated.color[<color[20,0,0]>]><[keys]>
      - define build_ <[build_toggle].color[68,0,0]><proc[spacing].context[-17]><element[<[wall]> <[floor]> <[stair]> <[pyramid]> <[unselected_slot]>].color[<color[30,0,0]>]>

    ## [ Build Mode ] ##
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

      - define k            <&keybind[key.swapOffhand]>
      - define inv_toggle   <element[<[backdrop]><proc[spacing].context[-9]><[k].font[neg_half_f]><[k].font[visitor]><[k].font[neg_half_c]><proc[spacing].context[9]>].color[70,0,0]>

      - define build_         <[build_slots].space_separated.color[<color[30,0,0]>]><[keys]>
      - define slots_         <[inv_toggle]><proc[spacing].context[-17]><[slots].space_separated.color[<color[20,0,0]>]>


  fill_custom_hotbar:
    #still do the fill_slots when in build mode? (it shows the rarities in the inv, but not the items)

    - define rarity_list <list[common|uncommon|rare|epic|legendary]>

    - repeat 6:
      #in case there's nothing afterwards
      - if <[inv_items].get[<[value]>]||null> == null:
        #set the rarity slot to nothing
        - repeat stop
  
      #put in the item with the right rarity
      - if <[inv_items].get[<[value]>].has_flag[rarity]>:
        - define item   <[inv_items].get[<[value]>]>
        - define icon_chr <[item].flag[icon_chr]>
        - define rarity <[item].flag[rarity]>
        - define qty    <[item].quantity>
        - define s_name <[item].script.name>

        ## [ Player Inventory Slots ] ##
        #in case it's an item with different models per rarity
        - if <[item].has_flag[rarities.<[rarity]>.icon_chr]>:
          - define icon_chr <[item].flag[rarities.<[rarity]>.icon_chr]>

        - if <[s_name].starts_with[gun_]>:
          - define font_type guns
          - define gun_uuid  <[item].flag[uuid]>
          #-check in the future why i need this fallback (it errors if i dont use it)
          #show how much ammy in hotbar slot
          - define qty       <server.flag[fort.temp.<[gun_uuid]>.loaded_ammo]||0>
        - else if <[s_name].starts_with[fort_pickaxe_]>:
          - define font_type pickaxes
        - else:
          - define font_type items

        #if the current selected slot is the item, make it the selected one
        - if <[value]> == <[slot]> && <[inv_type]> == inv:
          - define qty_font_type item_qty_selected
          - define rarity_slot   <[<[rarity]>_selected]>
          - define chr           A<element[0].repeat[<element[3].sub[<[icon_chr].length>]>]><[icon_chr]>
          - define icon          <&chr[<[chr]>].font[<[font_type]>]>
          - define item_selected True
        - else:
          - define qty_font_type item_qty
          - define icon          <&chr[<[icon_chr]>].font[<[font_type]>]>
          - define rarity_slot <[<[rarity]>]>

        - define display_quantity <[qty].font[neg_half_f]><[qty].font[<[qty_font_type]>]><[qty].font[neg_half_c]>
        - if <[font_type]> == pickaxes:
          - define display_quantity <empty>

        - define qty_spacing <[qty].is[OR_MORE].than[10].if_true[12].if_false[8]>
        - define item_slot <[rarity_slot]><proc[spacing].context[-47]><[icon]><proc[spacing].context[-<[qty_spacing]>]><[display_quantity]><proc[spacing].context[<[qty_spacing]>]>
        - define slots <[slots].set[<[item_slot]>].at[<[value]>]>