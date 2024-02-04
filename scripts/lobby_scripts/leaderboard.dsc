fort_board_handler:
  type: world
  debug: false
  events:
    on delta time secondly every:10:

    - run update_server_status


update_leaderboard:
  type: task
  debug: false
  definitions: type
  script:

    - define lb_loc <server.flag[fort.menu_spawn].left[6.5].with_yaw[90]>

    - define start_loc <[lb_loc].above[4]>

    ####temp (move to lobby setup) ####

    - define title_display <server.flag[fort.leaderboard.wins.title]||null>
    - if <[title_display]> != null:
      - remove <[title_display]>
    - spawn <entity[text_display].with[text=<&b><&l>Top 10 Wins<&r>;pivot=FIXED;background_color=transparent]> <[start_loc]> save:lb_title_display
    - flag server fort.leaderboard.wins.title:<entry[lb_title_display].spawned_entity>
    #####

    - define first <player>

    #-first place player head
    - define player_head <server.flag[fort.leaderboard.wins.head]||null>
    - if <[player_head]> != null:
      - remove <[player_head]>

    ####REMEMBER TO CACHE THE SKULL SKIN OF THE WINNER WHEN TRANSFERRING SERVER DATA

    - define player_head_item <item[player_head].with[skull_skin=<[first].skull_skin>]>

    - spawn <entity[item_display].with[item=<[player_head_item]>;scale=0,0,0]> <[start_loc].below[0.415].with_yaw[-90]> save:wins_first_head
    - define head_display <entry[wins_first_head].spawned_entity>

    - flag server fort.leaderboard.wins.head:<[head_display]>

    - rotate <[head_display]> infinite yaw:2.5 frequency:1t

    - wait 2t
    #pop up animation
    - adjust <[head_display]> interpolation_start:0
    - adjust <[head_display]> scale:1.25,1.25,1.25
    - adjust <[head_display]> translation:0,0.23,0
    - adjust <[head_display]> interpolation_duration:4t

    - wait 4t

    #redefine start_loc with the player head in mind, so the rest of the names follow after it
    - define start_loc <[start_loc].below[1]>

    #fort flag is removed for lobby stuff, so using separate flag name
    - define players <server.players.random[10]>
    - foreach <[players]> as:p:
      - define place <[loop_index]>
      - define name  <[p].name>

      - define text "<[place].bold>. <[name]>"

      #name colors
      - choose <[place]>:
        - case 1:
          - define text <[text].color_gradient[from=<color[#ffc800]>;to=<color[#fff8de]>]><&r>
        - case 2:
          - define text <[text].color_gradient[from=<color[#b07031]>;to=<color[#fff8de]>]><&r>
        - case 3:
          - define text <[text].color_gradient[from=<color[#757575]>;to=<color[#ffffff]>]><&r>
        - default:
          - define text <[text].color[<color[#696969]>]><&r>

      - define text "<[text]> <&f><[p].flag[fort_data.wins]||->"

      #gold, silver, bronze, gray

      - define name_loc <[start_loc].below[<[place].div[2.5]>]>

      #-text
      #i could just remove and readd a new display entity, OR just update the current one already...
      #idc i wanna do it this way
      - define current_place_display <server.flag[fort.leaderboard.wins.<[place]>.entity]||null>
      - if <[current_place_display]> != null:
        - adjust <[current_place_display]> interpolation_start:0
        - adjust <[current_place_display]> scale:1,0,1
        - adjust <[current_place_display]> translation:0,0.08,0
        - adjust <[current_place_display]> interpolation_duration:1t
        - wait 1t
        - remove <[current_place_display]>

      - spawn <entity[text_display].with[text=<[text]>;pivot=FIXED;background_color=transparent;scale=1,0,1]> <[name_loc]> save:t_<[p]>
      - define e <entry[t_<[p]>].spawned_entity>
      - flag server fort.leaderboard.wins.<[place]>.entity:<[e]>

      - wait 1t
      - adjust <[e]> interpolation_start:0
      - adjust <[e]> scale:1,1,1
      - adjust <[e]> translation:0,0.08,0
      - adjust <[e]> interpolation_duration:3t


    #- announce "<&b>[<bungee.server>]<&r> Updated leaderboard. <&8>(<util.time_now.format>)" to_console