fort_commands_handler:
  type: world
  debug: false
  events:
    on player clicks in inventory flagged:fort.model_menu:
    - if <context.inventory> == <player.inventory>:
      - stop
    - define i <context.item>
    - stop if:!<[i].script.exists>
    - if !<[i].script.name.starts_with[fort_]||true>:
      - stop
    - determine passively cancelled

    - give <[i]>
    - narrate "<&7>Recieved <&a><[i].display>"

    on player closes inventory flagged:fort.model_menu:
    - flag player fort.model_menu:!
    - narrate "<&c>Closed Nimnite models menu."

    on player clicks in inventory flagged:fort.spectate_menu:
    - determine passively cancelled
    - define i <context.item>
    - if !<[i].has_flag[server]>:
      - stop

    - if <player.has_flag[fort.spectate_cooldown]>:
      - narrate "<&c>This is on cooldown."
      - stop

    - if <player.has_flag[fort.spectate_sending]>:
      - narrate "<&c>Already sending you to a server."
      - stop

    - flag player fort.spectate_cooldown duration:1s

    - define server <[i].flag[server]>
    - ~bungeetag server:<[server]> <server.worlds.contains[<world[nimnite_map]>]> save:is_ready
    - define is_ready <entry[is_ready].result>
    - if !<[is_ready]>:
      - narrate "<&c>Server isn't ready yet."
      - stop

    - inventory close
    - flag player fort.spectate_sending

    - narrate "<&a>Sending you to server:<&r> <[server]>"
    - bungeerun <[server]> fort_spectate_bungee def:<player>
    - wait 1s
    #this command is not very well tested. for example, a player could leave and theyd still have the joined_as_spectator flag, but idc
    - flag player fort.spectate_sending:!
    - if !<player.is_online>:
      - stop
    - adjust <player> send_to:<[server]>

    on player closes inventory flagged:fort.spectate_menu:
    - flag player fort.spectate_menu:!
    - narrate "<&c>Closed Nimnite spectate menu."

get_prefix:
  type: procedure
  debug: false
  definitions: player
  script:
    - define prefix <[player].luckperms_primary_group.group_name||none>

    - choose <[prefix]>:
      - case helper:
        - define prefix <&a>[helper]<&r><&sp>
      - case mod:
        - define prefix <&9>[mod]<&r><&sp>
      - case admin:
        - define prefix <&c>[admin]<&r><&sp>
      - case owner:
        - define prefix <&7>[not<&sp>owner]<&r><&sp>
      - default:
        - define prefix <empty>

    - determine <[prefix]>

fort_spectate_bungee:
  type: task
  debug: false
  definitions: player
  script:
    - flag <[player]> joined_as_spectator

fort_spectate_command:
  type: command
  name: fort_spectate
  debug: false
  description: Open fortnite game server spectating menu.
  usage: /fort_spectate
  permission: fort.spectate
  aliases:
  - fspec
  script:
    - if <context.args.is_empty>:
      - define game_servers <bungee.list_servers.filter[starts_with[fort_]].exclude[fort_lobby].sort_by_number[after[_]]>
      
      - narrate "<&a>Opening current Nimnite game servers <&7>(<[game_servers].size>)"
      
      - define items <list[]>
      - foreach <[game_servers]> as:s:
        - define i <item[paper].with[display=<&a><&l>Game Server <[loop_index]>;flag=server:<[s]>;lore=<list[<&sp>|<&e>Click to spectate.]>]>
        - define items:->:<[i]>

      - inventory open d:<inventory[generic[title=Nimnite Game Servers (<[game_servers].size>);contents=<[items]>;size=9]]>
      - flag player fort.spectate_menu
      - stop 

    - define server_number <context.args.get[1]>
    - if <[server_number].is_numeric> && <[server_number]> >= 1 && <bungee.list_servers.filter[starts_with[fort_]].exclude[fort_lobby].sort_by_number[after[_]]>.size >= <[server_number]>:
      - define server_to_spectate <bungee.list_servers.filter[starts_with[fort_]].exclude[fort_lobby].sort_by_number[after[_]].get[<[server_number]>]>
      - narrate "<&a>Spectating server <&7><[server_to_spectate]>"
      - flag player fort.spectate_sending

      - bungeerun <[server_to_spectate]> fort_spectate_bungee def:<player>
      - wait 1s
      - stop 

    - narrate "<&c>Invalid server number. Please select a number between 1 and <bungee.list_servers.filter[starts_with[fort_]].exclude[fort_lobby].sort_by_number[after[_]]>.size>."

