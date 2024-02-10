fort_board_handler:
  type: world
  debug: false
  events:
    on delta time secondly every:10:
    - run update_server_status

    #update lb every 20 sec
    ##- if <context.second.mod[20]> == 0:
      # - [ Fetch LB Data ] - #
      #- run update_leaderboard

fort_stats:
  type: command
  name: stats
  debug: false
  description: Fully recover player's bars
  #permission: Fort.stats
  usage: /stats (mode) (player)
  aliases:
    - stastitics
  script:
    - if !<player.is_op>:
      - narrate "<&c>Command not out yet."
      - stop

    - define mode        <context.args.first||null>
    - define player_name <context.args.get[2]||null>

    # no need for switch statements, but i wanna so players can have multiple options to type the same thing
    - choose <[mode]>:
      - case solo solos:
        - define mode solo
      - case duo duos:
        - define mode duos
      - case squad squads:
        - define mode squads
      - default:
        - narrate "<&c>Incorrect command usage! Type /stats (mode) (player)."
        - stop

    - inject fort_stats.player_check

    - if <player.has_flag[fort.stats_cooldown]>:
      - narrate "<&c>This command is on cooldown! (<player.flag_expiration[fort.stats_cooldown].from_now.formatted>)"
      - stop

    - flag player fort.stats_cooldown duration:3s

    - define uuid         <[player].uuid>

    - define kills        <server.flag[fort.playerstats.<[uuid]>.<[mode]>.kills]||0>
    - define deaths       <server.flag[fort.playerstats.<[uuid]>.<[mode]>.deaths]||0>
    - define games_played <server.flag[fort.playerstats.<[uuid]>.<[mode]>.games_played]||0>
    - define wins         <server.flag[fort.playerstats.<[uuid]>.<[mode]>.wins]||0>

    - if <[games_played]> == 0:
      - narrate "<&c>This player hasn't played yet."
      - stop

    - define losses <[games_played].sub[<[wins]>]>

    - define line <&8><element[<&sp>].repeat[45].strikethrough>
    - narrate <[line]>
    - narrate "<&a>Nimnite <&n><[mode].to_titlecase><&r> <&a>Stats <&f>(<[player].name>)"
    - narrate "<&7>Kills: <&b><[kills]>"
    - narrate "<&7>Deaths: <&b><[deaths]>"
    - narrate "<&7>K/D: <&b><[kills].div[<[deaths]>].round_to[2]||0>"
    - narrate "<&7>Games Played: <&b><[games_played]>"
    - narrate "<&7>Wins: <&b><[wins]>"
    - narrate "<&7>W/L: <&b><[wins].div[<[losses]>].round_to[2]||0>"
    - narrate <[line]>

  player_check:
    - if <[player_name]> == null:
      - define player <player>
    - else:
      - define player <server.match_offline_player[<[player_name]>]||not_found>
      - if <[player]> == not_found:
        - narrate "<&c>Player not found."
        - stop

  cache_playerdata:
    #TODO: cache duos and squads too

    - define uuid <player.uuid>
    - define mode solo

    - ~mongo id:nimnite_playerdata find:[uuid=<player.uuid>] save:pdata
    - define pdata <entry[pdata].result.first.parse_yaml||no_data>

    - define kills        <[pdata].get[<[mode]>].get[kills]||0>
    - define deaths       <[pdata].get[<[mode]>].get[deaths]||0>
    - define games_played <[pdata].get[<[mode]>].get[games_played]||0>
    - define wins         <[pdata].get[<[mode]>].get[wins]||0>

    - flag server fort.playerstats.<[uuid]>.<[mode]>.kills:<[kills]>
    - flag server fort.playerstats.<[uuid]>.<[mode]>.deaths:<[deaths]>
    - flag server fort.playerstats.<[uuid]>.<[mode]>.games_played:<[games_played]>
    - flag server fort.playerstats.<[uuid]>.<[mode]>.wins:<[wins]>

  #testing:
  #  - define mode solo
  #  - define random_players <server.players>
  #  - foreach <[random_players]> as:p:
  #    - foreach <list[kills|wins]> as:type:
  #      - flag server fort.playerdata.<[p].uuid>.<[mode]>.<[type]>:<util.random.int[1].to[10]>

