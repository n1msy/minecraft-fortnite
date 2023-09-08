fort_lobby_setup:
  type: task
  debug: false
  script:

    - if <server.flag[fort.menu.play_button_hitbox]>:
      - remove <server.flag[fort.menu.play_button_hitbox]>

    - define loc <player.location.center.with_pose[0,0].forward_flat[3].above[0.1]>

    - spawn <entity[interaction].with[width=2.5;height=1]> <[loc]> save:play_hitbox
    #- spawn <entity[text_display].with[text=<&chr[F000].font[icons]>;pivot=FIXED;scale=1,1,1]> <[loc]> save:play

    - define play_hitbox <entry[play_hitbox].spawned_entity>
    - flag <[play_hitbox]> menu.play_button

    - flag server fort.menu.play_button_hitbox:<[play_hitbox]>


fort_lobby_handler:
  type: world
  debug: false
  definitions: player|button|option
  events:
    on player damages entity flagged:fort.menu.selected_button priority:-10:
    - inject fort_lobby_handler.button_press

    on player join:
    ##############remove this
    - if <player.name> != Nimsy:
      - stop

    #- define uuid <player.uuid>

    #show hud
    - inject update_hud

    #-flag server or player?
    - define play_button_loc <server.flag[fort.menu.play_button_hitbox].location>
    - spawn <entity[item_display].with[item=<item[oak_sign].with[custom_model_data=0]>;scale=3,3,3;brightness=<map[block=15;sky=0]>;hide_from_players=true]> <[play_button_loc].above[0.5]> save:play_button
    - define play_button <entry[play_button].spawned_entity>
    - adjust <player> show_entity:<[play_button]>

    - flag player fort.menu.play_button:<[play_button]>

    #show compass (also updates the menu buttons)
    - run minimap

    on player quit:
    - define uuid <player.uuid>
    - if <player.has_flag[fort.menu]>:
      - define play_button <player.flag[fort.menu.play_button]>
      - remove <[play_button]> if:<[play_button].is_spawned>
      - flag player fort.menu:!

  menu:
    #used in "minimap.dsc"
    - define interaction <player.eye_location.ray_trace_target[entities=interaction;range=10]||null>
    - if <[interaction]> != null && <[interaction].has_flag[menu]>:
      - define button_type <[interaction].flag[menu].keys.first>
      - define selected_button <player.flag[fort.menu.<[button_type]>]>
      #second check is to prevent the while from repeating
      - if !<[selected_button].has_flag[selected]> && !<[selected_button].has_flag[selected_animation]>:
        - flag player fort.menu.selected_button:<[button_type]> duration:2t
        - flag <[selected_button]> selected duration:2t
        - run fort_lobby_handler.select_anim def.button:<[selected_button]>
      - flag player fort.menu.selected_button:<[button_type]> duration:2t
      - flag <[selected_button]> selected duration:2t

    - define play_button <player.flag[fort.menu.play_button]>

    #every 10 seconds
    #loop index, since it's being injected from minimap.dsc
    #first check is because glint cant play when animating
    - if !<[play_button].has_flag[selected]>:
      - if !<player.has_flag[fort.in_queue]> && <[loop_index].div[20].mod[8]> == 0:
        - run fort_lobby_handler.play_button_anim def.button:<[play_button]>

      #- if <[loop_index].mod[2]> == 0:
        #- define angle <[button].location.face[<player.eye_location>].yaw.to_radians>
        #- define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>
        #- adjust <[play_button]> interpolation_start:0
        #- adjust <[play_button]> left_rotation:<[left_rotation]>
        #- adjust <[play_button]> interpolation_duration:2t

  select_anim:
    - define s 3
    - glow <[button]> true
    - define anim_speed 18
    #in case they select it mid-glint anim
    - if !<player.has_flag[fort.in_queue]>:
      - adjust <[button]> item:<item[oak_sign].with[custom_model_data=0]>
    - flag <[button]> selected_animation
    - while <[button].is_spawned> && <[button].has_flag[selected]>:
      - if <[button].has_flag[press_animation]>:
        - wait 1t
        - while next

      - adjust <[button]> interpolation_start:0
      - adjust <[button]> scale:<location[3.35,3.35,3.35]>
      - adjust <[button]> interpolation_duration:<[anim_speed]>t

      #wait 1t to instantly stop
      - repeat <[anim_speed]>:
        - while stop if:!<[button].has_flag[selected]>
        - wait 1t
        - while next if:<[button].has_flag[press_animation]>

      - adjust <[button]> interpolation_start:0
      - adjust <[button]> scale:<location[<[s]>,<[s]>,<[s]>]>
      - adjust <[button]> interpolation_duration:<[anim_speed]>t

      - repeat <[anim_speed]>:
        - while stop if:!<[button].has_flag[selected]>
        - wait 1t
        - while next if:<[button].has_flag[press_animation]>

    - adjust <[button]> scale:<location[<[s]>,<[s]>,<[s]>]>
    - glow <[button]> false
    - flag <[button]> selected_animation:!

  button_press:
    #null fall back is in case the player shoots the interact entity from too far, so there'd be nothing selected
    - define button_type <player.flag[fort.menu.selected_button]||null>
    - stop if:<[button_type].equals[null]>
    - playsound <player> sound:BLOCK_NOTE_BLOCK_HAT pitch:1
    - choose <[button_type]>:
      - case play_button:
        - define button <player.flag[fort.menu.<[button_type]>]>
        - if <player.has_flag[fort.in_queue]>:
          ## [ CANCELLING ] ##

          - run fort_lobby_handler.match_info def.button:<[button]> def.option:remove

          - playsound <player> sound:BLOCK_NOTE_BLOCK_BASS pitch:1
          - flag player fort.in_queue:!
          - define i <item[oak_sign].with[custom_model_data=0]>
        - else:
          ## [ READYING UP ] ##
          #spawn time elapsed text entity
          #check in case they spam
          - if !<player.has_flag[fort.menu.match_info]> || !<player.flag[fort.menu.match_info].is_spawned>:
            - run fort_lobby_handler.match_info def.button:<[button]> def.option:add

          - playsound <player> sound:BLOCK_NOTE_BLOCK_BASS pitch:0
          - define i <item[oak_sign].with[custom_model_data=9]>
          - flag player fort.in_queue
        - run fort_lobby_handler.press_anim def.button:<[button]>
        - adjust <[button]> item:<[i]>

  match_info:
    - define info_display <player.flag[fort.menu.match_info]||null>
    - choose <[option]>:
      - case add:
        - define button_loc <[button].location>
        - define match_info_loc <[button_loc].above[0.55].with_yaw[<[button_loc].yaw.add[180]>]>
        - spawn <entity[text_display].with[text=Finding match...<n>Elapsed: <time[2069/01/01].format[m:ss]>;pivot=FIXED;translation=0,0.25,0;scale=1,0,1;background_color=transparent;hide_from_players=true]> <[match_info_loc]> save:time_elapsed
        - define info_display <entry[time_elapsed].spawned_entity>
        - adjust <player> show_entity:<[info_display]>
        - flag player fort.menu.match_info:<[info_display]>

        - wait 2t

        - adjust <[info_display]> interpolation_start:0
        - adjust <[info_display]> translation:0,0,0
        - adjust <[info_display]> scale:<location[1,1,1]>
        - adjust <[info_display]> interpolation_duration:2t

      - case remove:
        - if <[info_display]> != null && <[info_display].is_spawned>:
          - wait 1t
          - adjust <[info_display]> interpolation_start:0
          - adjust <[info_display]> translation:0,0.25,0
          - adjust <[info_display]> scale:<location[1,0,1]>
          - adjust <[info_display]> interpolation_duration:2t
          - wait 2t
          - remove <[info_display]> if:<[info_display].is_spawned>
        - flag player fort.menu.match_info:!

  play_button_anim:
    - repeat 8:
      #in case the bar is removed
      - if <[button].has_flag[selected]> || !<[button].is_spawned>:
        - stop
      - define i <item[oak_sign].with[custom_model_data=<[value]>]>
      - adjust <[button]> item:<[i]>
      - wait 1t
    - adjust <[button]> item:<item[oak_sign].with[custom_model_data=0]> if:<[button].is_spawned>

  press_anim:
    #speed 1 has a "pressing" anim
    - define speed 2
    - flag <[button]> press_animation duration:4t
    - adjust <[button]> interpolation_start:0
    - adjust <[button]> scale:<location[4,4,4]>
    - adjust <[button]> interpolation_duration:<[speed]>t

    - wait <[speed]>t

    - adjust <[button]> interpolation_start:0
    - adjust <[button]> scale:<location[3,3,3]>
    - adjust <[button]> interpolation_duration:<[speed]>t


