##make sure to flag the server for different modes with "fort.mode"

##should we hide usernames when the player first joins, or no?#
#if not, then when the player emotes, their name tag disappears, maybe add a name tag
#for them? im too lazy for now

#this command breaks when switching worlds (name_tag_visibility)
apply_team_options:
  type: task
  debug: false
  definitions: name
  script:
    #- wait 10t
    - team name:<[name]> option:FRIENDLY_FIRE status:NEVER
    #so other teams can't see their names
    - team name:<[name]> option:NAME_TAG_VISIBILITY status:FOR_OTHER_TEAMS
    #so you can't see anyone that's invisible
    - team name:<[name]> option:SEE_INVISIBLE status:NEVER

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

##show names before the game starts?
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

    - remove <world[pregame_island].entities[dropped_item]>

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

    on player join:
    - determine passively "<&9><&l><player.name> <&7>joined the match"

    #clear previous fort flags in case it wasn't
    - flag player fort:!

    #in case they're invis
    - invisible <player> reset
    - teleport <player> <server.flag[fort.pregame.spawn].above.random_offset[10,0,10]>

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

    #in case they had shields from the last game
    - adjust <player> armor_bonus:0
    #in case they had the storm blind fx
    - adjust <player> remove_effects
    #so all houses/builds aren't dark
    - cast NIGHT_VISION duration:infinite no_ambient hide_particles no_icon no_clear

    - run update_hud
    - run minimap

    #for future purpose maybe?
    #- team name:Pregame_Island add:<player.name>

    - wait 10t
    #update this to empty?
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

    #when this flag happens, it means the player was sent to the lobby
    - if <server.has_flag[fort.temp.unexpected_shutdown]>:
      - stop

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
    #OR if they're on the bus
    - if !<player.has_flag[fort.lobby_teleport]> && !<player.has_flag[fort.spectating]>:
      - run fort_death_handler.death def:<map[quit=true;loc=<player.location>]>

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

      #-bus engine revving + remove the return to lobby
      - if <[seconds]> == 1:
        - playsound <[players]> sound:ENTITY_MINECART_RIDING pitch:1 volume:0.1 if:<[seconds].equals[1]>

        #disable/remove lobby circle a second before
        - flag server fort.lobby_circle_enabled:!

      - wait 1s
      - define players <server.online_players_flagged[fort]>

      # - [ Force start mechanism ] - #
      #it's a little copy pasta, but i dont really care rn
      - if <server.has_flag[fort.temp.force_start]> && <[players].size> < 2:
        - bossbar update fort_info title:<proc[spacing].context[50]><&chr[A004].font[icons]><proc[spacing].context[-72]><&l><element[WAITING FOR PLAYERS].font[lobby_text]> color:YELLOW players:<[players]>
        - sidebar set_line scores:5 values:<element[<[clock_icon]> -].font[hud_text].color[<color[50,0,0]>]> players:<[players]>

        - flag server fort.temp:!
        #so this flag isn't removed (probably a better way to do this but eh)
        - flag server fort.temp.available
        - stop
      - else if !<server.has_flag[fort.temp.force_start]> && <[players].size> < <[min_players]>:
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


    # - Player Setup - #
    #teams automatically are removed when server restart (team command stuff moved to battle_bus.dsc because you switch worlds)

    #stop everyone from emoting
    - flag <[players]> fort.emote:!
    #use duration flags, or just remove the flags manually?
    #manually is more right duh
    #using .loading so players can't thank the bus drive before they're even on it
    - flag <[players]> fort.on_bus.loading
    #- flag <[players]> fort.disable_emotes duration:5s
    #prevent players from switching to build / cancel their build mode
    - flag <[players]> fort.disable_build duration:5s

    #wait for build to fully disable before updating hud
    - wait 3t
    - foreach <[players]> as:p:
      - adjust <[p]> item_slot:1
      - run update_hud player:<[p]>
    #in case they were invisible for some reason (case: mergu, even though emotes were disabled)
    - invisible <[players]> false
    #wait for emotes to stop, then send
    - wait 3t
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

      #can't remove the notable, otherwise it causes errors with the event
      #- if <util.notes[ellipsoids].parse[note_name].contains[fort_lobby_circle]>:
        #- note remove as:fort_lobby_circle

      #remove entities in case they weren't already (or if server shuts down)
      - remove <world[pregame_island].entities[text_display].filter[has_flag[lobby_circle_square]]>
      - flag server fort.lobby_circle_enabled:!
