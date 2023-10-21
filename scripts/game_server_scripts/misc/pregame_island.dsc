
##make sure to flag the server for different modes with "fort.mode"

pregame_island_handler:
  type: world
  debug: false
  definitions: data
  events:

    on server start:

    #clear anything from the previous match
    - flag server fort.temp:!
    - flag server fort.temp.startup
    - announce "<&b>[Nimnite]<&r> Getting ready for startup..." to_console
    #5 seconds
    - wait 3s
    - announce "-------------------- [ <&b>NIMNITE GAME SERVER STARTUP <&r>] --------------------" to_console

    #two ways of doing the "copying" system:
    #1) copy the file, then create the world
    #2) have the template world on each server and use "copy_from" arg in createworld command

    #either createworld here, *or* just remove the world on shut down
    - if <util.has_file[../../nimnite_map]>:
      - ~createworld nimnite_map
      #-in case server was shut down during bus phase
      - run pregame_island_handler.bus_removal
      - adjust <world[nimnite_map]> destroy

    - ~filecopy origin:../../../../nimnite_map_template destination:../../nimnite_map overwrite
    - ~createworld nimnite_map

    - announce "<&b>[Nimnite]<&r> Created world <&dq><&a>nimnite_map<&r><&dq> from <&dq><&e>nimnite_map_template<&r><&dq>" to_console

    - foreach <list[chests|ammo_boxes]> as:container_type:
      - define containers <server.flag[fort.<[container_type]>]||<list[]>>
      - announce "<&b>[Nimnite]<&r> Filling all <&e><[container_type].replace[_].with[ ]><&r>..." to_console

      - foreach <[containers]> as:loc:
        - inject fort_chest_handler.fill_<map[chests=chest;ammo_boxes=ammo_box].get[<[container_type]>]>

      - announce "<&b>[Nimnite]<&r> Done (<&a><[containers].size><&r> filled)" to_console

    ##################SET FLOOR LOOT TOO
    - announce "<&b>[Nimnite]<&r> Setting all <&e>floor loot<&r>... <&c>Coming Soon." to_console
    #- announce "<&b>[Nimnite]<&r> Setting all <&e>floor loot<&r>..." to_console
    #- announce "<&b>[Nimnite]<&r> Done (<&a>0<&r>)" to_console

    #reset the notable (since its also being used after victory)
    - define ellipsoid <server.flag[fort.pregame.lobby_circle.loc].to_ellipsoid[1.3,3,1.3]>
    - note <[ellipsoid]> as:fort_lobby_circle

    #create the storm circle off-rip (so the event doesn't break)
    - define diameter 2048
    - define storm_center <world[nimnite_map].spawn_location.with_y[20]>
    - define circle_radius <[diameter].div[2].round>
    - define storm_circle <[storm_center].to_ellipsoid[<[circle_radius]>,10000,<[circle_radius]>]>
    - note <[storm_circle]> as:fort_storm_circle

    - remove <world[pregame_island].entities[dropped_item]>

    - run pregame_island_handler.lobby_circle.anim
    - announce "<&b>[Nimnite]<&r> Set lobby circle animation in world <&dq><&e>fort_pregame_island<&r><&dq>" to_console

    - define bossbar fort_info
    - bossbar create <[bossbar]> title:<proc[spacing].context[50]><&chr[A004].font[icons]><proc[spacing].context[-72]><&l><element[WAITING FOR PLAYERS].font[lobby_text]> color:YELLOW players:<server.online_players>
    - announce "<&b>[Nimnite]<&r> Created bossbar <&dq><&e><[bossbar]><&r><&dq>" to_console
    - announce ------------------------------------------------------------------------- to_console
    - flag server fort.temp.startup:!

    #just for safety, wait a few seconds
    - wait 2s
    #players *should* always be 0, but in case someone somehow (like an op) joins this server manually
    - if <bungee.list_servers.contains[fort_lobby]>:
      - definemap data:
          game_server: <bungee.server>
          status: AVAILABLE
          mode: <server.flag[fort.mode]||solo>
          players: <server.online_players_flagged[fort]>
      #- define data <map[game_server=<bungee.server>;status=AVAILABLE;mode=<server.flag[fort.mode]||solo>;players=<server.online_players_flagged[fort]>]>
      - bungeerun fort_lobby fort_bungee_tasks.set_data def:<[data]>
      - announce "<&b>[Nimnite]<&r> Set this game server to <&a>AVAILABLE<&r> (<&b><[data].get[game_server]><&r>)." to_console

    - flag server fort.temp.available

    on player join:
    - determine passively "<&9><&l><player.name> <&7>joined the match"

    #clear previous fort flags in case it wasn't
    - flag player fort:!

    #in case they're invis
    - invisible <player> reset
    - teleport <player> <server.flag[fort.pregame.spawn].random_offset[10,0,10]>

    - flag player fort.wood.qty:0
    - flag player fort.brick.qty:0
    - flag player fort.metal.qty:0

    - flag player fort.kills:0

    - foreach <list[light|medium|heavy|shells|rockets]> as:ammo_type:
      - flag player fort.ammo.<[ammo_type]>:0

    - heal
    - adjust <player> gamemode:survival
    - inventory clear
    - give fort_pickaxe_default slot:1
    - adjust <player> item_slot:1

    #in case they had the storm blind fx
    - adjust <player> remove_effects
    #so all houses/builds aren't dark
    - cast NIGHT_VISION duration:infinite no_ambient hide_particles no_icon no_clear

    - run update_hud
    - run minimap

    - wait 10t
    - bossbar update fort_info color:YELLOW players:<player>

    - define players <server.online_players_flagged[fort]>

    - define alive_icon <&chr[0002].font[icons]>
    - define alive      <element[<[players].size>].font[hud_text]>
    - define alive_     <element[<[alive_icon]> <[alive]>].color[<color[51,0,0]>]>

    #update the player count for everyone
    - sidebar set_line scores:4 values:<[alive_]> players:<[players]>

    #-start countdown if there are enough people ready
    #second check is in case more people join during the countdown and it still going on, dont start another one
    #wait a bit after the last person before starting the queue
    - wait 2s
    - if <[players].size> >= <script[nimnite_config].data_key[minimum_players]> && !<server.has_flag[fort.temp.game_starting]>:
      - run pregame_island_handler.countdown

    # - [ Return to Lobby Menu ] - #
    on player enters fort_lobby_circle:
    - flag player fort.lobby_teleport
    - title title:<&font[denizen:black]><&chr[0004]><&chr[F801]><&chr[0004]> fade_in:7t stay:0s fade_out:1s
    - cast LEVITATION duration:8t amplifier:3 no_ambient no_clear no_icon hide_particles
    - wait 7t
    - adjust <player> send_to:fort_lobby

    on player quit:
    #remove quit message
    - if <server.online_players.exclude[<player>].size> == 0:
      - remove <world[pregame_island].entities[text_display].filter[has_flag[lobby_circle_square]]>

    #if it's still in the pregame lobbe island
    - if <server.has_flag[fort.temp.available]>:
      - definemap data:
          game_server: <bungee.server>
          status: AVAILABLE
          mode: <server.flag[fort.mode]||solo>
          players: <server.online_players_flagged[fort]>
      #send all the player data, or just remove the current one?
      - bungeerun fort_lobby fort_bungee_tasks.set_status def:<[data]>
      - determine passively "<&9><&l><player.name> <&7>quit"
      #so update the pregame island (since if they leave via lobby teleport circle, the death event wont fire)
      - if <player.has_flag[fort.lobby_teleport]>:
        - define players       <server.online_players_flagged[fort].exclude[<player>]>
        - define alive_icon <&chr[0002].font[icons]>
        - sidebar set_line scores:4 values:<element[<[alive_icon]> <[players].size>].font[hud_text].color[<color[51,0,0]>]> players:<[players]>

    - else:
      - determine passively NONE

    #don't play the death animation if they are teleporting via the circle or they're spectating (already dead)
    - if !<player.has_flag[fort.lobby_teleport]> && !<player.has_flag[fort.spectating]>:
      - run fort_death_handler.death def:<map[quit=true]>

    - flag player fort:!

    #-if nobody is left on the server (there's no need to wait the whole 1 minute before server restarting)
    - if <server.flag[fort.temp.phase]||null> == END && <server.online_players_flagged[fort].filter[has_flag[fort.spectating].not].is_empty>:
      - inject fort_core_handler.reset_server

  countdown:
    - define min_players <script[nimnite_config].data_key[minimum_players]>
    - define +spacing    <proc[spacing].context[99]>
    - define -spacing    <proc[spacing].context[-121]>
    - define bus_icon    <&chr[A025].font[icons]>
    - define clock_icon  <&chr[0004].font[icons]>

    - run FORT_CORE_HANDLER.announcement_sounds.bus_honk
    - run FORT_CORE_HANDLER.announcement_sounds.main

    - flag server fort.temp.game_starting
    #flagging phase for hud updating manually too
    - flag server fort.temp.phase:bus
    - repeat 10:
      - define players <server.online_players_flagged[fort]>
      - define seconds <element[10].sub[<[value]>]>
      - define timer <time[2069/01/01].add[<[seconds]>].format[m:ss]>

      - flag server fort.temp.timer:<[timer]>

      - bossbar update fort_info title:<[+spacing]><[bus_icon]><[-spacing]><&l><element[BATTLE BUS LAUNCHING IN].font[lobby_text]><&sp><element[<&d><&l><[seconds]> Seconds].font[lobby_text]> color:YELLOW players:<[players]>
      - sidebar set_line scores:5 values:<element[<&chr[0025].font[icons]> <[timer]>].font[hud_text].color[<color[50,0,0]>]> players:<[players]>

      #-bus engine revving
      - playsound <[players]> sound:ENTITY_MINECART_RIDING pitch:1 volume:0.1 if:<[seconds].equals[1]>
      - wait 1s
      - define players <server.online_players_flagged[fort]>
      - if <[players].size> < <[min_players]>:
        - bossbar update fort_info title:<proc[spacing].context[50]><&chr[A004].font[icons]><proc[spacing].context[-72]><&l><element[WAITING FOR PLAYERS].font[lobby_text]> color:YELLOW players:<[players]>
        - sidebar set_line scores:5 values:<element[<[clock_icon]> -].font[hud_text].color[<color[50,0,0]>]> players:<[players]>

        - flag server fort.temp:!
        #so this flag isn't removed (probably a better way to do this but eh)
        - flag server fort.temp.available
        - stop

    - definemap data:
        game_server: <bungee.server>
        status: UNAVAILABLE
        mode: <server.flag[fort.mode]||solo>
    #send all the player data, or just remove the current one?
    - bungeerun fort_lobby fort_bungee_tasks.set_data def:<[data]>
    - announce "<&b>[Nimnite]<&r> Set this game server to <&c>CLOSED<&r> (<&b><[data].get[game_server]><&r>)." to_console

    #in case lobby restarts, let it know on startup that it's no longer available
    - flag server fort.temp.available:!

    #stop lobby circle animation
    - flag server fort.lobby_circle_enabled:!

    # - Player Setup - #
    #teams automatically are removed when server restart

    #in parties, the team name would be the name of the party leader
    - foreach <[players]> as:p:
      - define name <[p].name>
      - team name:<[name]> add:<[p]>
      - team name:<[name]> option:FRIENDLY_FIRE status:NEVER
      #so other teams can't see their names
      - team name:<[name]> option:NAME_TAG_VISIBILITY status:FOR_OTHER_TEAMS
      #so you can't see anyone that's invisible
      - team name:<[name]> option:SEE_INVISIBLE status:NEVER


    - run fort_core_handler

  bus_removal:
    - if <server.has_flag[fort.temp.bus.model]>:
      - run dmodels_delete def.root_entity:<server.flag[fort.temp.bus.model]> if:<server.flag[fort.temp.bus.model].is_spawned>
      - flag server fort.temp.bus.model:!

    #we can also make the seats the keys, and the vectors the values
    - if <server.has_flag[fort.temp.bus.seats]>:
      - foreach <server.flag[fort.temp.bus.seats]> as:s:
        - remove <[s]> if:<[s].is_spawned>
      - flag server fort.temp.bus.seats:!

    - if <server.has_flag[fort.temp.bus.driver]>:
      - remove <server.flag[fort.temp.bus.driver]>
      - flag server fort.temp.bus.driver:!


  lobby_circle:
    anim:
      - define loc <[data].get[loc].above[0.3].with_pitch[0]||<server.flag[fort.pregame.lobby_circle.loc].with_pose[0,0]>>
      - define circle <[data].get[circle]||<server.flag[fort.pregame.lobby_circle.circle]>>

      #in case server was shut down incorrectly (or before a match was started)
      - remove <world[pregame_island].entities[text_display].filter[has_flag[lobby_circle_square]]>

      - flag server fort.lobby_circle_enabled

      - while <[circle].is_spawned> && <server.has_flag[fort.lobby_circle_enabled]>:

        - playsound <[loc]> sound:BLOCK_BEACON_AMBIENT pitch:1.2 volume:1.2 if:<[loop_index].mod[30].equals[1]>

        - adjust <[circle]> interpolation_start:0
        - adjust <[circle]> left_rotation:<quaternion[0,0,1,0].mul[<location[0,0,-1].to_axis_angle_quaternion[<[loop_index].div[85]>]>]>
        - adjust <[circle]> interpolation_duration:2t

        #-square
        #second check is if it's greater than 0, otherwise they'll keep on spawning and not be removed?
        - if <[loop_index].mod[6]> == 0 && <server.online_players_flagged[fort].size> > 0:
          - define size            <util.random.decimal[1.2].to[1.9]>
          - define origin          <[loc].below[0.4].random_offset[0.75,0,0.75]>
          - define end_translation 0,<util.random.decimal[1.8].to[2.6]>,0

          - spawn <entity[text_display].with[text=<element[⬛].color[#<list[D8F0FF|AAF4FF].random>]>;pivot=VERTICAL;scale=<[size]>,<[size]>,<[size]>;background_color=transparent]> <[origin]> save:fx
          - define fx <entry[fx].spawned_entity>
          - flag <[fx]> lobby_circle_square

          #wait 2t to fix backdrop
          - wait 2t

          - adjust <[fx]> interpolation_start:0
          - adjust <[fx]> translation:<[end_translation]>
          - adjust <[fx]> scale:0,0,0
          - adjust <[fx]> interpolation_duration:50t
          - run fort_death_handler.fx.remove_square def:<map[square=<[fx]>;wait=52]>
        - else:
          - wait 2t

      #remove entities in case they weren't already (or if server shuts down)
      - remove <world[pregame_island].entities[text_display].filter[has_flag[lobby_circle_square]]>
      - flag server fort.lobby_circle_enabled:!
