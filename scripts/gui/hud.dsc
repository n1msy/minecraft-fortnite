
###use shaders for health bar instead of repeating values (input the health in r values)

#-basically everything that's not the map
update_hud:
  type: task
  debug: false
  script:

  #falling icon turns to clock icon after bus is done dropping

  # - [ Ammo ] - #
  #depends on what gun you're holding
  - define ammo_current 20
  - define ammo_max 291
  - define ammo_icon <&chr[E002].font[icons]>
  - define ammo_     <element[<element[<[ammo_current]> / <[ammo_max]>].font[ammo_text]> <[ammo_icon]>].color[<color[12,0,0]>]>

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
  - define wood_icon  <&chr[A001].font[icons]>
  - define wood_qty   999
  - define wood       <&sp.repeat[<element[3].sub[<[wood_qty].length>]>]><[wood_qty].font[hud_text]>
  - define wood_      <element[<[wood_icon]><proc[spacing].context[-32]><[wood]>].color[<color[41,0,0]>]>

  - define brick_icon <&chr[A002].font[icons]>
  - define brick_qty  999
  - define brick      <&sp.repeat[<element[3].sub[<[brick_qty].length>]>]><[brick_qty].font[hud_text]>
  - define brick_     <element[<[brick_icon]><proc[spacing].context[-32]><[brick]>].color[<color[42,0,0]>]>

  - define metal_icon <&chr[A003].font[icons]>
  - define metal_qty  999
  - define metal      <&sp.repeat[<element[3].sub[<[metal_qty].length>]>]><[metal_qty].font[hud_text]>
  - define metal_     <element[<[metal_icon]><proc[spacing].context[-32]><[metal]>].color[<color[43,0,0]>]>

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

  - sidebar set title:<empty> values:<[ammo_]>|<[shield_]>|<[health_]>|<[build_]>|<[slots_]>|<[wood_]>|<[brick_]>|<[metal_]>|<[time_]>|<[alive_]>|<[kills_]>|<[team_bars]>

hud_handler:
  type: world
  debug: false
  events:
    on player scrolls their hotbar:

    - define new_slot <context.new_slot>
    - define old_slot <context.previous_slot>

    - inject update_hud

    on player swaps items:
    - determine passively cancelled
    - define new_type <map[inv=build;build=inv].get[<player.flag[fort.inv_type]||inv>]>
    - flag player fort.inv_type:<[new_type]>

    - define old_slot <player.held_item_slot>
    - adjust <player> item_slot:1
    - define new_slot 1

    - inject update_hud

    - run build_toggle

    after player damaged:
    - inject update_hud

    on player heals:
    - determine cancelled
  update_slots:
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

    - if <[inv_type]> == inv:
      - if <[new_slot]> > 6:
        - define slot <[old_slot].is_more_than[3].if_true[1].if_false[6]>
        - adjust <player> item_slot:<[slot]>
      - define slots               <[unselected_slot].repeat_as_list[6]>

      - define slots_              <[slots].set[<[selected_slot]>].at[<[slot]>].space_separated.color[<color[20,0,0]>]>
      - define build_ <element[<[wall]> <[floor]> <[stair]> <[pyramid]> <[unselected_slot]>].color[<color[30,0,0]>]>

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

      - define build_         <[build_slots].space_separated.color[<color[30,0,0]>]>
      - define slots_         <[unselected_slot].repeat_as_list[6].space_separated.color[<color[20,0,0]>]>

    #- sidebar set_line scores:8|9 values:<[slots_]>|<[build_]>