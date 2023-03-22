
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
  - define ammo_icon "[ammo icon]"
  - define ammo_     <element[<element[<[ammo_current]> / <[ammo_max]>].font[ammo_text]> <[ammo_icon]>].color[<color[12,0,0]>]>

  - define empty_bar <&chr[C000].font[icons]>

  # - [ Main Health/Shield Bars ] - #
  - define health      100
  - define health_bar  <[empty_bar]>
  - define health_icon []
  - define health_     <element[<[health_icon]><[health_bar]><[health]>].color[<color[10,0,0]>]>

  - define shield      100
  - define shield_bar  <&chr[C000].font[icons]>
  - define shield_icon []
  - define shield_     <element[<[shield_icon]><[shield_bar]><[shield]>].color[<color[11,0,0]>]>

  # - [ Inventory ] - #
  - define empty_slot     <&chr[B000].font[icons]>
  - define selected_slot  <&chr[B001].font[icons]>
  - define slots          <[empty_slot].repeat_as_list[6].space_separated>
  - define slots_         <[slots].color[<color[20,0,0]>]>

  # - [ Builds ] - #
  - define build_slots    <[empty_slot].repeat_as_list[5].space_separated>
  - define build_         <[build_slots].color[<color[30,0,0]>]>

  # - [ Materials ] - #
  - define wood_icon  <&chr[A001].font[icons]>
  - define wood_qty   999
  - define wood       <&sp.repeat[<element[3].sub[<[wood_qty].length>]>]><[wood_qty].font[hud_text]>
  - define wood_      <element[<[wood_icon]><&chr[F801].font[denizen:overlay].repeat[24]><[wood]>].color[<color[41,0,0]>]>

  - define brick_icon <&chr[A002].font[icons]>
  - define brick_qty  999
  - define brick      <&sp.repeat[<element[3].sub[<[brick_qty].length>]>]><[brick_qty].font[hud_text]>
  - define brick_     <element[<[brick_icon]><&chr[F801].font[denizen:overlay].repeat[24]><[brick]>].color[<color[42,0,0]>]>

  - define metal_icon <&chr[A003].font[icons]>
  - define metal_qty  999
  - define metal      <&sp.repeat[<element[3].sub[<[metal_qty].length>]>]><[metal_qty].font[hud_text]>
  - define metal_     <element[<[metal_icon]><&chr[F801].font[denizen:overlay].repeat[24]><[metal]>].color[<color[43,0,0]>]>

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
  - define small_bar <[small_health_bar]><&chr[F801].font[denizen:overlay].repeat[106]><[small_shield_bar]>
  - define team_bars <element[<[small_bar]><&chr[F801].font[denizen:overlay].repeat[106]><[name]>].color[<color[61,0,0]>]>

  - sidebar set title:<empty> values:<[ammo_]>|<[shield_]>|<[health_]>|<[build_]>|<[slots_]>|<[wood_]>|<[brick_]>|<[metal_]>|<[time_]>|<[alive_]>|<[kills_]>|<[team_bars]>