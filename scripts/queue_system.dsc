## - [ Nimnite Queue System ] - ##
fort_queue_handler:
  type: world
  debug: false
  events:

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
      - define seconds_in_queue <[player].flag[val.in_queue]>

      - bossbar update queue_<[uuid]>_2 color:WHITE style:SOLID title:<&f><time[2069/01/01].add[<[seconds_in_queue]>].format[m:ss]>

      - flag <[player]> val.in_queue:++

    - foreach <[players_not_queued]> as:player:
      ############remove this
      - if <[player].name> != Nimsy:
        - stop

      #play the "play" glint animation
      - run fort_lobby_handler.play_button_anim def.player:<[player]> if:<context.second.mod[10].equals[0]>


