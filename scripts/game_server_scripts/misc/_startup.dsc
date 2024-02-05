fort_startup_events:
  type: world
  debug: false
  events:
    on server start:

    #clear anything from the previous match
    - flag server fort.temp:!
    - flag server fort.temp.startup
    - announce "<&b>[Nimnite]<&r> Getting ready for startup..." to_console
    #5 seconds
    - wait 3s
    - announce "-------------------- [ <&b>NIMNITE GAME SERVER STARTUP <&r>] --------------------" to_console


    #connect to db
    - ~mongo id:nimnite_playerdata connect:<secret[nimbus_db]> database:Nimnite collection:Playerdata
    - announce "<&b>[Nimnite]<&r> Connected to the Nimbus database with id <&dq><&a>nimnite_playerdata<&r><&dq>" to_console


    - if <util.has_file[../../nimnite_map]>:
      - ~createworld nimnite_map
      #-in case server was shut down during bus phase
      - run pregame_island_handler.bus_removal
      - adjust <world[nimnite_map]> destroy


    #do lobby setup here since the pregame island is being made too
    - ~filecopy origin:../../../../nimnite_map_template destination:../../nimnite_map overwrite
    - ~createworld nimnite_map
    - gamerule <world[nimnite_map]> randomTickSpeed 0

    - announce "<&b>[Nimnite]<&r> Created world <&dq><&a>nimnite_map<&r><&dq> from <&dq><&e>nimnite_map_template<&r><&dq>" to_console

    # - [ filling chests / ammo boxes ] - #
    #-get a check of all the
    #-mention the time elapsed for when filling all the chests?
    - foreach <list[chest|ammo_box]> as:container_type:
      - define containers <world[nimnite_map].flag[fort.<[container_type]>.locations]||<list[]>>
      - announce "<&b>[Nimnite]<&r> Filling <&e><[container_type]><&r> containers..." to_console

      #- define containers_filled 0
      #not really a need to fill the ammo boxes in advance, but eh? (it's not really being filled either, since it randomizes upon opening)
      - foreach <[containers]> as:loc:
          #there's a bunch of stuff we can leave out in these task scripts, since a new map is being added anyways. but eh
        - if !<[loc].chunk.is_loaded>:
          - define chunk <[loc].chunk>
          - chunkload <[chunk]> durations:8s

          #saving to unload the chunks after setup is complete
          ##unload all the chunks?
          - define loaded_chunks:->:<[chunk]>
        - inject fort_fill_container.<[container_type]>

        #wait every 2t for safety and prevent the crash thing
        - if <[container_type]> == CHEST && <[loop_index].mod[30].equals[0]>:
          #- announce "<&b>[Nimnite]<&r> Filling chests... <&e><[loop_index].div[<[containers].size>].mul[100].round><&f>%" to_console
          - wait 2t

        #- define containers_filled:++
        #- announce "<&b>[Nimnite]<&r> [DEBUG] <&e><[containers_filled]><&f>/<&a><[containers].size> <&f><[container_type]> filled." to_console

      - announce "<&b>[Nimnite]<&r> Done (<&a><[containers].size><&r> filled)" to_console

    - flag server fort.unopened_chests:<world[nimnite_map].flag[fort.chest.locations]||<list[]>>
    - run fort_chest_handler.all_chest_effects

   # - waituntil <[containers_to_fill].is_empty> rate:1s
   # - chunkload remove <[loaded_chunks]>

    - announce "<&b>[Nimnite]<&r> Setting all <&e>floor loot<&r>..." to_console
    - inject fort_floor_loot_handler.set_loot

    - adjust <material[leather_helmet]> max_stack_size:64
    #it's fine to change max stack size for gun materials, since they won't stack
    #because each gun has a unique uuid
    - adjust <material[leather_horse_armor]> max_stack_size:64

    #remove teams
    - foreach <server.scoreboard.team_names||<list[]>> as:team:
      - team name:<[team]> remove:<server.scoreboard.team[<[team]>].members>

    #reset the notable (since its also being used after victory)
    - define ellipsoid <server.flag[fort.pregame.lobby_circle.loc].to_ellipsoid[1.3,3,1.3]>

    - if <util.notes[ellipsoids].parse[note_name].contains[fort_lobby_circle]>:
      - note remove as:fort_lobby_circle

    - note <[ellipsoid]> as:fort_lobby_circle

    #create the storm circle off-rip (so the event doesn't break)
    - define diameter 2048
    - define storm_center <world[nimnite_map].spawn_location.with_y[20]>
    - define circle_radius <[diameter].div[2].round>
    - define storm_circle <[storm_center].to_ellipsoid[<[circle_radius]>,10000,<[circle_radius]>]>
    - if <util.notes[ellipsoids].parse[note_name].contains[fort_storm_circle]>:
      - note remove as:fort_storm_circle
    - note <[storm_circle]> as:fort_storm_circle

    #-instead of filtering out the pregame island circle, why not just re-set it up again?
    - define remove_entities <world[pregame_island].entities[dropped_item|text_display|item_display].filter[has_flag[fort.pregame].not]>
    - remove <[remove_entities]>

    - run pregame_island_handler.lobby_circle.anim
    - announce "<&b>[Nimnite]<&r> Set lobby circle animation in world <&dq><&e>fort_pregame_island<&r><&dq>" to_console

    - define bossbar fort_info
    - bossbar create <[bossbar]> title:<proc[spacing].context[50]><&chr[A004].font[icons]><proc[spacing].context[-72]><&l><element[WAITING FOR PLAYERS].font[lobby_text]> color:YELLOW players:<server.online_players>
    - announce "<&b>[Nimnite]<&r> Created bossbar <&dq><&e><[bossbar]><&r><&dq>" to_console

    - announce to_console "Waiting for bungee to connect..."
    - waituntil rate:1s <bungee.connected>

    - define mode <script[nimnite_config].data_key[game_servers.<bungee.server>.mode]||solo>
    - flag server fort.mode:<[mode]>

    #cache full map data
    #no reason to do this every startup, but idgaf
    - run tablist_map_handler.cache_map_tiles

    - announce "<&b>[Nimnite]<&r> Mode set: <&e><[mode].to_titlecase>" to_console

    - announce ------------------------------------------------------------------------- to_console
    - flag server fort.temp.startup:!

    #just for safety, wait a few seconds
    - wait 2s
    #players *should* always be 0, but in case someone somehow (like an op) joins this server manually
    - run enable_server

    - flag server fort.temp.available

enable_server:
  type: task
  debug: false
  script:
    - waituntil rate:1s <bungee.list_servers.contains[fort_lobby]>
    - definemap data:
        game_server: <bungee.server>
        status: AVAILABLE
        mode: <server.flag[fort.mode]>
        players: <server.online_players_flagged[fort]>
    # For whatever reason, bungeetag doesn't handle map defs
    - define mode <[data.mode]>
    - define game_server <[data.game_server]>
    - while true:
      - bungeerun fort_lobby fort_bungee_tasks.set_data def:<[data]>
      - wait 1s
      - ~bungeetag server:fort_lobby <server.has_flag[fort.available_servers.<[mode]>.<[game_server]>]> save:res
      # This is probably the only time where you will see a valid == true... sometimes the tag will not error but instead spit out gibberish.
      - if <entry[res].result||false> == true:
        - announce to_console "<&b>[Nimnite]<&r> Set this game server to <&a>AVAILABLE<&r> (<&b><[data].get[game_server]><&r>)."
        - stop
      - announce to_console "<&b>[Nimnite]<&r> Failed to connect to lobby, retrying in 1s..."
      - wait 1s
