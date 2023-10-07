#-Belongs on LOBBY SERVER

fort_lobby_handler:
  type: world
  debug: false
  definitions: player|button|option|title|size_data
  events:

    on shutdown:
    - define menu_players <server.online_players_flagged[fort.in_menu]>
    - foreach <[menu_players]> as:p:
      - define player_npc     <player.flag[fort.menu.player_npc]>
      - define play_button    <player.flag[fort.menu.play_button]>
      - define mode_button    <player.flag[fort.menu.mode_button]>
      - define vid_button     <player.flag[fort.menu.vid_button]>
      - define match_info     <player.flag[fort.menu.match_info]>
      - define invite_buttons <player.flag[fort.menu.invite_button]>

      - remove <[player_npc]> if:<[player_npc].is_spawned>
      - remove <[play_button]> if:<[play_button].is_spawned>
      - remove <[mode_button]> if:<[mode_button].is_spawned>
      - remove <[vid_button]> if:<[vid_button].is_spawned>
      - remove <[match_info]> if:<[match_info].is_spawned>
      - foreach <[invite_buttons].keys> as:i:
        - define i_button <player.flag[fort.menu.invite_button.<[i]>]>
        - remove <[i_button]> if:<[i_button].is_spawned>

    on server prestart:
    #so only the test server is updated
    - if <bungee.server||null> != null:
      - stop
    - createworld ft24
    - createworld fort_pregame_island
    - createworld fort_map
    - createworld nimnite_map

    #-in case the server crashed/it was incorrectly shut down
    - remove <world[lobby].entities[item_display|text_display|npc]>
    - run fort_lobby_setup

    #-create the entities upon joining/quitting, or remove/add entities when entering/exiting area

    #-remove the sound for whenever hitting the npc?

    on player stops flying flagged:fort.in_menu:
    - determine cancelled

    #-remove/hide the display entities when they exit the cuboid?
    on player enters fort_menu:
    #in case it bugs and joins them twice (or when i reload while inside the menu)
    - if <player.has_flag[fort.in_menu]>:
      - stop

    - flag player fort.in_menu
    - if <context.cause> != JOIN:
      - run fort_lobby_handler.lobby_tp
    - adjust <player> can_fly:true
    - adjust <player> flying:true

    - adjust <player> fly_speed:0.02
    #- adjust <player> hide_from_players
    - invisible state:true
    - inventory clear
    - sidebar remove
    - if <player.has_flag[minimap]>:
      - run minimap

    - define youtube_icon <&chr[13].font[icons]>
    - define twitch_icon  <&chr[14].font[icons]>
    - define twitter_icon <&chr[15].font[icons]>

    - define actionbar_text "<[youtube_icon]> Nimsy <[twitch_icon]> FlimsyNimsy <[twitter_icon]> N1msy"

    #wait, so the player's play button flag will work (when they join the server)
    - wait 1t

    - while <player.is_online> && <player.has_flag[fort.in_menu]>:
      #socials
      - inject fort_lobby_handler.menu
      #only update every 2 seconds
      - actionbar <[actionbar_text]> if:<[loop_index].mod[40].equals[0]>
      - wait 1t
    #wait for fade effect to go away
    - wait 6t
    - flag player fort.in_menu:!

    on player exits fort_menu:

    - if <context.cause> == WALK:
      - run fort_lobby_handler.lobby_tp
      - stop

    #cancel the emote
    - flag player fort.in_menu:!
    - flag player fort.emote:!
    - if <context.cause> == QUIT:
      - stop

    - title title:<&font[denizen:black]><&chr[0004]><&chr[F801]><&chr[0004]> fade_in:7t stay:0s fade_out:1s
    - wait 6t
    - adjust <player> can_fly:false
    - invisible state:false
    - heal
    - give fort_pickaxe_default slot:1
    - adjust <player> item_slot:1
    - adjust <player> fly_speed:0.2

    - wait 1t
    - inject update_hud
    - if !<player.has_flag[minimap]>:
      - run minimap

    #in case they click it from far
    on player left clicks block flagged:fort.menu.selected_button priority:-10:
    - inject fort_lobby_handler.button_press

    on player damages entity flagged:fort.menu.selected_button priority:-10:
    - determine passively cancelled
    - inject fort_lobby_handler.button_press

    on player damages entity flagged:fort.in_menu:
    - determine cancelled

    #### - [ OPTIMIZE / PRETTIFY THIS CODE ] ###
    on player join:
    ##############remove this
    - if !<list[asd988|Nimsy|DessieWessie].contains[<player.name>]>:
      - stop

    - teleport <player> <server.flag[fort.menu_spawn].above[0.5]>

    #default mode
    - flag player fort.menu.mode:solo

    - foreach <list[light|medium|heavy|shells|rockets]> as:ammo_type:
      - flag <player> fort.ammo.<[ammo_type]>:999

    - adjust <player> item_slot:1

    - define pad_loc <server.flag[fort.menu.pads].first.location>
    - define npc_loc <[pad_loc].face[<player.eye_location>].with_pitch[0]>
    - create PLAYER <player.name> <[npc_loc]> save:player_npc
    - define player_npc <entry[player_npc].created_npc>
    - adjust <[player_npc]> hide_from_players
    - adjust <[player_npc]> name_visible:false
    - adjust <player> show_entity:<[player_npc]>

    - flag player fort.menu.player_npc:<[player_npc]>

    - spawn <entity[text_display].with[text=<player.name><n><&c>Not Ready;background_color=transparent;pivot=CENTER;scale=1,1,1;hide_from_players=true]> <[npc_loc].above[1.5]> save:name_text
    - flag player fort.menu.name:<entry[name_text].spawned_entity>
    - adjust <player> show_entity:<entry[name_text].spawned_entity>

    #show hud (dont show hud)
    #- inject update_hud

    #get the middle location
    - define button_loc <server.flag[fort.menu.play_button_hitboxes].get[2].location>
    - foreach play|mode as:button_type:
      - if <[button_type]> == mode:
        - define button_loc <[button_loc].above[0.8]>
      - define l <[button_loc].above[0.5]>
      - define l <[l].with_yaw[<[l].yaw.add[20]>]>
      - spawn <entity[item_display].with[item=<item[oak_sign].with[custom_model_data=<map[play=1;mode=14].get[<[button_type]>]>]>;scale=3,3,3;hide_from_players=true]> <[l]> save:<[button_type]>_button
      - define <[button_type]>_button <entry[<[button_type]>_button].spawned_entity>
      - adjust <player> show_entity:<[<[button_type]>_button]>

      - flag player fort.menu.<[button_type]>_button:<[<[button_type]>_button]>
      - flag <[<[button_type]>_button]> type:<[button_type]>

    #vid button
    ##moving it forward a little bit, because it for some reason rotates a little bit
   #- define vid_button_loc <server.flag[fort.menu.vid_button_bg].location.backward_flat[0.001]>
    - define vid_button_loc <server.flag[fort.menu.vid_button_bg].location.backward_flat[0.05]>
    - spawn <entity[item_display].with[item=<item[oak_sign].with[custom_model_data=20]>;scale=3,3,3;hide_from_players=true]> <[vid_button_loc]> save:vid_button
    - define vid_button <entry[vid_button].spawned_entity>
    - adjust <player> show_entity:<[vid_button]>

    - flag player fort.menu.vid_button:<[vid_button]>
    - flag <[vid_button]> type:vid_button

    - foreach <server.flag[fort.menu.invite_button_hitboxes]> as:hb:
      - define hb_loc <[hb].location>
      - spawn <entity[item_display].with[item=<item[oak_sign].with[custom_model_data=12]>;scale=0.75,0.75,0.75;hide_from_players=true]> <[hb_loc].above[0.5]> save:inv_<[loop_index]>
      - define button <entry[inv_<[loop_index]>].spawned_entity>
      - adjust <player> show_entity:<[button]>
      - flag player fort.menu.invite_button.<[loop_index]>:->:<[button]>
      - flag <[button]> type:invite

    #-nimnite title
    - wait 5s
    - if !<player.has_flag[fort.in_queue]> || !<player.has_flag[fort.menu.match_info]>:
      - run fort_lobby_handler.match_info def.option:add

    ## - [ MAKE THIS CLEANER ] - ##
    on player quit priority:-10:
    - define uuid <player.uuid>
    #- adjust <player> show_to_players
    - if <player.has_flag[fort.menu]>:
      - foreach play|mode|vid as:button_type:
        - define button <player.flag[fort.menu.<[button_type]>_button]>
        #play/mode/vid button
        - remove <[button]> if:<[button].is_spawned>

      #invite buttons
      - foreach <player.flag[fort.menu.invite_button].keys> as:k:
        - define e <player.flag[fort.menu.invite_button.<[k]>].first>
        - remove <[e]> if:<[e].is_spawned>

      #match info text
      - if <player.has_flag[fort.menu.match_info]> && <player.flag[fort.menu.match_info].is_spawned>:
        - run fort_lobby_handler.match_info def.button:<player.flag[fort.menu.match_info]> def.option:remove

      #player npc
      - if <player.has_flag[fort.menu.player_npc]> && <player.flag[fort.menu.player_npc].is_spawned>:
        - remove <player.flag[fort.menu.player_npc]>

      #player name
      - if <player.has_flag[fort.menu.name]> && <player.flag[fort.menu.name].is_spawned>:
        - remove <player.flag[fort.menu.name]>

      #nimnite title
      - if <player.has_flag[fort.menu.title]> && <player.flag[fort.menu.title].is_spawned>:
        - remove <player.flag[fort.menu.title]>


    - if <player.has_flag[fort.emote]> && <player.has_flag[spawned_dmodel_emotes]>:
      - run dmodels_delete def.root_entity:<player.flag[spawned_dmodel_emotes]>
    - flag player fort:!
    - inventory clear

  lobby_tp:
    - title title:<&font[denizen:black]><&chr[0004]><&chr[F801]><&chr[0004]> fade_in:7t stay:0s fade_out:1s
    - wait 7t
    - teleport <player> <server.flag[fort.menu_spawn].above[0.5]>

  menu:
    #used in "minimap.dsc"
    - define interaction <player.eye_location.ray_trace_target[entities=interaction;range=25]||null>
    - if <[interaction]> != null && <[interaction].has_flag[menu]>:

      #get the button type from the player's target
      - define button_type <[interaction].flag[menu].keys.first>

      - if <[button_type]> == invite_button:
        - foreach <player.flag[fort.menu.invite_button].keys> as:k:
          - if <[interaction].flag[menu.invite_button].keys.first> == <[k]>:
            - define selected_button <player.flag[fort.menu.invite_button.<[k]>].first>
            - flag player fort.menu.invite_button_entity:<[selected_button]>
            - foreach stop
      - else:
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

  title_anim:

    #two second animation time

    - flag <[title]> animating

    - repeat 2:

      - define sign +
      - if <[value]> == 2:
        - define sign -

      - define dur 20
      - adjust <[title]> interpolation_start:0
      - adjust <[title]> translation:0,<[sign]>0.01,0
      - adjust <[title]> interpolation_duration:<[dur]>t

      - wait <[dur]>t
      - stop if:!<[title].is_spawned>

      - define dur 8
      - adjust <[title]> interpolation_start:0
      - adjust <[title]> translation:0,<[sign]>0.025,0
      - adjust <[title]> interpolation_duration:<[dur]>t

      - wait <[dur]>t
      - stop if:!<[title].is_spawned>

      - define dur 12
      - adjust <[title]> interpolation_start:0
      - adjust <[title]> translation:0,<[sign]>0.05,0
      - adjust <[title]> interpolation_duration:<[dur]>t

      - if <[value]> != 2:
        - wait <[dur]>t
        - stop if:!<[title].is_spawned>

    - stop if:!<[title].is_spawned>

    - flag <[title]> animating:!


  select_anim:
    - define anim_speed  16
    - define type        <[button].flag[type]>
    - define scale       <[button].scale>
    - define scale_add   <map[play=0.25;mode=0.25;invite=0.1;vid=0.2].get[<[type].before[_]>]>
    - define max_scale   <[scale].add[<[scale_add]>,<[scale_add]>,<[scale_add]>]>
    - if <[type]> != invite:
      - glow <[button]> true
    #in case they select it mid-glint anim
    - if <[type]> == play && !<player.has_flag[fort.in_queue]>:
      - adjust <[button]> item:<item[oak_sign].with[custom_model_data=1]>
    - flag <[button]> selected_animation
    - while <[button].is_spawned> && <[button].has_flag[selected]>:
      - if <[button].has_flag[press_animation]>:
        - wait 1t
        - while next

      - adjust <[button]> interpolation_start:0
      - adjust <[button]> scale:<[max_scale]>
      - adjust <[button]> interpolation_duration:<[anim_speed]>t

      #wait 1t to instantly stop
      - repeat <[anim_speed]>:
        - while stop if:!<[button].has_flag[selected]>
        - wait 1t
        - while next if:<[button].has_flag[press_animation]>

      - adjust <[button]> interpolation_start:0
      - adjust <[button]> scale:<[scale]>
      - adjust <[button]> interpolation_duration:<[anim_speed]>t

      - repeat <[anim_speed]>:
        - while stop if:!<[button].has_flag[selected]>
        - wait 1t
        - while next if:<[button].has_flag[press_animation]>

    - adjust <[button]> scale:<[scale]>
    - glow <[button]> false
    - flag <[button]> selected_animation:!

  button_press:
    #null fall back is in case the player shoots the interact entity from too far, so there'd be nothing selected
    - define button_type <player.flag[fort.menu.selected_button]||null>
    - stop if:<[button_type].equals[null]>
    - define button <player.flag[fort.menu.<[button_type]>]>
    - define name_text <player.flag[fort.menu.name]||null>
    - playsound <player> sound:BLOCK_NOTE_BLOCK_HAT pitch:1
    - choose <[button_type]>:
      - case play_button:
        - if <player.has_flag[fort.in_queue]>:
          ## [ CANCELLING ] ##

          - run fort_lobby_handler.match_info def.option:remove

          - adjust <[name_text]> "text:<player.name><n><&c>Not ready" if:<[name_text].equals[null].not>

          - playsound <player> sound:BLOCK_NOTE_BLOCK_BASS pitch:1
          - flag player fort.in_queue:!
          - define i <item[oak_sign].with[custom_model_data=1]>
        - else:
          ## [ READYING UP ] ##
          #spawn time elapsed text entity
          #check in case they spam

          #have to flag *before* match_info shows up
          - flag player fort.in_queue:0

          - run fort_lobby_handler.match_info def.option:add

          - adjust <[name_text]> text:<player.name><n><&a>Ready if:<[name_text].equals[null].not>

          - playsound <player> sound:BLOCK_NOTE_BLOCK_BASS pitch:0
          - define i <item[oak_sign].with[custom_model_data=10]>

        - run fort_lobby_handler.press_anim def.button:<[button]>
        - adjust <[button]> item:<[i]>

      - case mode_button:
        - run fort_lobby_handler.press_anim def.button:<[button]>
        - if !<player.has_flag[fort.menu.coming_soon_cooldown]>:
          - playsound <player> sound:ENTITY_VILLAGER_NO
          - narrate "<&c>This feature is coming soon."
          - flag player fort.menu.coming_soon_cooldown duration:2s
        - stop

        - if <player.has_flag[fort.in_queue]>:
          - if !<player.has_flag[fort.menu.mode_lock_cooldown]>:
            - playsound <player> sound:ENTITY_VILLAGER_NO
            - narrate "<&c>Cannot change modes mid-queue."
            - flag player fort.menu.mode_lock_cooldown duration:2s
          - stop

        ###use this to add new modes
        - define new_mode <map[solo=duos;duos=squads;squads=solo].get[<player.flag[fort.menu.mode]>]>
        - flag player fort.menu.mode:<[new_mode]>
        - define i <item[oak_sign].with[custom_model_data=<map[solo=14;duos=15;squads=16].get[<[new_mode]>]>]>

        - run fort_lobby_handler.press_anim def.button:<[button]>
        - adjust <[button]> item:<[i]>

      - case invite_button:
        - define button <player.flag[fort.menu.invite_button_entity]>
        - run fort_lobby_handler.press_anim def.button:<[button]> def.size_data:<map[to=<location[1.15,1.15,1.15]>;back=<location[0.75,0.75,0.75]>]>

      - case vid_button:
        - define button <player.flag[fort.menu.vid_button]>
        - run fort_lobby_handler.press_anim def.button:<[button]> def.size_data:<map[to=<location[3.5,3.5,3.5]>;back=<location[3,3,3]>]>

  match_info:
    - define info_display <player.flag[fort.menu.match_info]||null>
    - choose <[option]>:

      - case add:
        #it's a title, but no need to check for it, since that's the only possible thing it can be
        - if <[info_display]> != null && <[info_display].is_spawned>:
          - run fort_lobby_handler.match_info def.button:<player.flag[fort.menu.match_info]> def.option:remove
          - wait 4t

        - if <player.has_flag[fort.menu.match_info]> && <player.flag[fort.menu.match_info].is_spawned>:
          - stop

        #above[0.55] (on top of play button)
        #below[1] (below play button)
        #below and back
        #above it: <[button_loc].above[1.3].with_yaw[<[button_loc].yaw.add[180]>]>
        - define match_info_loc <server.flag[fort.menu_spawn].forward[5].above[3.25].with_yaw[<server.flag[fort.menu_spawn].yaw.add[180]>]>
        - define text "Finding match...<n>Elapsed: <time[2069/01/01].format[m:ss]>"
        - define translation 0,0.25,0
        #nimnite title
        - if !<player.has_flag[fort.in_queue]>:
          - define text <&chr[999].font[icons]>
          - define translation 0,-0.3,0
          - define match_info_loc <[match_info_loc].above>

        - spawn <entity[text_display].with[text=<[text]>;pivot=CENTER;translation=<[translation]>;scale=1,0,1;hide_from_players=true]> <[match_info_loc]> save:match_info
        - define info_display <entry[match_info].spawned_entity>

        - if !<player.has_flag[fort.in_queue]>:
          #flagging spawn anim just so the "idle" animation and spawn animation dont overlap
          - adjust <[info_display]> background_color:transparent
          #- flag <[info_display]> spawn_anim duration:3t
          - flag <[info_display]> title

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
          - define translation 0,0.25,0

          #this means if they're removing the queue thing
          - if <player.has_flag[fort.in_queue]>:
            - define translation 0,-0.5,0
          - adjust <[info_display]> translation:<[translation]>
          - adjust <[info_display]> scale:<location[1,0,1]>
          - adjust <[info_display]> interpolation_duration:2t
          - wait 2t
          - remove <[info_display]> if:<[info_display].is_spawned>

          - if !<[info_display].has_flag[title]> && !<player.has_flag[fort.in_queue]>:
            - run fort_lobby_handler.match_info def.button:<[info_display]> def.option:add
        #- flag player fort.menu.match_info:!

  play_button_anim:
    - repeat 8:
      #in case the bar is removed
      - if <[button].has_flag[selected]> || !<[button].is_spawned>:
        - stop
      - define i <item[oak_sign].with[custom_model_data=<[value].add[1]>]>
      - adjust <[button]> item:<[i]>
      - wait 1t
    - adjust <[button]> item:<item[oak_sign].with[custom_model_data=1]> if:<[button].is_spawned>



  press_anim:
    #speed 1 has a "pressing" anim
    ##waiting 1 tick after a denizen/paper update has made it a bit better?
    #- wait 1t
    - if <[size_data].exists>:
      - define to_size   <[size_data].get[to]>
      - define back_size <[size_data].get[back]>
    - else:
      - define to_size   <location[4,4,4]>
      - define back_size <location[3,3,3]>
    - define speed 2
    - flag <[button]> press_animation duration:4t
    - adjust <[button]> interpolation_start:0
    - adjust <[button]> scale:<[to_size]>
    - adjust <[button]> interpolation_duration:<[speed]>t

    - wait <[speed]>t

    - adjust <[button]> interpolation_start:0
    - adjust <[button]> scale:<[back_size]>
    - adjust <[button]> interpolation_duration:<[speed]>t



