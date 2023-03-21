
###use shaders for health bar instead of repeating values (input the health in r values)

#-basically everything that's not the map
update_hud:
  type: task
  debug: false
  script:


  #top left health bars (they're different):
  #shield - ◼
  #health - ■

  #main health:
  #shield/health - ⬛ or <element[█].font[hud_text]>

  #falling icon turns to clock icon after bus is done dropping

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

  - define wood_icon  <&chr[A001].font[icons]>
  - define wood       <element[100].font[hud_text]>
  - define wood_      <[wood_icon]><[wood]>

  - define brick_icon <&chr[A002].font[icons]>
  - define brick      <element[100].font[hud_text]>
  - define brick_     <[brick_icon]><[brick]>

  - define metal_icon <&chr[A003].font[icons]>
  - define metal      <element[100].font[hud_text]>
  - define metal_     <[metal_icon]><[metal]>

  - define empty_slot     <&chr[B000].font[icons]>
  - define selected_slot  <&chr[B001].font[icons]>
  - define slots         "<[empty_slot]> <[empty_slot].repeat_as_list[5].unseparated>"

  - define build_slots   "<[empty_slot].repeat_as_list[4].unseparated> <[empty_slot]>"

  - define empty_bar <&chr[C000].font[icons]>

  - define health     100
  - define health_bar <element[█].font[hud_text].repeat[10]>
  - define health_    <[health]><[health_bar]>

  - define shield     100
  - define shield_bar <element[█].font[hud_text].repeat[100]><[health]>
  - define shield_    <[shield]><[shield_bar]>

  - sidebar set title:test values:10000000<[empty_bar]>|<[build_slots]>|<[slots]>|<[wood_]>|<[brick_]>|<[metal_]>|<[time_]>|<[alive_]>|<[kills_]>