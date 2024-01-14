fort_bungee_handler:
  type: world
  debug: false
  events:
    #-in case the server closes and it reopens thinking a game server is open even though it isn't
    on bungee server connects:
    - if <context.server> == fort_lobby && <bungee.server> != fort_lobby && <bungee.server.starts_with[fort_]>:
      - define status <server.has_flag[fort.temp.available].if_true[AVAILABLE].if_false[UNAVAILABLE]>
      - definemap data:
          game_server: <bungee.server>
          status: <[status]>
          mode: <server.flag[fort.mode]||solo>
          players: <server.online_players_flagged[fort]>
      - bungeerun fort_lobby fort_bungee_tasks.set_data def:<[data]>

    on bungee server disconnects:
    - if <context.server> != fort_lobby && <context.server.starts_with[fort_]>:
      - define closed_server <context.server>
      - if <bungee.server> == fort_lobby:
        - foreach <list[solo|duos|squads]> as:mode_type:
          - define available_servers <server.flag[fort.available_servers.<[mode_type]>].keys||<list[]>>
          - if <[available_servers].filter[equals[<[closed_server]>]].any>:
            - define mode <[mode_type]>
            - foreach stop

        - if <[mode].exists>:
          - definemap data:
              game_server: <[closed_server]>
              status: UNAVAILABLE
              mode: <[mode]>
          #send all the player data, or just remove the current one?
          - run fort_bungee_tasks.set_data def:<[data]>

    ###change this later down the road
    on bungee player joins network:
    #only run it on one server, so it doesn't repeat
    #waiting one second to prevent spam joining/rejoining so it makes sure players are on the server
    - if <bungee.server> == fort_lobby:
      - wait 2s
      - bungeerun backup discord_join def:<map[name=<context.name>;uuid=<context.uuid>;status=join]> if:<player.is_online>

    on bungee player leaves network:
    - if <bungee.server> == fort_lobby:
      #- if <server.flag[whitelist].contains[<context.name>]>:
      - bungeerun backup discord_join def:<map[name=<context.name>;uuid=<context.uuid>;status=leave]>
    ###dont keep it here

    - if <bungee.server> != fort_lobby:
      - stop
    #-only announce this in the fort lobby, not in-game
    - define name <context.name>
    - announce "<&chr[0002].font[denizen:announcements]> <&9><[name]>"
    - announce to_console "<&8><&lb><&c>-<&8><&rb> <&f><[name]>"



fort_bungee_tasks:
  type: task
  debug: false
  definitions: data
  script:
    - narrate "do bungee tings"
  set_data:

    #instead of having available_servers flag, have only .servers flag and have a status key?

    - define game_server <[data].get[game_server]>
    - define status      <[data].get[status]>
    - define mode        <[data].get[mode]>

    - choose <[status]>:
      - case AVAILABLE:
        - define players     <[data].get[players]>
        - flag server fort.available_servers.<[mode]>.<[game_server]>.players:<[players]>
        - announce "<&b>[Nimnite]<&r> Game server <&b><[game_server]><&r> is now <&a>AVAILABLE<&r>. Mode: <&e><[mode]>" to_console
      - case UNAVAILABLE:
        - flag server fort.available_servers.<[mode]>.<[game_server]>:!
        - announce "<&b>[Nimnite]<&r> Game server <&b><[game_server]><&r> is now <&c>CLOSED<&r>" to_console
      - default:
        - flag server fort.available_servers.<[mode]>.<[game_server]>:!