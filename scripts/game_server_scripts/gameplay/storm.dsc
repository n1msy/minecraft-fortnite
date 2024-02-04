fort_storm_info:
  type: data
  # - Some stuff for understanding what the storm flags are and what they're used for - #

  fort.temp.storm.diameter: the LIVE (current) diameter of the storm. this is updated while the storm changes size.
  fort.temp.storm.center:   the LIVE (current) center of the storm. this is also updated while the storm transforms.

  fort.temp.storm.new_diameter: the diameter's end size of the storm.
  fort.temp.storm.new_center: the center's end destination of the storm.

fort_storm_handler:
  type: world
  debug: false
  definitions: new_diameter|seconds
  events:

    # - [ EXITING THE STORM ] - #
    #checking flagged: so it doesn't fire multiple times
    on player enters fort_storm_circle flagged:fort.in_storm:
    - inject fort_storm_handler.exit_storm

    # - [ ENTERING THE STORM ] - #
    on player exits fort_storm_circle flagged:!fort.in_storm:
    - inject fort_storm_handler.enter_storm

  exit_storm:
    #in case they already aren't in the storm
    - if !<player.has_flag[fort.in_storm]>:
      - stop

    - flag player fort.in_storm:!
    - cast BLINDNESS remove
    - playsound <player> sound:BLOCK_BEACON_POWER_SELECT pitch:1.5 volume:0.5
    - adjust <player> stop_sound:minecraft:ambient.basalt_deltas.loop
    #- time player reset
    - weather player reset
    - cast SPEED remove

  enter_storm:
    - if <player.has_flag[fort.in_storm]> || <player.has_flag[fort.spectating]>:
      - stop

    - flag player fort.in_storm
    #remember: night vision plays a part in showing the purple sky
    - cast BLINDNESS duration:10t hide_particles no_ambient no_icon no_clear
    - cast SPEED amplifier:2 duration:infinite hide_particles no_icon no_ambient no_clear
    - cast BLINDNESS duration:infinite hide_particles no_icon no_ambient no_clear
    - playsound <player> sound:BLOCK_BEACON_POWER_SELECT pitch:1.25 volume:0.5
    #- time player 13000
    - weather player storm
    - while <player.is_online> && !<player.has_flag[fort.spectating]> && <player.has_flag[fort.in_storm]>:
      #cancel the sprint in case they were sprinting when coming into the storm
      - adjust <player> sprinting:false if:<player.is_sprinting>
    #.mod should be like at mod[28.5], so there's a tiny pause between the sounds, but it's fine honestly
      - playsound <player> sound:AMBIENT_BASALT_DELTAS_LOOP pitch:1.5 volume:0.3 if:<[loop_index].mod[29].equals[2]>

      #cooldown check, this way, the timing of the lightning is not based on when players entered the storm
      #happens thirty percent of the time
      - if !<server.has_flag[fort.temp.storm.thunder_cooldown]> && <util.random_chance[10]>:
        - define storm_players <server.online_players_flagged[fort.in_storm]>
        - define random_loc <[storm_players].random.location.add[<location[40,0,0].rotate_around_y[<util.random.int[0].to[360].to_radians>]>].highest>
        - if <[random_loc]> != null && <[random_loc].is_in[fort_storm_circle].not>:
          - strike <[random_loc]> no_damage
          - flag server fort.temp.storm.thunder_cooldown duration:2s

      - wait 1s
      - if !<player.is_online>:
        - stop
      - define loc <player.location.above>
      - playeffect effect:ELECTRIC_SPARK at:<[loc]> offset:0.33 quantity:10 visibility:30
      - playeffect effect:REDSTONE at:<[loc]> offset:0.3 quantity:10 special_data:1.2|<color[#ec73ff]>
      - playsound <player> sound:BLOCK_LARGE_AMETHYST_BUD_BREAK pitch:2 volume:0.45
      - hurt <server.flag[fort.temp.storm.dps].div[5]||0.2> cause:WORLD_BORDER

  ## - [ CREATE STORM ] - ##
  create:
    #- execute as_server "globaldisplay destroy storm"
    #- flag server fort.temp.storm:!

    ##

    - define diameter 2350

    #center is the world's spawn
    - define storm_center <world[nimnite_map].spawn_location.with_y[20]>

    - execute as_server "globaldisplay create storm paper{CustomModelData:19} <[storm_center].x> <[storm_center].y> <[storm_center].z> <[diameter]> 150 <[diameter]>"
    #@a doesn't work?
    #- execute as_server "globaldisplay player add storm @a"
    - foreach <server.online_players.parse[name]> as:player_name:
      - execute as_server "globaldisplay player add storm <[player_name]>"

    - flag server fort.temp.storm.diameter:<[diameter]>
    - flag server fort.temp.storm.center:<[storm_center]>

    - define circle_radius <[diameter].div[2].round>
    #- define storm_circle <[storm_center].points_around_y[radius=<[circle_radius]>;points=16].to_polygon.with_y_min[0].with_y_max[300]>
    - define storm_circle <[storm_center].to_ellipsoid[<[circle_radius]>,10000,<[circle_radius]>]>
    - note <[storm_circle]> as:fort_storm_circle


  ## - [ SET NEW STORM ] - ##
  #just setting new data and for the white circle
  set_new:
    #- define new_diameter 100
    ##

    #save current storm data
    - define current_diameter <server.flag[fort.temp.storm.diameter]>
    - define current_center   <server.flag[fort.temp.storm.center]>

    #should be around half
    - define radius <[new_diameter].div[2]>
    #making the radius a little smaller than current, so the (starting) circle can actually be at least half showing on the map
    #.round because getting random.int not .decimal
    - define smaller_radius <[radius].sub[<[radius].div[10]>].round>

    #this way the center won't be on the outskirts of the map or in the void
    - define valid_center False
    #- announce "[Storm Debug] Calculating next storm center..." to_console
    #what if it's an infinite while loop since there's no y value greater than 15?
    - while <[valid_center].not>:
      - define x <util.random.int[-<[smaller_radius]>].to[<[smaller_radius]>]>
      - define z <util.random.int[-<[smaller_radius]>].to[<[smaller_radius]>]>
      - define new_center <[current_center].above[200].add[<[x]>,0,<[z]>]>
      #since edge water levels are below 40
      #lowest y on land i think is like 20
      #fallback is in case the center was somehow in the void
      - if <[new_center].with_pitch[90].ray_trace.y||-1> > 15:
        - define valid_center True
      - wait 1t
    #- announce "[Storm Debug] Done!" to_console

    - flag server fort.temp.storm.new_center:<[current_center].add[<[x]>,0,<[z]>]>
    - flag server fort.temp.storm.new_diameter:<[new_diameter]>

  ## - [ RESIZE/TRANSFORM STORM ] - ##
  resize:
    #- define seconds 5
    ##

    - define start_center   <server.flag[fort.temp.storm.center]>
    - define end_center     <server.flag[fort.temp.storm.new_center]>

    - define start_diameter <server.flag[fort.temp.storm.diameter]>
    - define end_diameter   <server.flag[fort.temp.storm.new_diameter]>

    - define ticks <[seconds].mul[20]>

    - execute as_server "globaldisplay transform storm <[end_center].x> <[end_center].y> <[end_center].z> <[end_diameter]> 150 <[end_diameter]> <[ticks]>"

    #how many points between the two centers
    - define center_increment   <[start_center].distance[<[end_center]>].div[<[ticks]>]>
    - define diameter_increment <[end_diameter].sub[<[start_diameter]>].div[<[ticks]>]>

    - flag server fort.temp.storm.animating
    #for debug purposes
    #- define final_center <[start_center].face[<[end_center]>].forward[<[center_increment].mul[<[ticks]>]>].round>

    - define start_center <[start_center].face[<[end_center]>]>
    - repeat <[ticks]>:
      #rounding so it works with color codes
      - define next_center   <[start_center].forward[<[center_increment].mul[<[value]>]>].round>
      - define next_diameter <[start_diameter].add[<[diameter_increment].mul[<[value]>]>].round>

      - if <[value].mod[20]> == 0:
        - define circle_radius <[next_diameter].div[2]>
        #- define storm_circle <[next_center].points_around_y[radius=<[circle_radius]>;points=16].to_polygon.with_y_min[0].with_y_max[300]>
        - define storm_circle <[next_center].to_ellipsoid[<[circle_radius]>,10000,<[circle_radius]>]>
        - note <[storm_circle]> as:fort_storm_circle
        #resize storm notable every second isntead of tick, to prevent further lag

        - define players            <server.online_players_flagged[!fort.spectating]>
        - define non_storm_players  <ellipsoid[fort_storm_circle].players.filter[has_flag[fort.spectating].not]>
        - define storm_players      <[players].exclude[<[non_storm_players]>]>
        #enter players who are in the storm now
        - foreach <[storm_players]> as:p:
          - run fort_storm_handler.enter_storm player:<[p]>
        #exit players who were previously inside the storm but are now outside
        - foreach <[non_storm_players].filter[has_flag[fort.in_storm]]> as:p:
          - run fort_storm_handler.exit_storm player:<[p]>

      - flag server fort.temp.storm.center:<[next_center]>
      - flag server fort.temp.storm.diameter:<[next_diameter]>

      - wait 1t
    #set the notable to the next value, in case the last tick wasn't at mod[20] == 0
    - define storm_circle <[end_center].to_ellipsoid[<[end_diameter].div[2]>,10000,<[end_diameter].div[2]>]>
    - note <[storm_circle]> as:fort_storm_circle

    - flag server fort.temp.storm.animating:!