fort_bungee_handler:
  type: task
  debug: false
  definitions: data
  script:
    - narrate "fort bungee tings"

  set_data:

    #instead of having available_servers flag, have only .servers flag and have a status key?

    - define game_server <[data].get[game_server]>
    - define status      <[data].get[status]>

    - choose <[status]>:
      - case AVAILABLE:
        - define mode        <[data].get[mode]>
        - define players     <[data].get[players]>
        - flag server fort.available_servers.<[mode]>.<[game_server]>.players:<[players]>
        - announce "<&b>[Nimnite]<&r> Game server <&b><[game_server]><&r> is now <&a>AVAILABLE<&r>. Mode: <&e><[mode]>" to_console
      - case UNAVAILABLE:
        - flag server fort.available_servers.<[mode]>.<[game_server]>:!
        - announce "<&b>[Nimnite]<&r> Game server <&b><[game_server]><&r> is now <&c>CLOSED<&r>" to_console
      - default:
        - flag server fort.available_servers.<[mode]>.<[game_server]>:!