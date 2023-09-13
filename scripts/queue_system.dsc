## - [ Nimnite Queue System ] - ##
fort_queue_handler:
  type: world
  debug: false
  events:


    ##create events on server shutdown to safely reset the lobby

    after server start:
    - bossbar create fort_waiting color:YELLOW

    ## - [ QUEUE SYSTEM ] - ##
    on delta time secondly:

    - define min_players <script[nimnite_config].data_key[minimum_players]>
    - define max_players <script[nimnite_config].data_key[maximum_players]>

    - define players <server.online_players_flagged[fort]>

    - define players_not_queued <[players].filter[has_flag[fort.in_queue].not]>
    - define players_queued     <[players].filter[has_flag[fort.in_queue]]>

    # - Update Queue Timer
    #bossbar is created on player joins in "lobby.dsc"
    - foreach <[players_queued]> as:player:
      - define uuid <[player].uuid>
      - define seconds_in_queue <[player].flag[fort.in_queue]>

      - flag <[player]> fort.in_queue:++
      - define secs_in_queue <[player].flag[fort.in_queue]>

      - define match_info <[player].flag[fort.menu.match_info]>
      - adjust <[match_info]> "text:Finding match...<n>Elapsed: <time[2069/01/01].add[<[secs_in_queue]>].format[m:ss]>"

    - bossbar update fort_waiting title:<proc[spacing].context[50]><&chr[A004].font[icons]><proc[spacing].context[-72]><&l><element[WAITING FOR PLAYERS].font[lobby_text]> color:YELLOW players:<[players_queued].filter[has_flag[fort.in_menu].not]>


    - run fort_lobby_setup.bg_cube_anim if:<context.second.mod[5].equals[0]>

    #- foreach <[players_not_queued]> as:player:
      #-play the title moving up and down animation
      ###should we have this? id
      #- define title <[player].flag[fort.menu.match_info]>
      #- if <[title].is_spawned> && !<[title].has_flag[spawn_anim]> && !<[title].has_flag[animating]> && <context.second.mod[2]> == 0:
        #- run fort_lobby_handler.title_anim def.title:<[title]>
