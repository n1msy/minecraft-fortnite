fort_chest_handler:
  type: world
  debug: false
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
  - define text <[text_display].text.font[white]>
  - spawn TEXT_DISPLAY[text=<[text]>;pivot=center;scale=1,1,1;view_range=0.035;see_through=true;height=0;hide_from_players=true] <[text_display].location.below[0.022]> save:load_bar
  - define bar <entry[load_bar].spawned_entity>
  - adjust <player> show_entity:<[bar]>
  - while <player.is_online> && <player.is_sneaking> && <[look_loc].has_flag[fort.chest]> && !<[look_loc].has_flag[fort.opened]> && <[text_display].is_spawned>:
    - define look_loc <player.eye_location.ray_trace[return=block;range=2.7;default=air]>
    #- adjust <[bar]> scale:<[loop_index].div[10]>,0.25,0.25
    #s- adjust <[bar]> translation:-<[loop_index].div[100]>,0,0
    - wait 1t
  - remove <[bar]> if:<[bar].is_spawned>