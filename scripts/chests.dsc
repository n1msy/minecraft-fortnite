fort_chest_handler:
  type: world
  debug: false
  definitions: data
  events:
    on player breaks block location_flagged:fort.chest:
    - define loc <context.location>
    - remove <[loc].flag[fort.chest]> if:<[loc].flag[fort.chest].is_spawned>
    - remove <[loc].flag[fort.chest_text]> if:<[loc].flag[fort.chest_text].is_spawned>
    #is this safe to do? (what if there was another flag in the same loc?)
    - flag <[loc]> fort:!

  open:
  #required definitions: look_loc
  - define text_display <[look_loc].flag[fort.chest_text]>
  - define chest        <[look_loc].flag[fort.chest]>
  - spawn TEXT_DISPLAY[text=■;pivot=center;display=left;scale=1,1,1;view_range=0.035;see_through=true;width=10;hide_from_players=true] <[text_display].location.below[0.022]> save:load_bar
  - define bar <entry[load_bar].spawned_entity>
  - adjust <player> show_entity:<[bar]>
  - while <player.is_online> && <player.is_sneaking> && <[look_loc].has_flag[fort.chest]> && !<[look_loc].has_flag[fort.opened]> && <[text_display].is_spawned>:
    - define look_loc <player.eye_location.ray_trace[return=block;range=2.7;default=air]>
    - adjust <[bar]> scale:<[loop_index]>,0.25,0.25
    - if <[loop_index]> == 10:
      - define open_chest True
      - while stop
    - wait 1t
  - remove <[bar]> if:<[bar].is_spawned>
  - stop if:<[open_chest].exists.not>

  - playsound <[chest].location> sound:BLOCK_CHEST_OPEN volume:0.5 pitch:1
  - playsound <[chest].location> sound:BLOCK_AMETHYST_CLUSTER_BREAK pitch:0.85 volume:2

  chest_fx:
  - define loc <[data].get[loc]>
  - define circle_center <[loc].below[0.5]>
  - define circle        <[circle_center].points_around_y[radius=1;points=45]>
  - define gold_shine    <[loc].forward[0.4].below[0.1]>
  - while <[loc].has_flag[fort.chest]>:
    - if <[loop_index].mod[5]> == 0:
      - playsound <[loc]> sound:BLOCK_AMETHYST_BLOCK_CHIME pitch:1.5 volume:0.75
    #- if <[loop_index].mod[2]> == 0:
    - playeffect at:<[gold_shine]> effect:DUST_COLOR_TRANSITION offset:0.22,0,0 quantity:15 special_data:1|<color[#ffc02e]>|<color[#fff703]>
    - wait 4t
    #- playeffect effect:INSTANT_SPELL at:<[circle].get[<[loop_index].mod[45].add[1]>]> offset:0 visibility:10
    #- wait 2t