#-Belongs on LOBBY SERVER

## - [ Nimnite Queue System ] - ##
fort_queue_handler:
  type: world
  debug: false
  events:


    ##create events on server shutdown to safely reset the lobby

    on tick:

      - define priority_queue <script[nimnite_config].data_key[priority_queue]>

      - define tick <context.tick>

    ## - [ Lobby Button Selection ] - ##
      - define lobby_players <server.online_players_flagged[fort.in_menu]>

      - define youtube_icon <&chr[13].font[icons]>
      - define twitch_icon  <&chr[14].font[icons]>
      - define twitter_icon <&chr[15].font[icons]>

      #socials
      - define actionbar_text "<[youtube_icon]> Nimsy <[twitch_icon]> FlimsyNimsy <[twitter_icon]> N1msy"


      - foreach <[lobby_players]> as:p:

        - run fort_lobby_handler.menu player:<[p]>

        #play button animation every 8 seconds
        - define play_button <[p].flag[fort.menu.play_button]>
        - if <[tick].div[20].mod[8]> == 0:
          #not doing second check in same line, so it doesn't have to define every tick
          - define play_button <[p].flag[fort.menu.play_button]>
          - if !<[play_button].has_flag[selected]> && !<[p].has_flag[fort.in_queue]>:
            - run fort_lobby_handler.play_button_anim def.button:<[play_button]>

        ## - [ AFK System ] - ##
        #-maybe add a bypass for mods?

        #should we make this a separate run task?

        #(updates every second)
        - if <[tick].mod[20]> == 1:
          #no need for fallback, since the data is initalized when player joins
          - define previous_loc <[p].flag[fort.afk.location]>
          - define new_loc      <[p].location>
          - if <[previous_loc]> == <[new_loc]>:
            - flag <[p]> fort.afk.time:++
          - else:
            - flag <[p]> fort.afk.time:0
          - flag <[p]> fort.afk.location:<[new_loc]>

          - define afk_seconds <[p].flag[fort.afk.time]>
          #after 10 minutes, kick the player (only if they're not in queue)
          - if <[afk_seconds]> >= 600 && !<[p].has_flag[fort.in_queue]>:
            - kick <[p]> "reason:<&c>You've been AFK for too long!"


      #only update every 2 seconds
      - actionbar <[actionbar_text]> if:<[tick].mod[40].equals[0]> targets:<[lobby_players]>

    ## - [ QUEUE SYSTEM ] - ##
      #every second
      - if <[tick].mod[20]> == 0:
        - define max_players <script[nimnite_config].data_key[maximum_players]>

        - define players <server.online_players_flagged[fort]>

        - define players_not_queued <[players].filter[has_flag[fort.in_queue].not]>
        - define players_queued     <[players].filter[has_flag[fort.in_queue]].filter[has_flag[fort.joining_match].not]>

        - define solo_servers   <server.flag[fort.available_servers.solo].keys||<list[]>>
        - define duos_servers   <server.flag[fort.available_servers.duos].keys||<list[]>>
        - define squads_servers <server.flag[fort.available_servers.squads].keys||<list[]>>

        #flag keys for available servers
        #.players = each player ready that has joined the pregame island and is waiting for the game to start

        # - Update Queue Timer
        #bossbar is created on player joins in "lobby.dsc"
        #sort_by_number.reverse so players who have waited the longest get the highest priority
        - foreach <[players_queued].sort_by_number[flag[fort.in_queue]].reverse> as:player:
          - define uuid <[player].uuid>
          - define mode <[player].flag[fort.menu.mode]>

          - flag <[player]> fort.in_queue:++
          - define secs_in_queue <[player].flag[fort.in_queue]>

          - define match_info <[player].flag[fort.menu.match_info]>

          - define text "Finding match...<n>Elapsed: <time[2069/01/01].add[<[secs_in_queue]>].format[m:ss]>"

          #find the servers only with less than 100 players (because server is still available to join even if the game is starting (if it has less than 100 players))
          #checking if null at the end, since the ".players" key isn't necessarily added yet
          - define available_servers <[<[mode]>_servers].filter_tag[<server.flag[fort.available_servers.<[mode]>.<[filter_value]>.players].size.is[LESS].than[<[max_players]>].if_null[true]>]>

          #-this sorts all available servers by player count from highest to lowest so all servers fill properly
          - define available_servers <[available_servers].parse_tag[<[parse_value]>/<server.flag[fort.available_servers.<[mode]>.<[parse_value]>.players].size>].sort_by_number[after[/]].parse[before[/]].reverse>

          - if <[secs_in_queue]> >= 5 && <[available_servers].any>:
            - define text "Joining match..."

          #timer resets hourly (meaning it can't go past an hour)
          - adjust <[match_info]> text:<[text]>

          #TODO: priority queue

          #only send players after waiting at least 5 seconds
          ##change from 6 to 10 temporarily
          - if <[secs_in_queue]> >= 8 && <[available_servers].any>:

            #get the server with the most players
            #instead of finding the server for each player, update the count within the queue while still having this def so the definition doesnt have to constantly be redefined?
            - define server_to_join <[available_servers].first>

            - narrate "<&a>Sending you to game server <[server_to_join].after_last[_]>." targets:<[player]>

            #- wait 10t
            #- if !<[player].is_online>:
            #  - foreach next

            #this flag is so the foreach doesn't include the "joining" players, in case it takes a minute
            - flag <[player]> fort.joining_match
            - adjust <[player]> send_to:<[server_to_join]>
            #make a waituntil the player is no longer on this server?
            #-should i do it this way, or is it just safer to check in the bungee event
            #one perk of doing it directly on the server is that the flag is basically instant, unlike a bungeerun, making it safe to check
            #if there are enough players waiting on the other server.
            #one way to counter this if i wanted to use bungeerun is to add a delay before checking for available players?
            - flag server fort.available_servers.<[mode]>.<[server_to_join]>.players:->:<[player]>

        #background triangles (every 5 seconds, aka 5*20 = 100)
        - run fort_lobby_setup.bg_cube_anim if:<[tick].mod[100].equals[0]>


        #-title animation (disabled)
        #- foreach <[players_not_queued]> as:player:
          #-play the title moving up and down animation
          #- define title <[player].flag[fort.menu.match_info]>
          #- if <[title].is_spawned> && !<[title].has_flag[spawn_anim]> && !<[title].has_flag[animating]> && <context.second.mod[2]> == 0:
            #- run fort_lobby_handler.title_anim def.title:<[title]>