update_leaderboard:
  type: task
  debug: false
  definitions: type|start_loc
  script:
    - define lb_loc <server.flag[fort.menu_spawn].left[6.25].with_yaw[90]>
    - define start_loc <[lb_loc].above[4.1]>

    - run update_leaderboard.set def.type:wins def.start_loc:<[start_loc].left[1.75]>
    - run update_leaderboard.set def.type:kills def.start_loc:<[start_loc].right[1.75]>

  title_setup:

    - define lb_loc <server.flag[fort.menu_spawn].left[6.25].with_yaw[90]>

    - define start_loc <[lb_loc].above[4.1]>

    # - [ stats display ] - #
    - foreach wins|kills as:type:
      - define title_loc <map[wins=<[start_loc].left[1.75]>;kills=<[start_loc].right[1.75]>].get[<[type]>]>
      - define title_display <server.flag[fort.leaderboard.<[type]>.title]||null>
      - if <[title_display]> != null:
        - remove <[title_display]> if:<[title_display].is_spawned>
      - spawn <entity[text_display].with[text=<&b><&l>Top 10 <[type].to_titlecase><&r>;pivot=FIXED;background_color=transparent]> <[title_loc]> save:lb_<[type]>_title_display
      - flag server fort.leaderboard.<[type]>.title:<entry[lb_<[type]>_title_display].spawned_entity>

    # - [ stats display ] - #
    - define info_display <server.flag[fort.leaderboard.info]||null>
    - if <[info_display]> != null:
      - remove <[info_display]> if:<[info_display].is_spawned>
    - spawn <entity[text_display].with[text=<&r>Type <&b>/stats <&7>(mode) (player)<&f> to view more info.;pivot=FIXED;background_color=transparent]> <[start_loc].below[5.7]> save:lb_info_display
    - flag server fort.leaderboard.info:<entry[lb_info_display].spawned_entity>

  set:

    #TODO: duos and squads
    - define mode solo

    #fort flag is removed for lobby stuff, so using separate flag name
    - define cached_uuids <server.flag[fort.playerdata].keys||<list[]>>

    #type = wins/kills
    - define pdata <list[]>
    - foreach <[cached_uuids]> as:u:
      - define amount <server.flag[fort.playerdata.<[u]>.<[mode]>.<[type]>]>
      - define pdata:->:<map[uuid=<[u]>;amount=<[amount]>]>

    - define top_players <[pdata].sort_by_number[get[amount]].reverse.get[1].to[10].parse[get[uuid].as[player]]||<list[]>>

    - define first <[top_players].first||null>

    #-first place player head
    - define player_head <server.flag[fort.leaderboard.<[type]>.head]||null>
    - define skull_skin         <server.flag[fort.playerdata.<[first].uuid||null>.skull_skin]||null>

    - if <[player_head]> != null && <[player_head].is_spawned>:

      # - [ skip anim if same player head ] - #
      - if <[player_head].flag[uuid]||null> != <[first].uuid>:
        - remove <[player_head]>
      - else:
        - define same_first_player True

    - if !<[same_first_player].exists>:
      - define player_head_item <item[player_head].with[skull_skin=<[skull_skin]>]>

      - spawn <entity[item_display].with[item=<[player_head_item]>;scale=0,0,0]> <[start_loc].below[0.415].with_yaw[-90]> save:first_head
      - define head_display <entry[first_head].spawned_entity>

      - flag <[head_display]> uuid:<[first].uuid>
      - flag server fort.leaderboard.<[type]>.head:<[head_display]>

      - rotate <[head_display]> infinite yaw:2.5 frequency:1t

      - wait 3t
      #pop up animation
      - adjust <[head_display]> interpolation_start:0
      - adjust <[head_display]> scale:1.25,1.25,1.25
      - adjust <[head_display]> translation:0,0.23,0
      - adjust <[head_display]> interpolation_duration:4t


    - wait 4t

    #redefine start_loc with the player head in mind, so the rest of the names follow after it
    - define start_loc <[start_loc].below[1]>

    - foreach <[top_players]> as:p:
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

      - define amount <server.flag[fort.playerdata.<[p].uuid>.<[mode]>.<[type]>]>
      - define text "<[text]> <&f><[amount]>"

      #gold, silver, bronze, gray

      - define name_loc <[start_loc].below[<[place].div[2.5]>]>

      #-text
      #i could just remove and readd a new display entity, OR just update the current one already...
      #idc i wanna do it this way
      - define current_place_display <server.flag[fort.leaderboard.<[type]>.<[place]>.entity]||null>
      - if <[current_place_display]> != null && <[current_place_display].is_spawned>:

        # - [ skip the whole animation shit if the player has stayed in the same place ] - #
        - if <[text].strip_color> == <[current_place_display].text.strip_color>:
          - foreach next

        - adjust <[current_place_display]> interpolation_start:0
        - adjust <[current_place_display]> scale:1,0,1
        - adjust <[current_place_display]> translation:0,0.08,0
        - adjust <[current_place_display]> interpolation_duration:1t
        - wait 1t
        - remove <[current_place_display]> if:<[current_place_display].is_spawned>

      - spawn <entity[text_display].with[text=<[text]>;pivot=FIXED;background_color=transparent;scale=1,0,1]> <[name_loc]> save:t_<[p]>
      - define e <entry[t_<[p]>].spawned_entity>
      - flag server fort.leaderboard.<[type]>.<[place]>.entity:<[e]>

      - wait 1t
      - adjust <[e]> interpolation_start:0
      - adjust <[e]> scale:1,1,1
      - adjust <[e]> translation:0,0.08,0
      - adjust <[e]> interpolation_duration:3t


    #- announce "<&b>[<bungee.server>]<&r> Updated leaderboard. <&8>(<util.time_now.format>)" to_console