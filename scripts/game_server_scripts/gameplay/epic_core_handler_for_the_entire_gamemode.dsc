##on server start, adjust the mining speed of all materials to a thing?

#todo:
##SET THE VICTORY FLAGS

fort_core_handler:
  type: task
  debug: false
  definitions: data
  #phases:
  #1) bus (doors will open in x)
  #2) fall (jump off bus)
  #3) grace_period
  #4) storm_shrink

  script:

  #-Doors open
  #doors open in 20 seconds
  #default: 20
  - define seconds 20
  - define phase   BUS
  - inject fort_core_handler.timer

  #-Bus drop
  #everybody off, last stop in 55 seconds
  #default: 55
  - define seconds 55
  - define phase   FALL
  - inject fort_core_handler.timer

  #-Storm forms
  #storm forming in 1 Minute
  #default : 60
  - define seconds       30
  - define phase         GRACE_PERIOD
  - define forming       FORMING
  - inject fort_core_handler.timer

  #injecting, since we gotta wait for the flag to generate
  - inject fort_storm_handler.create

  #-stage 1
  #storm eye shrinks in 3 minutes 20 seconds
  #default: 200
  - define seconds       30
  - define phase         GRACE_PERIOD
  - define forming:!
  - flag server fort.temp.storm.dps:1
  - ~run fort_storm_handler.set_new def.new_diameter:1600
  - inject fort_core_handler.timer
  #storm eye shrinking 3 minutes
  #default: 180
  - define seconds  140
  - define phase    STORM_SHRINK
  - run fort_storm_handler.resize def.seconds:<[seconds]>
  - inject fort_core_handler.timer

  #-stage 2
  #storm eye shrinks in 2 minutes
  #default: 120
  - define seconds       100
  - define phase         GRACE_PERIOD
  - ~run fort_storm_handler.set_new def.new_diameter:800
  - inject fort_core_handler.timer
  #storm eye shrinking 2 minutes
  - define seconds  100
  - define phase    STORM_SHRINK
  - run fort_storm_handler.resize def.seconds:<[seconds]>
  - inject fort_core_handler.timer

  #-stage 3
  #storm eye shrinks in 1 Minute 30 seconds
  #default: 90
  - define seconds       30
  - define phase         GRACE_PERIOD
  - flag server fort.temp.storm.dps:2
  - ~run fort_storm_handler.set_new def.new_diameter:400
  - inject fort_core_handler.timer
  #storm eye shrinking 1 Minute 30 seconds
  #default: 90
  - define seconds  75
  - define phase    STORM_SHRINK
  - run fort_storm_handler.resize def.seconds:<[seconds]>
  - inject fort_core_handler.timer

  #-stage 4
  #storm eye shrinks in 1 Minute 20 Seconds
  #default: 80
  - define seconds       20
  - define phase         GRACE_PERIOD
  - define new_diameter  200
  - flag server fort.temp.storm.dps:5
  - ~run fort_storm_handler.set_new def.new_diameter:200
  - inject fort_core_handler.timer
  #storm eye shrinking 1 Minute 10 seconds
  #default: 70
  - define seconds  60
  - define phase    STORM_SHRINK
  - run fort_storm_handler.resize def.seconds:<[seconds]>
  - inject fort_core_handler.timer

  #-stage 5
  #storm eye shrinks in 50 Seconds
  #default: 50
  - define seconds       15
  - define phase         GRACE_PERIOD
  - flag server fort.temp.storm.dps:8
  - ~run fort_storm_handler.set_new def.new_diameter:100
  - inject fort_core_handler.timer
  #storm eye shrinking 1 Minute
  #default: 60
  - define seconds  50
  - define phase    STORM_SHRINK
  - run fort_storm_handler.resize def.seconds:<[seconds]>
  - inject fort_core_handler.timer

  #-stage 6
  #storm eye shrinks in 30 Seconds
  #default: 30
  - define seconds       5
  - define phase         GRACE_PERIOD
  - flag server fort.temp.storm.dps:10
  - ~run fort_storm_handler.set_new def.new_diameter:50
  - inject fort_core_handler.timer
  #storm eye shrinking 1 Minute
  #default: 60
  - define seconds  50
  - define phase    STORM_SHRINK
  - run fort_storm_handler.resize def.seconds:<[seconds]>
  - inject fort_core_handler.timer

  #-stage 7
  #storm eye shrinking 55 seconds
  #default: 55
  - define seconds       45
  - define phase         STORM_SHRINK
  - ~run fort_storm_handler.set_new def.new_diameter:35
  - run fort_storm_handler.resize def.seconds:<[seconds]>
  - inject fort_core_handler.timer

  #-stage 8
  #storm eye shrinking 45 seconds
  #default: 45
  - define seconds      40
  - define phase        STORM_SHRINK
  - ~run fort_storm_handler.set_new def.new_diameter:20
  - run fort_storm_handler.resize def.seconds:<[seconds]>
  - inject fort_core_handler.timer

  #-stage 9
  #storm eye shrinking 1 Minute 15 seconds
  #default: 75
  - define seconds      55
  - define phase        STORM_SHRINK
  - ~run fort_storm_handler.set_new def.new_diameter:0
  - run fort_storm_handler.resize def.seconds:<[seconds]>
  - inject fort_core_handler.timer

  timer:
    #in cases that this script was run (ie during END phase)
    - if <[data].exists>:
      - define phase   <[data].get[phase]>
      - define seconds <[data].get[seconds]>

    - flag server fort.temp.phase:<[phase]>

    - define icon <&chr[<map[bus=0025;fall=0003;grace_period=B005;storm_shrink=0005;end=0004].get[<[phase]>]>].font[icons]>

    - define players <server.online_players_flagged[fort]>
    - run FORT_CORE_HANDLER.announcement_sounds.main

    - choose <[phase]>:
      - case bus:
        - run fort_bus_handler.start_bus
        #wait for the bus to actually spawn before startnig the timer
        #- waituntil <server.has_flag[fort.temp.bus.ready]>

        - define announce_icon <&chr[A025].font[icons]>
        - define text "DOORS WILL OPEN IN"
        - define +spacing <proc[spacing].context[89]>
        - define -spacing <proc[spacing].context[-97]>
      - case fall:
        - define announce_icon <&chr[B003].font[icons]>
        - define text "EVERYBODY OFF, LAST STOP IN"
        - define +spacing <proc[spacing].context[114]>
        - define -spacing <proc[spacing].context[-130]>
      - case grace_period:
        - define announce_icon <&chr[B006].font[icons]>
        - define text "STORM EYE <[FORMING]||SHRINKS> IN"

        - playsound <[players]> sound:BLOCK_BEACON_DEACTIVATE pitch:1.2 volume:0.3 if:!<[forming].exists>

        - if <[seconds]> <= 60:
          - define +spacing <proc[spacing].context[86]>
          - define -spacing <proc[spacing].context[-113]>
        - else:
          #1 min and x seconds
          - define +spacing <proc[spacing].context[113]>
          - define -spacing <proc[spacing].context[-141]>

        - if !<[forming].exists>:
          #-supply drops during grace period only? idk how it works...
          - run fort_chest_handler.random_supply_drop

      - case storm_shrink:
        - define announce_icon <&chr[A005].font[icons]>
        - define text "STORM EYE SHRINKING"

        - playsound <[players]> sound:ENTITY_ILLUSIONER_PREPARE_BLINDNESS pitch:0.9 volume:0.3

        - if <[seconds]> <= 60:
          - define +spacing <proc[spacing].context[82]>
          - define -spacing <proc[spacing].context[-112]>
        - else:
          #1 min and x seconds
          - define +spacing <proc[spacing].context[109]>
          - define -spacing <proc[spacing].context[-138]>

      #-victory end timer
      - case end:
        - define announce_icon <&chr[A004].font[icons]>
        - define text "MATCH ENDING"
        - define +spacing <proc[spacing].context[65]>
        - define -spacing <proc[spacing].context[-89]>

    - repeat <[seconds]>:

      - if <server.has_flag[fort.temp.pause_phase]>:
        - announce "<&7><&o>Game has been paused by an admin."
        - waituntil !<server.has_flag[fort.temp.pause_phase]> rate:1s

      #for some reason it includes npcs?
      - define players      <server.online_players_flagged[fort].filter[is_npc.not]>
      - define seconds_left <[seconds].sub[<[value]>]>
      - define timer        <time[2069/01/01].add[<[seconds_left]>].format[m:ss]>

      #flag is for hud
      - flag server fort.temp.timer:<[timer]>
      - flag server fort.temp.timer_seconds:<[seconds_left]>
      - sidebar set_line scores:5 values:<element[<[icon]> <[timer]>].font[hud_text].color[<color[50,0,0]>]> players:<[players]>

      - if <[phase]> == GRACE_PERIOD && !<[forming].exists> && <[seconds_left]> == 12:
        - run FORT_CORE_HANDLER.announcement_sounds.tick_tock

      #do this in a separate task?
      #-turn this info into titles instead of bossbars?
      - if <[value]> <= 5:
        - bossbar update fort_info title:<[+spacing]><[announce_icon]><[-spacing]><&l><[text].font[lobby_text]><&sp><&d><&l><[seconds_left].as[duration].formatted_words.to_titlecase.font[lobby_text]> color:YELLOW players:<[players]>
      - else if <[value]> == 6:
        - bossbar update fort_info title:<empty> color:YELLOW players:<[players]>

      #-if the match has ended
      - if <[phase]> != END && <server.flag[fort.temp.phase]> == END:
        - stop

      - if <server.has_flag[fort.temp.restarting_server]>:
        - stop

      - if <server.has_flag[fort.temp.phase_skipped]>:
        - announce "<&7><&o>This phase was skipped by an admin."
        - flag server fort.temp.phase_skipped:!
        - repeat stop


      - wait 1s

    #-send players back to lobby
    - if <[phase]> == end:
      - inject fort_core_handler.reset_server

  ## - [ GAME END ] - ##

  victory_check:
    #alive TEAMS for support for duos and squads
    - define dead_player   <[data].get[dead_player]>
    - define death_loc     <[dead_player].location>
    #excluding dead player, since the fort.spectating flag is applied *after* this check is run
    - define alive_players <server.online_players_flagged[!fort.spectating].exclude[<[dead_player]>]>
    - define alive_teams   <[alive_players].parse[scoreboard_team_name].deduplicate>
    - if <[alive_teams].size> > 1:
      - stop

    - run fort_core_handler.timer def:<map[phase=END;seconds=30]>

    #team name is the team captain's name
    - define winning_team <[alive_teams].first>
    #not using <[alive_players]> in case team member died, but the team still won
    - define winners <server.online_players_flagged[fort].filter[scoreboard_team_name.equals[<[winning_team]>]]>

    #winning title
    - title title:<&chr[10].font[icons].color[<color[77,0,0]>]> fade_in:0 fade_out:0 stay:1m targets:<[winners]>
    - playsound <[winners]> sound:ENTITY_PLAYER_LEVELUP pitch:0

    - flag <[winners]> fort.winner
    - flag server fort.temp.winners:<[winners]>

    #wait for elim text and anything else to disappear
    - wait 1s

    - while <[winners].filter[is_online].any>:
      #-do it every 2s so winner title shows up still
      - title title:<&chr[10].font[icons].color[<color[77,0,0]>]> fade_in:0 fade_out:0 stay:1m targets:<[winners].filter[is_online]>
      - actionbar <&chr[1].font[elim_text]><element[<&e><&l>Double-Sneak <&f>to <&c>leave<&r> the match.].font[elim_text]> targets:<[winners].filter[is_online]>
      - wait 2s

  reset_server:
    #in case this was fired multiple times and it's already running
    - if <server.has_flag[fort.temp.restarting_server]>:
      - stop
    - flag server fort.temp.restarting_server
    - define players <server.online_players>
    - if <[players].any>:
      - if <bungee.list_servers.contains[fort_lobby]>:
        - foreach <[players]> as:p:
          - adjust <[p]> send_to:fort_lobby
      - else:
        - kick <[players]> "reason:<&r>The <&b>Nimnite lobby menu<&r> is currently offline. Rejoin later!"
    - announce to_console "<&b>[Nimnite]<&r> Match ended. Saving player data..."

    - define mode         <server.flag[fort.mode]||solo>
    - define winner_uuids <server.flag[fort.temp.winners].parse[uuid]>

    # - [ Save Player KILLS ] - #

    # In the future, i wanna change this to modifying the data, and then only inserting/updating it on the db ONCE instead of using several mongo commands
    - define players_that_played <server.flag[fort.temp.total_players]>
    - foreach <[players_that_played]> as:p:

      #*just in case* the data stacks (which i dont think should be possible)
      - define created_data:!
      - define new_data:!
      - define old_data:!

      #i dont think we have to erase, since it overrides but just in case ig
      - define uuid <[p].uuid>
      - define current_kills  <server.flag[fort.temp.kills.<[uuid]>]||0>
      - define current_deaths <server.flag[fort.temp.deaths.<[uuid]>]||0>

      - ~mongo id:nimnite_playerdata find:[_id=<[uuid]>] save:pdata_<[uuid]>
      - define pdata <entry[pdata_<[uuid]>].result>
      - if <[pdata].is_empty>:

        - define created_data._id:<[uuid]>
        - define created_data.<[mode]>.kills:<[current_kills]>
        - define created_data.<[mode]>.deaths:<[current_deaths]>
        - define created_data.<[mode]>.games_played:1

        # - [ Save Player WINS ] - #
        - if <[winner_uuids].contains[<[uuid]>]>:
          - define created_data.<[mode]>.wins:1

        - ~mongo id:nimnite_playerdata insert:<[created_data]>
      - else:
        - define total_kills       <[pdata].first.parse_yaml.get[<[mode]>].get[kills]||0>
        - define new_total_kills   <[total_kills].add[<[current_kills]>]>

        - define total_deaths      <[pdata].first.parse_yaml.get[<[mode]>].get[deaths]||0>
        - define new_total_deaths  <[total_deaths].add[<[current_deaths]>]>

        - define total_games_played     <[pdata].first.parse_yaml.get[<[mode]>].get[games_played]||0>
        - define new_total_games_played <[total_games_played].add[1]>

        - define total_wins     <[pdata].first.parse_yaml.get[<[mode]>].get[wins]||0>

        - define old_data._id:<[uuid]>
        - define new_data.$set.<[mode]>.kills:<[new_total_kills]>
        - define new_data.$set.<[mode]>.deaths:<[new_total_deaths]>
        - define new_data.$set.<[mode]>.games_played:<[new_total_games_played]>

        # - [ Save Player WINS ] - #
        - if <[winner_uuids].contains[<[uuid]>]>:
          - define new_total_wins <[total_wins].add[1]>
          - define new_data.$set.<[mode]>.wins:<[new_total_wins]>
        - else:
          #so you retain previous win data
          - define new_data.$set.<[mode]>.wins:<[total_wins]>

        - ~mongo id:nimnite_playerdata update:<[old_data]> new:<[new_data]>

    - bungeerun fort_lobby fort_bungee_tasks.update_playerdata_cache def:<map[players=<[players_that_played].escaped>]>
    - announce to_console "<&b>[Nimnite]<&r>Restarting server..."
    - wait 5s
    - adjust server restart

  #put this path into somewhere in pregame_island, or just put the lobby circle in its own file entirely?
  spawn_lobby_circle:
    - spawn <entity[text_display].with[text=<&chr[22].font[icons]>;background_color=transparent;pivot=FIXED;scale=0,0,0]> <[loc]> save:circle
    - define blue_circle <entry[circle].spawned_entity>

    #-circular transparent outline
    #i think this might be off-center?
    - define radius 1.1
    - define cyl_height 1.7

    - define center <[loc].below[2.2]>

    - define circle <[center].points_around_y[radius=<[radius]>;points=16]>

    - foreach <[circle]> as:plane_loc:

      - define angle <[plane_loc].face[<[center]>].yaw.to_radians>
      - define left_rotation <quaternion[0,1,0,0].mul[<location[0,-1,0].to_axis_angle_quaternion[<[angle]>]>]>

      - spawn <entity[item_display].with[item=<item[white_stained_glass_pane].with[custom_model_data=2]>;translation=0,0.8,0;scale=1.2505,0,1.2505]> <[plane_loc].above[1.35].face[<[loc]>].with_pitch[0]> save:plane
      - define planes:->:<entry[plane].spawned_entity>

    - wait 2t

    - adjust <[blue_circle]> interpolation_start:0
    - adjust <[blue_circle]> scale:3,3,3
    - adjust <[blue_circle]> interpolation_duration:4t

    - wait 4t

    - foreach <[planes]> as:pl:
      - adjust <[pl]> interpolation_start:0
      - adjust <[pl]> scale:1.2505,<[cyl_height]>,1.2505
      - adjust <[pl]> translation:0,1.7,0
      - adjust <[pl]> interpolation_duration:4t

    - run pregame_island_handler.lobby_circle.anim def:<map[loc=<[loc]>;circle=<[blue_circle]>]>

    - define text <&chr[23].font[icons]>
    - spawn <entity[text_display].with[text=<[text]>;background_color=transparent;pivot=CENTER;scale=0,0,0]> <[loc].above[2.5]> save:text
    - define lobby_text <entry[text].spawned_entity>

    - wait 15t

    - adjust <[lobby_text]> interpolation_start:0
    - adjust <[lobby_text]> scale:1.35,1.35,1.35
    - adjust <[lobby_text]> interpolation_duration:4t

  ##make these sounds MIDI via noteblock studio & resourcepack instead? (that way when the server lags, the tune doesn't turn bad)
  announcement_sounds:
    main:
      - define players <server.online_players_flagged[fort]>
      - wait 15t
      - playsound <[players]> sound:BLOCK_NOTE_BLOCK_SNARE pitch:0.75 volume:0.1
      - wait 3.5t
      #-either _BIT or _XYLOPHONE idk
      - playsound <[players]> sound:BLOCK_NOTE_BLOCK_XYLOPHONE volume:0.3 pitch:0.7
      - wait 2t
      - playsound <[players]> sound:BLOCK_NOTE_BLOCK_XYLOPHONE volume:0.3 pitch:1.19
      - wait 2t
      - playsound <[players]> sound:BLOCK_NOTE_BLOCK_XYLOPHONE volume:0.3 pitch:0.898

    tick_tock:

    - define players <server.online_players_flagged[fort]>

    #for 12 seconds
    - repeat 15:
      #get louder over time
      - define vol <[value].mul[0.035]>

      - if <[value]> > 5 && <[value].mod[2]> == 0:
        #pitch is from 1.1 to 1.5
        #there's 5 of these sfx in 10 seconds
        #volume goes up to 0.35
        - define vol_ <[value].mul[0.0179]>
        #last one becomes a little quieter
        - if <[value]> == 14:
          - define vol_ 0.1
        - playsound <[players]> sound:BLOCK_BEACON_ACTIVATE pitch:<[value].mul[0.05].add[1]> volume:<[vol_]>

      - playsound <[players]> sound:BLOCK_NOTE_BLOCK_HAT pitch:1.85 volume:<[vol]>
      - wait 9t
      - playsound <[players]> sound:BLOCK_NOTE_BLOCK_HAT pitch:1.3 volume:<[vol]>
      - wait 9t

    bus_honk:
      - define players <server.online_players_flagged[fort]>
      - playsound <[players]> sound:BLOCK_NOTE_BLOCK_DIDGERIDOO pitch:1.415 volume:0.85
      - wait 4t
      - playsound <[players]> sound:BLOCK_NOTE_BLOCK_DIDGERIDOO pitch:1.415 volume:0.85
      - wait 6t
      - playsound <[players]> sound:BLOCK_NOTE_BLOCK_DIDGERIDOO pitch:1.415 volume:0.85