fort_admin_commands_2:
  type: command
  name: fortnite_menu
  debug: false
  description: Fortnite Menu Commands
  usage: /fortnite_menu
  permission: fort.menu
  aliases:
  - fort_menu
  script:
    #have no narrate messages or anything, this command is internal and should be hidden
    - choose <context.args.first||null>:
      - case party:
        - define option      <context.args.get[2]||null>
        - define from_uuid   <context.args.get[3]||null>
        - if <[from_uuid]> == null || <[from_uuid].as[player]||null> == null:
          - stop

        - choose <[option]>:
          - case accept:
            - narrate "<[beta_tag]> <&a>Accepted <&7>party invite from <[from_uuid].as[player].name>"
            #- flag <[]>

            - define party_members
            - playsound <player> sound:BLOCK_NOTE_BLOCK_BASS pitch:1
            - define line <&8><element[<&sp>].repeat[70].strikethrough>
            - narrate <[line]> targets:<[to]>
            - narrate "<[beta_tag]> <&a><[to_name]><&7> has joined the party." targets:<[to]>
            - narrate <[line]> targets:<[to]>

          - case deny:
            - define beta_tag <element[<&b><&lb>Pre-Alpha<&rb>].on_hover[<&e>Party system is in pre-alpha.<n><&7>I sorta rushed to add this, so this whole thing is temp.]>
            - narrate "<[beta_tag]> <&c>Denied <&7>party invite from <[from_uuid].as[player].name>"
            - flag player fort.invites.<[from_uuid]>:!