fort_lobby_setup:
  type: task
  debug: false
  definitions: cube|loops|type
  script:

    #-reset previous entities
    - foreach play|mode|vid as:button_type:
      - if <server.has_flag[fort.menu.<[button_type]>_button_hitboxes]>:
        - foreach <server.flag[fort.menu.<[button_type]>_button_hitboxes]> as:hb:
          - remove <[hb]> if:<[hb].is_spawned>

    - if <server.has_flag[fort.menu.pads]>:
      - foreach <server.flag[fort.menu.pads]> as:p:
        - remove <[p]> if:<[p].is_spawned>

    - if <server.has_flag[fort.menu.invite_button_hitboxes]>:
      - foreach <server.flag[fort.menu.invite_button_hitboxes]> as:inv:
        - remove <[inv]> if:<[inv].is_spawned>

    - if <server.has_flag[fort.menu.button_bg]>:
      - remove <server.flag[fort.menu.button_bg]> if:<server.flag[fort.menu.button_bg].is_spawned>

    - if <server.has_flag[fort.menu.vid_button_bg]>:
      - remove <server.flag[fort.menu.vid_button_bg]> if:<server.flag[fort.menu.vid_button_bg].is_spawned>

    - if <server.has_flag[fort.menu.vid_text]>:
      - remove <server.flag[fort.menu.vid_text]> if:<server.flag[fort.menu.vid_text].is_spawned>

    - if <server.has_flag[fort.menu.bg_planes]>:
      - foreach <server.flag[fort.menu.bg_planes]> as:plane:
        - remove <[plane]> if:<[plane].is_spawned>

    - if <server.has_flag[fort.menu.bg_cubes]>:
      - foreach <server.flag[fort.menu.bg_cubes]> as:plane:
        - remove <[plane]> if:<[plane].is_spawned>

    - if <server.has_flag[fort.menu.text_wall]>:
      - remove <server.flag[fort.menu.text_wall]> if:<server.flag[fort.menu.text_wall].is_spawned>

    #- define loc <player.location.center.with_pose[0,0]>
    - define loc <server.flag[fort.menu_spawn]>

    - flag server fort.menu:!
    #bottom right: <[loc].forward[2.5].right[0.8].below[0.5]>
    #bottom middle: <[loc].forward_flat[3].below[0.5]>
    #top middle: <[loc].forward[4].above[2].left[2]>
    - define play_loc <[loc].forward[4.5].right[1.2].below[0.2]>

    ## - [ BUTTONS ] - ##

    #-play button hitboxes
    - repeat 3:
      - spawn <entity[interaction].with[width=1;height=1]> <[play_loc].right[<[value]>]> save:play_hitbox_<[value]>
      - define play_hitbox <entry[play_hitbox_<[value]>].spawned_entity>
      - flag <[play_hitbox]> menu.play_button
      - flag server fort.menu.play_button_hitboxes:->:<[play_hitbox]>

    #-mode button hitboxes
    - repeat 3:
      - define mode_loc <[play_loc].forward[0.3].above[1].right[<[value].div[1.05].add[0.1]>]>
      - if <[value]> == 3:
        - define mode_loc <[mode_loc].backward[0.25].right[0.1]>
      - else if <[value]> == 1:
        - define mode_loc <[mode_loc].forward[0.28]>
      - spawn <entity[interaction].with[width=1;height=0.55]> <[mode_loc]> save:mode_hitbox_<[value]>
      - define mode_hitbox <entry[mode_hitbox_<[value]>].spawned_entity>
      - flag <[mode_hitbox]> menu.mode_button
      - flag server fort.menu.mode_button_hitboxes:->:<[mode_hitbox]>

    #get the center one
    - define play_loc <[loc].forward[4.5].right[3.2].below[0.2]>

    - spawn <entity[item_display].with[item=<item[oak_sign].with[custom_model_data=13]>;scale=3,1.63,3]> <[play_loc].above[0.85].forward[0.001].with_yaw[<[play_loc].yaw.add[20]>]> save:button_bg
    - define button_bg <entry[button_bg].spawned_entity>
    - flag server fort.menu.button_bg:<[button_bg]>

    #-vid button hitboxes
    - repeat 3:
      - define vid_loc <[play_loc].forward[0.1].above[0.8].left[<[value].div[1.15].add[5.5]>]>
      - if <[value]> == 3:
        - define vid_loc <[vid_loc].backward[0.25].left[0.1]>
      - else if <[value]> == 1:
        - define vid_loc <[vid_loc].forward[0.28]>
      - spawn <entity[interaction].with[width=0.9;height=2]> <[vid_loc]> save:vid_hitbox_<[value]>
      - define vid_hitbox <entry[vid_hitbox_<[value]>].spawned_entity>
      - flag <[vid_hitbox]> menu.vid_button
      - flag server fort.menu.vid_button_hitboxes:->:<[vid_hitbox]>

    #vid bg
    - define vid_bg_loc <[play_loc].forward[0.1].above[1.8].left[7.3].forward[0.001].with_yaw[<[play_loc].yaw.sub[20]>]>
    - spawn <entity[item_display].with[item=<item[oak_sign].with[custom_model_data=19]>;scale=3.1,1.8,3.1]> <[vid_bg_loc]> save:vid_button_bg
    - define vid_button_bg <entry[vid_button_bg].spawned_entity>
    - flag server fort.menu.vid_button_bg:<[vid_button_bg]>

    #vid text
    - define text "Watch how this gamemode was made!"
    - define vid_text_loc <[vid_bg_loc].above[1].with_yaw[<[vid_bg_loc].yaw.add[180]>]>
    - spawn <entity[text_display].with[text=<[text]>;pivot=FIXED;scale=0.8,0.8,0.8;background_color=transparent]> <[vid_text_loc]> save:vid_text
    - define vid_text <entry[vid_text].spawned_entity>
    - flag server fort.menu.vid_text:<[vid_text]>


    ## - [ PADS ] - ##

    - define pad_loc_1 <[loc].above.forward[5]>
    - define pad_loc_2 <[pad_loc_1].forward.left[2]>
    - define pad_loc_3 <[pad_loc_2].right[4]>
    - define pad_loc_4 <[pad_loc_3].forward.right[2]>
    - repeat 4:
      - define l <[pad_loc_<[value]>]>
      - modifyblock <[l].center.below> barrier
      - spawn <entity[item_display].with[item=<item[oak_sign].with[custom_model_data=11]>;scale=1,1,1]> <[l]> save:pad_<[value]>
      - flag server fort.menu.pads:->:<entry[pad_<[value]>].spawned_entity>

      #skip the first pad, since that's the player's own one
      - if <[value]> == 1:
        - repeat next
      - spawn <entity[interaction].with[width=1;height=1]> <[l].above[0.25]> save:invite_hitbox_<[value]>
      - define inv_hb <entry[invite_hitbox_<[value]>].spawned_entity>
      - flag <[inv_hb]> menu.invite_button.<[value].sub[1]>
      - flag server fort.menu.invite_button_hitboxes:->:<[inv_hb]>

    ## [ Back Message ] ##

    - define text "<&b><&l>Nimnite<&f> is a remake of the popular game <&o>Fortnite<&f>. Need I say more?<n><n><&f>If you're wondering what happened to <&c><&l>Nimorant<&f>, this server will be undergoing big changes from the ground up. So for the time being, this will be the only gamemode up. Enjoy!<n><n><&o>Special thanks to these people:<n><n><&b>SatoriOnSaturn <&f>(modeler)<n><&b>Freya <&f>(builder)<n><&b>asd988 <&f>(shader wiz)<n><n><&e>Donate on Patreon <&b>@ <&f><&n>patreon.com/nimsy<&r> <&c>❤"
    - spawn <entity[text_display].with[text=<[text]>;background_color=transparent;pivot=FIXED;scale=1,1,1]> <[loc].backward[6].below[0.5].with_yaw[0]> save:text_wall

    - flag server fort.menu.text_wall:<entry[text_wall].spawned_entity>

    ## - [ Background ] - ##

    ## make the circles all 1 big model, via obj mc

    #-cylinder
    - define radius 10
    - define cyl_height 15

    - define center <[loc].below[<[cyl_height].div[2.35]>]>

    - define circle <[center].points_around_y[radius=<[radius]>;points=15]>

    - define i <item[oak_sign].with[custom_model_data=17]>
    - foreach <[circle]> as:plane_loc:

      - define angle <[plane_loc].face[<[center]>].yaw.to_radians>
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

      - spawn <entity[ITEM_DISPLAY].with[item=<[i]>;scale=4.4,<[cyl_height]>,4.4;left_rotation=<[left_rotation]>;translation=0,<[cyl_height].div[2.35]>,0]> <[plane_loc]> save:plane
      - define plane     <entry[plane].spawned_entity>
      - flag server fort.menu.bg_planes:->:<[plane]>

    #-bottom circle
    - define radius 10
    - define height 15

    - define circle <[center].points_around_y[radius=<[radius]>;points=40]>

    - define i <item[oak_sign].with[custom_model_data=17]>
    - foreach <[circle]> as:plane_loc:
      - define angle <[plane_loc].face[<[center]>].yaw.to_radians>
      - define left_rotation <quaternion[0,-1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>
      - define left_rotation <[left_rotation].mul[<location[1,0,0].to_axis_angle_quaternion[<element[90].to_radians>]>]>

      - spawn <entity[ITEM_DISPLAY].with[item=<[i]>;scale=1.6,10.4,1.6;left_rotation=<[left_rotation]>;translation=<[plane_loc].sub[<[center]>].div[2]>]> <[plane_loc].with_yaw[180]> save:plane
      - define plane     <entry[plane].spawned_entity>
      - flag server fort.menu.bg_planes:->:<[plane]>

    #-top circle
    - define radius 10
    - define height 15

    - define circle <[center].add[0,<[cyl_height].mul[1.8]>,0].points_around_y[radius=<[radius]>;points=40]>

    - define i <item[oak_sign].with[custom_model_data=17]>
    - foreach <[circle]> as:plane_loc:
      - define angle <[plane_loc].face[<[center]>].yaw.to_radians>
      - define left_rotation <quaternion[0,-1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>
      - define left_rotation <[left_rotation].mul[<location[1,0,0].to_axis_angle_quaternion[<element[90].to_radians>]>]>

      - spawn <entity[ITEM_DISPLAY].with[item=<[i]>;scale=1.6,10.4,1.6;left_rotation=<[left_rotation]>;translation=<[center].sub[<[plane_loc]>].div[2]>]> <[plane_loc]> save:plane
      - define plane     <entry[plane].spawned_entity>
      - flag server fort.menu.bg_planes:->:<[plane]>

    #-background cubes
    ##to make it more performant, i could combine a bunch of them and make them 1 big image so it would use less text displays
    - define radius 9.8

    - define size 7.1

    - define i <item[white_stained_glass_pane].with[custom_model_data=1]>

    - define center <[loc].below[<[cyl_height].div[4]>]>

    - define circle <[center].points_around_y[radius=<[radius]>;points=25]>

    - foreach <[circle]> as:plane_loc:

      - define angle <[plane_loc].face[<[center]>].yaw.add[180].to_radians>
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

      - spawn <entity[item_display].with[item=<[i]>;left_rotation=<[left_rotation]>;scale=<[size]>,<[size]>,<[size]>]> <[plane_loc].above[1.5]> save:plane
      - define plane     <entry[plane].spawned_entity>
      - flag server fort.menu.bg_cubes:->:<[plane]>

    ##

    ##for tutorial icon, make sure to add text saying "Tutorial" when hovering over it

    - flag server fort.menu_spawn:<[loc]>

    - define size 8
    #- define cuboid <[loc].below[<[size]>].backward[<[size]>].left[<[size]>].to_cuboid[<[loc].above[<[size]>].forward[<[size]>].right[<[size]>]>]>
    - define ellipsoid <[loc].below[1.1].to_ellipsoid[<[size]>,5,<[size]>]>
    - note <[ellipsoid]> as:fort_menu

  bg_cube_anim:

    - define center <server.flag[fort.menu_spawn].below[3.75]>

    - define circle <[center].points_around_y[radius=9.8;points=25]>

    - foreach <server.flag[fort.menu.bg_cubes].reverse> as:cube:
      - wait 2t
      - run fort_lobby_setup.bg_cube_brightness_anim def.cube:<[cube]>

  bg_cube_brightness_anim:
    #4 seconds total

    - repeat 10:
      - adjust <[cube]> brightness:<map[block=<element[16].sub[<[value]>]>;sky=0]>
      - wait 1t

    - wait 3s

    - repeat 10:
      - adjust <[cube]> brightness:<map[block=<[value].add[5]>;sky=0]>
      - wait 1t

