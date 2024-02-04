update_server_status:
  type: task
  debug: false
  definitions: type
  script:


    - define start_loc <server.flag[fort.menu_spawn].right[4.5].with_yaw[-90].above[2.5]>

    #fort flag is removed for lobby stuff, so using separate flag name
    - define game_servers <bungee.list_servers.filter[starts_with[fort_]].exclude[fort_lobby].sort_by_number[after[_]]>


    - foreach <[game_servers]> as:s:

      - ~bungeetag server:<[s]> <map[players=<server.online_players_flagged[fort].filter[has_flag[fort.spectating].not]>;mode=<server.flag[fort.mode]>;is_startup=<server.has_flag[fort.temp.startup]>]> save:s_data
      - define s_data <entry[s_data].result>

      ##might be a little cheesing, but for some reason the players flag is incorrectly updated in the hub sometimes?
      - flag server fort.available_servers.<[s]>.players:<[s_data].get[players]>

      - define mode        <[s_data].get[mode]>
      - define player_size <[s_data].get[players].size>

      - define is_available <server.flag[fort.available_servers.<[mode]>].keys.contains[<[s]>]>
      - define status_icon  <[is_available].if_true[<&a>●].if_false[<&c>●]>
      - define number       <[s].after_last[_]>

      - define desc         <[is_available].if_true[<&a>AVAILABLE].if_false[<&f><[player_size]> <&7>left]>
      - if <[s_data].get[is_startup]>:
        - define status_icon  <element[●].color[#ffaa2b]>
        - define desc         <&f>Preparing...

      - define text "<[status_icon]> <&7>Server <[number]> (<&f><[mode]><&7>) <&8>- <[desc]>"

      #gold, silver, bronze, gray
      - define name_loc <[start_loc].below[<[loop_index].div[2.5]>]>

      #-text
      - define current_display <server.flag[fort.status.<[s]>.entity]||null>
      - if <[current_display]> != null:

        # - [ only update the text display if it has changed ] - #
        - if <[text]> == <[current_display].text> && <[name_loc]> == <[current_display].location>:
          - foreach next

        - adjust <[current_display]> interpolation_start:0
        - adjust <[current_display]> scale:1,0,1
        - adjust <[current_display]> translation:0,0.08,0
        - adjust <[current_display]> interpolation_duration:1t
        - wait 2t
        - remove <[current_display]>

      - spawn <entity[text_display].with[text=<[text]>;pivot=FIXED;background_color=transparent;scale=1,0,1]> <[name_loc]> save:e_<[s]>
      - define e <entry[e_<[s]>].spawned_entity>
      - flag server fort.status.<[s]>.entity:<[e]>

      - wait 1t
      - adjust <[e]> interpolation_start:0
      - adjust <[e]> scale:1,1,1
      - adjust <[e]> translation:0,0.08,0
      - adjust <[e]> interpolation_duration:3t

    #so offline servers are removed from the list OR a new game server is starting up

    - define cached_servers  <server.flag[fort.status].keys>
    - define offline_servers <[cached_servers].exclude[<[game_servers]>]>

    - foreach <[offline_servers]> as:o_s:
      - define display <server.flag[fort.status.<[o_s]>.entity]>
      #in case they were somehow removed
      - if !<[display].is_spawned>:
        - foreach next
      - adjust <[display]> interpolation_start:0
      - adjust <[display]> scale:1,0,1
      - adjust <[display]> translation:0,0.08,0
      - adjust <[display]> interpolation_duration:1t
      - wait 2t
      - remove <[display]>
      - flag server fort.status.<[o_s]>:!

