minimap:
  type: task
  debug: false
  script:
  - if <player.has_flag[minimap]>:
    - flag player minimap:!
    - narrate "<&c>minimap removed"
    - stop

  - define uuid <player.uuid>

  - define bb minimap_<player.uuid>
  - bossbar create <[bb]>
  - flag player minimap

  - while <player.is_online> && <player.has_flag[minimap]>:


    #turn loc to color
    - define loc <player.location.round>

    - define r <[loc].x.mod[256]>
    - define g <[loc].z.mod[256]>

    #can't be 0
    - if <[r]> < 0:
      - define r <[r].add[256]>
    - if <[g]> < 0:
      - define g <[g].add[256]>

    - define tiles:!
    - repeat 4:
      #value is display id
      - define display_id <map[1=3;2=1;3=2;4=4].get[<[value]>]>
      - define loc_to_color <color[<[r]>,<[g]>,<[display_id]>]>
      - define tiles:->:<&chr[000<[value]>].font[map].color[<[loc_to_color]>]>

    - define whole_map <[tiles].unseparated>

    - define title "minimap <[whole_map]>"

    - bossbar update <[bb]> title:<[title]>
    - wait 1t

  - flag player minimap:!
  - if <server.current_bossbars.contains[<[bb]>]>:
    - bossbar remove <[bb]>