
##make sure to disable lobby circle fx after game starts

pregame_island_handler:
  type: world
  debug: false
  definitions: square
  events:

    on server start:
    - flag server fort.temp.startup
    - announce "<&b>[Nimnite]<&r> Getting ready for startup..." to_console
    #5 seconds
    - wait 5s
    - announce "-------------------- [ <&b>NIMNITE GAME SERVER STARTUP <&r>] --------------------" to_console

    #two ways of doing the "copying" system:
    #1) copy the file, then create the world
    #2) have the template world on each server and use "copy_from" arg in createworld command

    #either createworld here, *or* just remove the world on shut down
    - if <util.has_file[../../nimnite_map]>:
      - ~createworld nimnite_map
      - adjust <world[nimnite_map]> destroy

    - ~filecopy origin:../../../../nimnite_map_template destination:../../nimnite_map overwrite
    - ~createworld nimnite_map

    - announce "<&b>[Nimnite]<&r> Created world <&dq><&a>nimnite_map<&r><&dq> from <&dq><&e>nimnite_map_template<&r><&dq>" to_console

    - foreach <list[chests|ammo_boxes]> as:container_type:
      - define containers <server.flag[fort.<[container_type]>]||<list[]>>
      - announce "<&b>[Nimnite]<&r> Filling all <&e><[container_type].replace[_].with[ ]><&r>..." to_console

      - foreach <[containers]> as:loc:
        - inject fort_chest_handler.fill_<map[chests=chest;ammo_boxes=ammo_box].get[<[container_type]>]>

      - announce "<&b>[Nimnite]<&r> Done (<&a><[containers].size><&r> filled)" to_console

    ##################SET FLOOR LOOT TOO
    - announce "<&b>[Nimnite]<&r> Setting all <&e>floor loot<&r>... <&c>Coming Soon." to_console
    #- announce "<&b>[Nimnite]<&r> Setting all <&e>floor loot<&r>..." to_console
    #- announce "<&b>[Nimnite]<&r> Done (<&a>0<&r>)" to_console

    - run pregame_island_handler.lobby_circle.anim
    - announce "<&b>[Nimnite]<&r> Set lobby circle animation in world <&dq><&e>fort_pregame_island<&r><&dq>" to_console

    - define bossbar fort_info
    - bossbar create <[bossbar]> title:<proc[spacing].context[50]><&chr[A004].font[icons]><proc[spacing].context[-72]><&l><element[WAITING FOR PLAYERS].font[lobby_text]> color:YELLOW players:<server.online_players>
    - announce "<&b>[Nimnite]<&r> Created bossbar <&dq><&e><[bossbar]><&r><&dq>" to_console
    - announce ------------------------------------------------------------------------- to_console
    - flag server fort.temp.startup:!


    on player join:

    - teleport <player> <server.flag[fort.pregame.spawn].random_offset[10,0,10]>

    - flag player fort.wood.qty:0
    - flag player fort.brick.qty:0
    - flag player fort.metal.qty:0

    - foreach <list[light|medium|heavy|shells|rockets]> as:ammo_type:
      - flag player fort.ammo.<[ammo_type]>:999

    - adjust <player> gamemode:survival
    - inventory clear
    - give fort_pickaxe_default slot:1
    - adjust <player> item_slot:1

    - run update_hud
    - run minimap
    - wait 10t
    - bossbar update fort_info color:YELLOW players:<player>

    - if <server.online_players_flagged[fort].size> >= <script[nimnite_config].data_key[minimum_players]> && !<server.has_flag[fort.temp.game_starting]>:
      - run pregame_island_handler.countdown

    # - [ Return to Lobby Menu ] - #
    on player enters fort_lobby_circle:
    - title title:<&font[denizen:black]><&chr[0004]><&chr[F801]><&chr[0004]> fade_in:7t stay:0s fade_out:1s
    - cast LEVITATION duration:8t amplifier:3 no_ambient no_clear no_icon hide_particles
    - wait 7t
    - adjust <player> send_to:fort_lobby

    ##################################TEMP WORLD CHANGE SHIT
    #on player changes world from fort_pregame_island:
    #- define mode solo
    #- flag server fort.available_servers.solo.test.players:<-:<player>
    #- bossbar remove fort_info players:<player>


  countdown:
    - define min_players <script[nimnite_config].data_key[minimum_players]>
    - define +spacing    <proc[spacing].context[99]>
    - define -spacing    <proc[spacing].context[-121]>
    - define bus_icon    <&chr[A025].font[icons]>
    - define clock_icon  <&chr[0004].font[icons]>

    - flag server fort.temp.game_starting
    #flagging phase for hud updating manually too
    - flag server fort.temp.phase:bus
    - repeat 10:
      - define players <server.online_players_flagged[fort]>
      - define seconds <element[10].sub[<[value]>]>
      - define timer <time[2069/01/01].add[<[seconds]>].format[m:ss]>

      - flag server fort.temp.timer:<[timer]>

      - bossbar update fort_info title:<[+spacing]><[bus_icon]><[-spacing]><&l><element[BATTLE BUS LAUNCHING IN].font[lobby_text]><&sp><element[<&d><&l><[seconds]> Seconds].font[lobby_text]> color:YELLOW players:<[players]>
      - sidebar set_line scores:5 values:<element[<&chr[0025].font[icons]> <[timer]>].font[hud_text].color[<color[50,0,0]>]> players:<[players]>

      - wait 1s
      - define players <server.online_players_flagged[fort]>
      - if <[players].size> < <[min_players]>:
        - bossbar update fort_info title:<proc[spacing].context[50]><&chr[A004].font[icons]><proc[spacing].context[-72]><&l><element[WAITING FOR PLAYERS].font[lobby_text]> color:YELLOW players:<[players]>
        - sidebar set_line scores:5 values:<element[<[clock_icon]> -].font[hud_text].color[<color[50,0,0]>]> players:<[players]>

        - flag server fort.temp:!
        - stop

    - announce start_game

    ###remove this
    - flag server fort.temp:!


  lobby_circle:
    anim:
      - define loc <server.flag[fort.pregame.lobby_circle.loc].with_pose[0,0]>
      - define circle <server.flag[fort.pregame.lobby_circle.circle]>

      #in case server was shut down incorrectly (or before a match was started)
      - remove <world[pregame_island].entities[text_display].filter[has_flag[lobby_circle_square]]>

      - flag server fort.lobby_circle_enabled

      - while <server.has_flag[fort.lobby_circle_enabled]>:
        - if <[circle].is_spawned>:
          - adjust <[circle]> interpolation_start:0
          - adjust <[circle]> left_rotation:<quaternion[0,0,1,0].mul[<location[0,0,-1].to_axis_angle_quaternion[<[loop_index].div[85]>]>]>
          - adjust <[circle]> interpolation_duration:1t

        #-square
        - if <[loop_index].mod[6]> == 0:
          - define size            <util.random.decimal[1.2].to[1.9]>
          - define origin          <[loc].below[0.4].random_offset[0.75,0,0.75]>
          - define end_translation 0,<util.random.decimal[1.8].to[2.6]>,0

          - spawn <entity[text_display].with[text=<element[⬛].color[#<list[D8F0FF|AAF4FF].random>]>;pivot=VERTICAL;scale=<[size]>,<[size]>,<[size]>;background_color=transparent]> <[origin]> save:fx
          - define fx <entry[fx].spawned_entity>
          - flag <[fx]> lobby_circle_square

          - wait 1t

          - adjust <[fx]> interpolation_start:0
          - adjust <[fx]> translation:<[end_translation]>
          - adjust <[fx]> scale:0,0,0
          - adjust <[fx]> interpolation_duration:50t
          - run fort_global_handler.death_fx.remove_square def:<map[square=<[fx]>;wait=52]>
        - else:
          - wait 1t

      #remove entities in case they weren't already (or if server shuts down)
      - remove <world[pregame_island].entities[text_display].filter[has_flag[lobby_circle_square]]>
      - flag server fort.lobby_circle_enabled:!
