#-Belongs on LOBBY SERVER

## - [ Nimnite Queue System ] - ##
fort_queue_handler:
  type: world
  debug: false
  events:


    ##create events on server shutdown to safely reset the lobby

    on server start:
    - bossbar create fort_waiting color:YELLOW players:<server.online_players>

    ## - [ QUEUE SYSTEM ] - ##
    on delta time secondly:

    - define min_players <script[nimnite_config].data_key[minimum_players]>
    - define max_players <script[nimnite_config].data_key[maximum_players]>

    - define players <server.online_players_flagged[fort]>

    - define players_not_queued <[players].filter[has_flag[fort.in_queue].not]>
    - define players_queued     <[players].filter[has_flag[fort.in_queue]]>

    - define solo_servers   <server.flag[fort.available_servers.solo].keys||<list[]>>
    - define duos_servers   <server.flag[fort.available_servers.duos].keys||<list[]>>
    - define squads_servers <server.flag[fort.available_servers.squads].keys||<list[]>>

    #flag keys for available servers
    #.players = each player ready that has joined the pregame island and is waiting for the game to start

    # - Update Queue Timer
    #bossbar is created on player joins in "lobby.dsc"
    - foreach <[players_queued]> as:player:
      - define uuid <[player].uuid>

      - flag <[player]> fort.in_queue:++
      - define secs_in_queue <[player].flag[fort.in_queue]>

      - define match_info <[player].flag[fort.menu.match_info]>
      #timer resets hourly (meaning it can't go past an hour)
      - adjust <[match_info]> "text:Finding match...<n>Elapsed: <time[2069/01/01].add[<[secs_in_queue]>].format[m:ss]>"

      #only send players after waiting at least 5 seconds
      #- if <[secs_in_queue]> > 5:

        #- define available_servers

    #background triangles
    - run fort_lobby_setup.bg_cube_anim if:<context.second.mod[5].equals[0]>


    #-title animation (disabled)
    #- foreach <[players_not_queued]> as:player:
      #-play the title moving up and down animation
      #- define title <[player].flag[fort.menu.match_info]>
      #- if <[title].is_spawned> && !<[title].has_flag[spawn_anim]> && !<[title].has_flag[animating]> && <context.second.mod[2]> == 0:
        #- run fort_lobby_handler.title_anim def.title:<[title]>
