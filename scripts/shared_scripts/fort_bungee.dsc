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
    - define mode        <[data].get[mode]>

    - choose <[status]>:
      - case AVAILABLE:
        - flag server fort.available_servers.<[mode]>.<[game_server]>.players:<[data].get[players]>
      - case UNAVAILABLE:
        - flag server fort.available_servers.<[mode]>.<[game_server]>:!
      - default:
        - flag server fort.available_servers.<[mode]>.<[game_server]>:!