fort_admin_commands:
  type: command
  name: fortnite
  debug: false
  description: Fortnite Setup Commands
  usage: /fortnite
  permission: fort.setup
  aliases:
  - fort
  tab completions:
    1: <list[models|lobby_setup|lobby_teleport|pregame_spawn|fill_chests|fill_ammo_boxes|supply_drop|mode]>
  script:
    - choose <context.args.first||null>:

      # - [ Set Whole Lobby Mode / Set game server mode ] - #
      - case mode:

        - define mode <context.args.get[2]||null>
        - if <[mode]> not in SOLO|DUOS|SQUADS:
          - narrate "<&c>Invalid mode."
          - stop

        # - [ Lobby ] - #
        - if <bungee.server> == fort_lobby:
          - define lobby_players <server.online_players_flagged[fort.menu.mode]>
          - define i <item[oak_sign].with[custom_model_data=<map[solo=14;duos=15;squads=16].get[<[mode]>]>]>
          - flag <[lobby_players]> fort.menu.mode:<[mode]>
          - foreach <[lobby_players]> as:p:
            - define button <[p].flag[fort.menu.mode_button]>
            - run fort_lobby_handler.press_anim def.button:<[button]>
            - adjust <[button]> item:<[i]>

          - flag <[lobby_players]> fort.menu.mode:<[mode]>
          - stop

        # - [ Game Server ] - #
        - if !<server.has_flag[fort.temp.available]>:
          - narrate "<&c>Cannot update mode while in-game."
          - stop

        - if <bungee.list_servers.contains[fort_lobby]>:
          - definemap data:
              game_server: <bungee.server>
              status: SET_MODE
              mode: <[mode]>
              players: <server.online_players_flagged[fort]>
          - bungeerun fort_lobby fort_bungee_tasks.set_data def:<[data]>

        - flag server fort.mode:<[mode]>
        - announce "<&b>[Nimnite]<&r> Mode set: <&e><[mode].to_titlecase>" to_console

      - case models:
        - inject fort_admin_commands.server_check
        - define containers <list[chest|ammo_box]>
        - define items      <[containers].parse_tag[<item[fort_<[parse_value]>]>]>

        - define props      <util.scripts.filter[name.starts_with[fort_prop_]].filter[data_key[type].equals[item]].parse[name.as[item]]>
        - define items      <[items].include[<[props]>]>

        - flag player fort.model_menu
        - inventory open d:<inventory[generic[contents=<[items]>;size=18]]>
        - narrate "<&a>Opened Nimnite models menu."


      # - [ In-Game Admin Commands ] - #
      - case force_start:
        - inject fort_admin_commands.server_check
        - if !<server.has_flag[fort.temp.available]>:
          - narrate "<&c>The game has already started."
          - stop

        - if <server.has_flag[fort.temp.game_starting]>:
          - narrate "<&c>The game is already starting."
          - stop

        - if <server.online_players_flagged[fort].size> < 2:
          - narrate "<&c>At least <&n>2<&c> players needed to start a game."
          - stop


        - flag server fort.temp.force_start
        - run pregame_island_handler.countdown

        - narrate "<&a>You forcefully started the game."
        - announce "<&7><&o>Game has been started by an admin."

      - case skip:
      #skip the phase
        - inject fort_admin_commands.server_check
        - flag server fort.temp.phase_skipped
        - narrate "<&a>Skipping current phase."

      - case pause:
        - inject fort_admin_commands.server_check
        - if !<server.has_flag[fort.temp.pause_phase]>:
          - flag server fort.temp.pause_phase
          - narrate "<&a>Game paused."
          - stop
        - flag server fort.temp.pause_phase:!
        - narrate "<&c>Game unpaused."

      # - [ SETUP COMMANDS ] - #
      - case lobby_setup:
        - inject fort_admin_commands.server_check
        - run fort_lobby_setup
        - narrate "<&a>Nimnite lobby circle set."

      - case lobby_teleport:
        #- define loc <player.location.round.above[0.5]>
        - inject fort_admin_commands.server_check
        - define loc <server.flag[fort.pregame.lobby_circle.loc]>
        - flag server fort.pregame.lobby_circle.loc:<[loc]>

        - define loc <[loc].with_pose[0,0]>
        - define circle <server.flag[fort.pregame.lobby_circle.circle]||null>
        - if <[circle]> != null && <[circle].is_spawned>:
          - remove <[circle]>

        - define text <server.flag[fort.pregame.lobby_circle.text]||null>
        - if <[text]> != null && <[text].is_spawned>:
          - remove <[text]>

        - define planes <server.flag[fort.pregame.lobby_circle.planes]||null>
        - flag server fort.pregame.lobby_circle.planes:!
        - if <[planes]> != null:
          - foreach <[planes]> as:pl:
            - remove <[pl]> if:<[pl].is_spawned>

        - define circle_icon <&chr[22].font[icons]>
        - spawn <entity[text_display].with[text=<[circle_icon]>;background_color=transparent;pivot=FIXED;scale=3,3,3]> <[loc].below[0.5].with_pitch[-90]> save:circle
        - flag server fort.pregame.lobby_circle.circle:<entry[circle].spawned_entity>

        #- define text <element[<&l>RETURN TO MENU].color_gradient[from=<color[#ffca29]>;to=<&e>]>
        - define text <&chr[23].font[icons]>
        - spawn <entity[text_display].with[text=<[text]>;background_color=transparent;pivot=CENTER;scale=1.35,1.35,1.35]> <[loc].above[2]> save:text
        - flag server fort.pregame.lobby_circle.text:<entry[text].spawned_entity>

        #-circular transparent outline
        #i think this might be off-center?
        - define radius 1.1
        - define cyl_height 1.7

        - define center <[loc].below[2.2]>

        - define circle <[center].points_around_y[radius=<[radius]>;points=16]>

        - foreach <[circle]> as:plane_loc:

          - define angle <[plane_loc].face[<[center]>].yaw.to_radians>
          - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

          #- define plane_loc <[plane_loc].face[<[loc]>]>
          #- define plane_loc <[plane_loc].with_yaw[<[plane_loc].yaw.mul[-1]>].with_pitch[0]>

          - spawn <entity[item_display].with[item=<item[white_stained_glass_pane].with[custom_model_data=2]>;translation=0,0.8,0;scale=1.2505,<[cyl_height]>,1.2505]> <[plane_loc].above[1.75].face[<[loc]>].with_pitch[0]> save:plane
          - define plane     <entry[plane].spawned_entity>
          - flag server fort.pregame.lobby_circle.planes:->:<[plane]>

        - define ellipsoid <[loc].to_ellipsoid[1.3,3,1.3]>
        - note <[ellipsoid]> as:fort_lobby_circle

        - run pregame_island_handler.lobby_circle.anim

      - case pregame_spawn:
        - flag server fort.pregame.spawn:<player.location.round.with_pose[0,-90]>
        - narrate "<&a>Nimnite pregame island spawn set."

      - case chest:
        #-much better to use the item instead and place them down
        - inject fort_admin_commands.server_check
        - define loc <player.location.center.above[0.1]>
        - if <[loc].material.name> != air:
          - narrate "<&c>Invalid spot."
          - stop
        - define text "<&7><&l>[<&e><&l>Sneak<&7><&l>] <&f><&l>Search"
        - define angle <player.location.forward.direction[<player.location>].yaw.mul[-1].to_radians>
        - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>
        - spawn ITEM_DISPLAY[item=<item[gold_nugget].with[custom_model_data=15]>;scale=1.25,1.25,1.25;left_rotation=<[left_rotation]>] <[loc]> save:chest
        - spawn TEXT_DISPLAY[text=<[text]>;pivot=center;scale=1,1,1;view_range=0.035;see_through=true] <[loc].above[0.75]> save:chest_text
        - modifyblock <[loc]> barrier
        - define loc <player.location.center>
        - flag <[loc]> fort.chest.model:<entry[chest].spawned_entity>
        - flag <[loc]> fort.chest.text:<entry[chest_text].spawned_entity>
        - flag <[loc]> fort.chest.yaw:<player.location.yaw.add[180].to_radians>
        #so it's not using the fx constantly when not in use
        - flag <[loc]> fort.chest.opened
        - flag server fort.chests:->:<[loc]>
        - narrate "<&a>Set chest at <&f><[loc].simple>"
      - case fill_chests fill_ammo_boxes:
        - inject fort_admin_commands.server_check
        - define container_type <map[fill_chests=chests;fill_ammo_boxes=ammo_boxes].get[<context.args.first>]>
        - define containers <player.world.flag[fort.<[container_type]>]||<list[]>>
        - narrate "<&7>Filling all <[container_type].replace[_].with[ ]>..."

        - foreach <[containers]> as:loc:
          - inject fort_chest_handler.fill_<map[chests=chest;ammo_boxes=ammo_box].get[<[container_type]>]>

        - narrate "<&a>All <[container_type].replace[_].with[ ]> have been filled <&7>(<[containers].size>)<&a>."

      - case supply_drop:
        - inject fort_admin_commands.server_check
        - define loc <player.location.with_pitch[0]>
        - run fort_chest_handler.send_supply_drop def:<map[loc=<[loc]>]>
        - narrate "<&a>Supply drop sent at <&f><[loc].simple><&a>."
      - default:
        - narrate "<&c>Invalid arg."

  server_check:
    - if <bungee.server||fort_lobby> == fort_lobby:
      - narrate "<&c>You're not on a valid server to run this command."
      - stop
