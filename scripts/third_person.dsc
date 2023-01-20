third_person_test:
  type: task
  debug: false
  script:
  - if <player.has_flag[3p]>:
    - flag player 3p:!
    - narrate "<&c>3rd person removed"
    - stop

  - define prev_gamemode <player.gamemode>
  - define loc <player.location>

  - invisible
  - flag player 3p

  - spawn ARMOR_STAND[gravity=false;collidable=false;invulnerable=true;visible=true] <[loc].backward_flat[3]> save:mount
  - define mount <entry[mount].spawned_entity>

  - spawn ARMOR_STAND[gravity=false;collidable=false;invulnerable=true;visible=true] <[loc]> save:stand
  - define stand <entry[stand].spawned_entity>

  #mounting the player on the armor stand, even though they're spectating the armor stand,
  #so they can't "interact with self"
  - mount <player>|<[mount]>
  #- adjust <player> spectate:<[mount]>

  - while <player.is_online> && <player.has_flag[3p]>:
    - define player_loc <player.location>
    - define stand_loc <[stand].location.below[1.5]>
    - define mount_loc <[mount].location>

    - define yaw <[player_loc].yaw>
    - define pitch <[player_loc].pitch>

    - look <[stand]> yaw:<[yaw]> pitch:<[pitch]>

    - look <[mount]> <[stand_loc]>

    - teleport <[mount]> <[stand_loc].backward[3]>

    - wait 1t


  - teleport <player> <[loc]>
  - invisible false
  #- adjust <player> spectate:<player>
  - remove <[stand]>|<[mount]>
  - flag player 3p:!

3p_event_handler:
  type: world
  debug: false
  events:
    on player exits vehicle flagged:3p:
    - flag player 3p:!