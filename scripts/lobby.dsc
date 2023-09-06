fort_lobby_handler:
  type: world
  debug: false
  definitions: player
  events:

    on player join:
    ##############remove this
    - if <player.name> != Nimsy:
      - stop

    - define uuid <player.uuid>

    #show hud
    - inject update_hud
    #show compass
    - run minimap

    #show "PLAY" button + socials
    - define play_icon <&chr[F000].font[icons]>
    - bossbar create lobby_<[uuid]> title:<[play_icon]> color:yellow players:<player>

    on player quit:
    - define uuid <player.uuid>
    - if <server.current_bossbars.contains[lobby_<[uuid]>]>:
      - bossbar remove lobby_<[uuid]>

  play_button_anim:
  - define uuid <[player].uuid>
  - repeat 8:
    #in case the bar is removed
    - if !<server.current_bossbars.contains[lobby_<[uuid]>]>:
      - stop
    - define icon <&chr[F00<[value]>].font[icons]>
    - bossbar update lobby_<[uuid]> title:<[icon]> color:yellow players:<[player]>
    - wait 1t
  - bossbar update lobby_<[uuid]> title:<&chr[F000].font[icons]> color:yellow players:<[player]>



