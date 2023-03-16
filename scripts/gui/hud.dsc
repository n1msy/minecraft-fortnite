
#TODO: to fix aligning issues for when numbers change, just make the "stats" separate lines each 

#-basically everything that's not the map
update_hud:
  type: task
  debug: false
  script:

  #falling icon turns to clock icon after bus is done dropping

  - define time <element[0:00].font[hud_text]>

  - define fall_icon <&chr[0003].font[icons]>
  - define clock_icon <&chr[0004].font[icons]>
  - define storm_icon <&chr[0005].font[icons]>

  - define alive <element[100].font[hud_text]>
  - define alive_icon <&chr[0002].font[icons]>

  - define kills <element[0].font[hud_text]>
  - define kills_icon <&chr[0001].font[icons]>

  - define stats <element[<[clock_icon]> <[time]> <[alive_icon]> <[alive]> <[kills_icon]> <[kills]>].color[<color[50,0,0]>]>

  #- if !<player.bossbar_ids.contains[stats]>:
  #  - bossbar create stats

  #- bossbar update stats title:<[stats]>

  - sidebar set title:test values:1|2|3|4|<[stats]>